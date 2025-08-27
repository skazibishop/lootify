-- ESX Bridge
LOOTIFY_BRIDGE_ESX = function()
    local ok, ESX = pcall(function()
        if exports and exports['es_extended'] and exports['es_extended'].getSharedObject then
            return exports['es_extended']:getSharedObject()
        end
        -- Legacy event fallback
        local obj
        TriggerEvent('esx:getSharedObject', function(x) obj = x end)
        return obj
    end)

    if not ok or not ESX then
        print('[Lootify][Bridge][ESX] ESX não detectado.')
        return nil
    end

    local bridge = {
        name = 'esx',
        getIdentifier = function(src)
            local xPlayer = ESX.GetPlayerFromId(src)
            return xPlayer and (xPlayer.identifier or xPlayer.getIdentifier()) or ('unknown:'..tostring(src))
        end,
        addItem = function(src, name, count, metadata)
            local xPlayer = ESX.GetPlayerFromId(src)
            if not xPlayer then return false end
            return xPlayer.addInventoryItem(name, count or 1) ~= false
        end,
        removeItem = function(src, name, count, metadata)
            local xPlayer = ESX.GetPlayerFromId(src)
            if not xPlayer then return false end
            xPlayer.removeInventoryItem(name, count or 1)
            return true
        end,
        addMoney = function(src, account, amount)
            local xPlayer = ESX.GetPlayerFromId(src); if not xPlayer then return false end
            if account == 'money' or account == 'cash' then
                xPlayer.addMoney(amount); return true
            else
                xPlayer.addAccountMoney(account, amount); return true
            end
        end,
        removeMoney = function(src, account, amount)
            local xPlayer = ESX.GetPlayerFromId(src); if not xPlayer then return false end
            if account == 'money' or account == 'cash' then
                xPlayer.removeMoney(amount); return true
            else
                xPlayer.removeAccountMoney(account, amount); return true
            end
        end,
        getJob = function(src)
            local xPlayer = ESX.GetPlayerFromId(src)
            return xPlayer and xPlayer.job and xPlayer.job.name or nil
        end,
        getPlayerName = function(src)
            local xPlayer = ESX.GetPlayerFromId(src)
            return xPlayer and xPlayer.getName and xPlayer.getName() or GetPlayerName(src)
        end,
    }

    print('[Lootify][Bridge] ESX pronto.')
    return bridge
end
