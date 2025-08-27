-- Standalone Bridge (fallback)
LOOTIFY_BRIDGE_STANDALONE = function()
    local bridge = {
        name = 'standalone',
        getIdentifier = function(src)
            -- license: identifiers may vary; pick the first license if available
            for _, id in ipairs(GetPlayerIdentifiers(src)) do
                if id:find('license:') then return id end
            end
            return 'player:'..tostring(src)
        end,
        addItem = function(src, name, count, metadata)
            -- handled by Lootify storage; return true to indicate success
            return true
        end,
        removeItem = function(src, name, count, metadata)
            return true
        end,
        addMoney = function(src, account, amount) return true end,
        removeMoney = function(src, account, amount) return true end,
        getJob = function(src) return nil end,
        getPlayerName = function(src) return GetPlayerName(src) end,
    }
    print('[Lootify][Bridge] Standalone pronto.')
    return bridge
end
