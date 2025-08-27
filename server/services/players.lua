local Storage = require 'server/storage/mysql'

local Players = {}
local cache = {}

local function ensurePlayer(src)
    if cache[src] then return cache[src] end
    local identifier = LOOTIFY.Bridge.getIdentifier(src)
    cache[src] = {
        src = src,
        id = identifier,
        name = LOOTIFY.Bridge.getPlayerName(src),
        inventories = {},
        dirty = false
    }
    return cache[src]
end

local function decodeMeta(row)
    local ok, meta = pcall(function() return row.meta and json.decode(row.meta) or {} end)
    if not ok or type(meta) ~= 'table' then meta = {} end
    return meta
end

local function ensureEquipment(p)
    local equip = Storage.FetchOrCreateInventory(p.id, 'equipment', 1, 1)
    local meta = decodeMeta(equip)
    meta.grids = meta.grids or {
        { key='hands', w=1, h=1 },
        { key='vest', w=1, h=1 },
        { key='backpack', w=1, h=1 },
        { key='container', w=1, h=1 },
        { key='mask', w=1, h=1 },
        { key='torso', w=1, h=1 },
        { key='legs', w=1, h=1 },
        { key='shoes', w=1, h=1 },
        { key='accessories', w=1, h=1 },
        { key='undershirts', w=1, h=1 },
        { key='body', w=1, h=1 },
        { key='decals', w=1, h=1 },
        { key='tops', w=1, h=1 },
        { key='hats', w=1, h=1 },
        { key='glasses', w=1, h=1 },
        { key='ears', w=1, h=1 },
        { key='watches', w=1, h=1 },
        { key='bracelets', w=1, h=1 },
    }
    Storage.UpdateInventoryMeta(equip.id, meta)
    return { row = equip, items = Storage.LoadItems(equip.id), meta = meta }
end

function Players.loadAll(src)
    local p = ensurePlayer(src)
    local base = Storage.FetchOrCreateInventory(p.id, LOOTIFY.Inventories.PLAYER, Config.DefaultGrid.w, Config.DefaultGrid.h)
    local stash = Storage.FetchOrCreateInventory(p.id, LOOTIFY.Inventories.STASH, Config.DefaultGrid.w, Config.DefaultGrid.h)
    local equip = ensureEquipment(p)

    p.inventories.player = { row = base, items = Storage.LoadItems(base.id), meta = { grids = { {key='main', w=base.grid_w, h=base.grid_h} } } }
    p.inventories.stash  = { row = stash, items = Storage.LoadItems(stash.id), meta = { grids = { {key='main', w=stash.grid_w, h=stash.grid_h} } } }
    p.inventories.equip  = equip

    return p
end

function Players.unload(src)
    cache[src] = nil
end

function Players.get(src)
    return cache[src] or ensurePlayer(src)
end

function Players.snapshot(src)
    local p = cache[src] or ensurePlayer(src)
    local inv = p.inventories

    local containers = {}
    for k, v in pairs(inv) do
        if type(k) == 'string' and k:sub(1,10) == 'container:' then
            containers[#containers+1] = {
                id = v.row.id,
                slot = k:sub(11),
                grids = (v.meta and v.meta.grids) or {},
                items = v.items
            }

            
        end
    end

    return {
        player = { id = inv.player.row.id, size = { w = inv.player.row.grid_w, h = inv.player.row.grid_h }, items = inv.player.items },
        stash  = { id = inv.stash.row.id,  size = { w = inv.stash.row.grid_w,  h = inv.stash.row.grid_h  }, items = inv.stash.items  },
        equip  = { id = inv.equip.row.id,  grids = inv.equip.meta.grids, items = inv.equip.items },
        containers = containers,
        name = p.name
    }
end

AddEventHandler('playerDropped', function()
    local src = source
    Players.unload(src)
end)

return Players
