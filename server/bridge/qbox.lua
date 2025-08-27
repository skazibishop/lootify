-- QBox/QBCore Bridge
LOOTIFY_BRIDGE_QBOX = function()
    local QBCore
    if exports and exports['qbx_core'] and exports['qbx_core'].GetCoreObject then
        QBCore = exports['qbx_core']:GetCoreObject()
    elseif exports and exports['qb-core'] and exports['qb-core'].GetCoreObject then
        QBCore = exports['qb-core']:GetCoreObject()
    end

    if not QBCore then
        print('[Lootify][Bridge][QBox] QBox/QBCore não detectado.')
        return nil
    end

    local bridge = {
        name = 'qbox',
        getIdentifier = function(src)
            local p = QBCore.Functions.GetPlayer(src)
            return p and p.PlayerData and p.PlayerData.citizenid or ('unknown:'..tostring(src))
        end,
        addItem = function(src, name, count, metadata)
            local p = QBCore.Functions.GetPlayer(src); if not p then return false end
            return p.Functions.AddItem(name, count or 1, false, metadata or {}) == true
        end,
        removeItem = function(src, name, count, metadata)
            local p = QBCore.Functions.GetPlayer(src); if not p then return false end
            return p.Functions.RemoveItem(name, count or 1) == true
        end,
        addMoney = function(src, account, amount)
            local p = QBCore.Functions.GetPlayer(src); if not p then return false end
            account = account or 'cash'
            return p.Functions.AddMoney(account, amount) == true
        end,
        removeMoney = function(src, account, amount)
            local p = QBCore.Functions.GetPlayer(src); if not p then return false end
            account = account or 'cash'
            return p.Functions.RemoveMoney(account, amount) == true
        end,
        getJob = function(src)
            local p = QBCore.Functions.GetPlayer(src)
            return p and p.PlayerData and p.PlayerData.job and p.PlayerData.job.name or nil
        end,
        getPlayerName = function(src)
            local p = QBCore.Functions.GetPlayer(src)
            return (p and p.PlayerData and p.PlayerData.charinfo and p.PlayerData.charinfo.firstname and (p.PlayerData.charinfo.firstname .. ' ' .. (p.PlayerData.charinfo.lastname or ''))) or GetPlayerName(src)
        end,
    }

    print('[Lootify][Bridge] QBox/QBCore pronto.')
    return bridge
end
