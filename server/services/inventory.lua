-- lootify/server/services/inventory.lua
local Storage = require 'server/storage/mysql'
local Locks = require 'server/services/locks'
local Players = require 'server/services/players'
local Packing = require 'server/services/packing'

local Inventory = {}

local function getInvById(p, inv_id)
    if p.inventories.player and p.inventories.player.row.id == inv_id then return p.inventories.player end
    if p.inventories.stash  and p.inventories.stash.row.id  == inv_id then return p.inventories.stash end
    if p.inventories.equip  and p.inventories.equip.row.id  == inv_id then return p.inventories.equip end
    for k,v in pairs(p.inventories) do
        if type(k)=='string' and k:sub(1,10)=='container:' and v.row.id == inv_id then return v end
    end
    return nil
end

local function canStack(a, b) return a.name == b.name and (a.metadata or '{}') == (b.metadata or '{}') end
local function findItem(inv, id) for _, it in ipairs(inv.items) do if it.id == id then return it end end end
local function reloadInv(inv) inv.items = Storage.LoadItems(inv.row.id) end

-- MOVE (UPDATE quando é o mesmo inventário)
lib.callback.register('lootify:move', function(src, data)
    local p = Players.get(src); if not p then return { ok=false, err='player_not_loaded' } end
    local fromInv = getInvById(p, data.from_inv)
    local toInv   = getInvById(p, data.to_inv)
    if not fromInv or not toInv then return { ok=false, err='invalid_inv' } end

    local item = findItem(fromInv, data.item_id)
    if not item then return { ok=false, err='item_not_found' } end

    local rot = data.rot==1 and 1 or 0
    local newSize = { w = (rot==1 and item.size_h or item.size_w), h = (rot==1 and item.size_w or item.size_h) }
    local targetKey = data.grid_key or 'main'
    local gW, gH = toInv.row.grid_w, toInv.row.grid_h
    if toInv.meta and toInv.meta.grids then
        for _, g in ipairs(toInv.meta.grids) do if g.key == targetKey then gW = g.w; gH = g.h break end end
    end

    local itemsForOcc = (fromInv.row.id == toInv.row.id) and (function()
        local t = {}
        for _, it in ipairs(toInv.items) do if it.id ~= item.id then t[#t+1] = it end end
        return t
    end)() or toInv.items

    local occ = Packing.buildGrid(itemsForOcc, gW, gH, targetKey)
    local function fits(W,H,w,h,x0,y0)
        if x0 < 1 or y0 < 1 or x0 + w - 1 > W or y0 + h - 1 > H then return false end
        for yy=y0, y0+h-1 do for xx=x0, x0+w-1 do if occ[yy][xx] then return false end end end
        return true
    end

    local x,y = data.to_pos.x+1, data.to_pos.y+1
    if not fits(gW, gH, newSize.w, newSize.h, x, y) then return { ok=false, err='no_space' } end

    if fromInv.row.id == toInv.row.id then
        local ok = Storage.ApplyOps(fromInv.row.id, { { op='update', item = {
            id=item.id, version=item.version or 1, amount=item.amount,
            pos={x=data.to_pos.x, y=data.to_pos.y}, rot=rot, grid_key=targetKey
        }}})
        if not ok then return { ok=false, err='db_error' } end
        reloadInv(fromInv)
    else
        local ok1 = Storage.ApplyOps(toInv.row.id, { { op='insert', item = {
            name=item.name, amount=item.amount, size={w=newSize.w,h=newSize.h}, rot=rot, pos={x=data.to_pos.x, y=data.to_pos.y}, grid_key=targetKey,
            durability=item.durability, metadata=json.decode(item.metadata or '{}')
        }}})
        if not ok1 then return { ok=false, err='db_error' } end
        Storage.ApplyOps(fromInv.row.id, { { op='delete', id=item.id } })
        reloadInv(fromInv); reloadInv(toInv)
    end

    TriggerClientEvent(LOOTIFY.Events.Sync, src, { changed = true })
    return { ok=true }
end)

-- SPLIT (respeita múltiplas grids)
lib.callback.register('lootify:split', function(src, data)
    local p = Players.get(src); if not p then return { ok=false, err='player_not_loaded' } end
    local inv = getInvById(p, data.inv_id); if not inv then return { ok=false, err='invalid_inv' } end
    local item = findItem(inv, data.item_id); if not item then return { ok=false, err='item_not_found' } end
    local splitCount = tonumber(data.count or 0); if splitCount <= 0 or splitCount >= item.amount then return { ok=false, err='bad_count' } end

    local defSizeW, defSizeH = item.size_w, item.size_h
    local invDef = (inv.meta and inv.meta.grids) and { grids = inv.meta.grids } or { w = inv.row.grid_w, h = inv.row.grid_h }
    local fit = Packing.findSlotFor(inv.items, invDef, defSizeW, defSizeH, true, item.grid_key or 'main')
    if not fit then return { ok=false, err='no_space' } end

    local ok = Storage.ApplyOps(inv.row.id, {
        { op='update', item = { id = item.id, version = item.version or 1, amount = item.amount - splitCount, rot = item.rot or 0, grid_key = item.grid_key or 'main' } },
        { op='insert', item = { name = item.name, amount = splitCount, size = { w = defSizeW, h = defSizeH }, rot = fit.rot, pos = { x = fit.x, y = fit.y }, grid_key = fit.grid_key, metadata = json.decode(item.metadata or '{}'), durability = item.durability } }
    })
    if not ok then return { ok=false, err='db_error' } end

    reloadInv(inv)
    TriggerClientEvent(LOOTIFY.Events.Sync, src, { changed = true })
    return { ok=true }
end)

-- STACK (no mesmo inventário)
lib.callback.register('lootify:stack', function(src, data)
    local p = Players.get(src); if not p then return { ok=false, err='player_not_loaded' } end
    local inv = getInvById(p, data.inv_id); if not inv then return { ok=false, err='invalid_inv' } end
    local a = findItem(inv, data.from_item_id); local b = findItem(inv, data.to_item_id)
    if not a or not b then return { ok=false, err='item_not_found' } end
    if not canStack(a, b) then return { ok=false, err='different' } end

    local maxStack = (Items[a.name] and Items[a.name].stack) or 1
    local free = maxStack - (b.amount or 0); if free <= 0 then return { ok=false, err='full' } end
    local move = math.min(free, a.amount)

    local ops = {}
    table.insert(ops, { op='update', item = { id = b.id, version = b.version or 1, amount = b.amount + move, rot=b.rot or 0, grid_key=b.grid_key or 'main' } })
    if a.amount - move <= 0 then
        table.insert(ops, { op='delete', id = a.id })
    else
        table.insert(ops, { op='update', item = { id = a.id, version = a.version or 1, amount = a.amount - move, rot=a.rot or 0, grid_key=a.grid_key or 'main' } })
    end
    local ok = Storage.ApplyOps(inv.row.id, ops)
    if not ok then return { ok=false, err='db_error' } end

    reloadInv(inv)
    TriggerClientEvent(LOOTIFY.Events.Sync, src, { changed = true })
    return { ok=true }
end)

-- EQUIP (salva layout no meta)
lib.callback.register('lootify:equip', function(src, data)
    local p = Players.get(src); if not p then return { ok=false, err='player_not_loaded' } end
    local fromInv = getInvById(p, data.from_inv); if not fromInv then return { ok=false, err='invalid_inv' } end
    local equip = p.inventories.equip
    local slot = data.slot_key
    if not slot then return { ok=false, err='no_slot' } end

    local item = findItem(fromInv, data.item_id); if not item then return { ok=false, err='item_not_found' } end
    local def = Items[item.name]; if not def then return { ok=false, err='unknown_item' } end
    if def.category == 'rig' and slot ~= 'vest' then return { ok=false, err='slot_mismatch' } end
    if def.category == 'backpack' and slot ~= 'backpack' then return { ok=false, err='slot_mismatch' } end
    for _, it in ipairs(equip.items) do if it.grid_key == slot then return { ok=false, err='slot_occupied' } end end

    local ok1 = Storage.ApplyOps(equip.row.id, { { op='insert', item = {
        name=item.name, amount=item.amount, size={w=item.size_w,h=item.size_h}, rot=0, pos={x=0,y=0}, grid_key=slot,
        durability=item.durability, metadata=json.decode(item.metadata or '{}')
    }}})
    if not ok1 then return { ok=false, err='db_error' } end
    Storage.ApplyOps(fromInv.row.id, { { op='delete', id=item.id } })

    if def.grids and #def.grids > 0 then
        local invType = 'container:'..slot
        local cont = Storage.FetchOrCreateInventory(p.id, invType, def.grids[1].w, def.grids[1].h, def.grids)
        Storage.UpdateInventoryMeta(cont.id, { grids = def.grids, layout = def.layout })
        p.inventories[invType] = { row = cont, items = Storage.LoadItems(cont.id), meta = { grids = def.grids, layout = def.layout } }
    end

    reloadInv(equip); reloadInv(fromInv)
    TriggerClientEvent(LOOTIFY.Events.Sync, src, { changed = true })
    return { ok=true }
end)

-- UNEQUIP (bloqueia se container tiver itens)
lib.callback.register('lootify:unequip', function(src, data)
    local p = Players.get(src); if not p then return { ok=false, err='player_not_loaded' } end
    local equip = p.inventories.equip
    local slot = data.slot_key; if not slot then return { ok=false, err='no_slot' } end
    local item
    for _, it in ipairs(equip.items) do if it.grid_key == slot then item = it break end end
    if not item then return { ok=false, err='empty' } end

    local invType = 'container:'..slot
    if p.inventories[invType] then
        local cont = p.inventories[invType]
        if #cont.items > 0 then return { ok=false, err='container_not_empty' } end
    end

    local fit = Packing.findSlotFor(p.inventories.player.items, { w=p.inventories.player.row.grid_w, h=p.inventories.player.row.grid_h }, item.size_w, item.size_h, true, 'main')
    if not fit then return { ok=false, err='no_space' } end

    local ok1 = Storage.ApplyOps(p.inventories.player.row.id, { { op='insert', item = {
        name=item.name, amount=item.amount, size={w=item.size_w,h=item.size_h}, rot=fit.rot, pos={x=fit.x,y=fit.y}, grid_key=fit.grid_key,
        durability=item.durability, metadata=json.decode(item.metadata or '{}')
    }}})
    if not ok1 then return { ok=false, err='db_error' } end
    Storage.ApplyOps(equip.row.id, { { op='delete', id=item.id } })

    p.inventories[invType] = nil

    reloadInv(equip); reloadInv(p.inventories.player)
    TriggerClientEvent(LOOTIFY.Events.Sync, src, { changed = true })
    return { ok=true }
end)


lib.callback.register('lootify:open', function(src)
    local p = Players.loadAll(src)
    return Players.snapshot(src)
end)

return Inventory
