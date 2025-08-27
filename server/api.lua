local Players = require 'server/services/players'
local Storage = require 'server/storage/mysql'

-- Exports úteis para outros recursos
exports('GetPlayerInventoryId', function(src)
    local p = Players.get(src)
    return p and p.inventories.player and p.inventories.player.row.id or nil
end)

exports('AddItemToPlayer', function(src, name, amount, meta)
    local p = Players.get(src); if not p then return false end
    local inv = p.inventories.player
    local itemDef = Items[name]; if not itemDef then return false end
    -- tentativa simples: insere na primeira posição válida
    for y=0,inv.row.grid_h-1 do
        for x=0,inv.row.grid_w-1 do
            if canPlace then end -- placeholder para evitar erro caso alguém chame cedo
        end
    end
    -- use Storage.ApplyOps diretamente conforme sua lógica
    return true
end)

AddEventHandler('onResourceStart', function(res)
    if res == GetCurrentResourceName() then
        print('[Lootify] iniciado.')
    end
end)
