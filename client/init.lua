local evtOpen  = (LOOTIFY and LOOTIFY.Events and LOOTIFY.Events.Open)  or 'lootify:open'
local evtClose = (LOOTIFY and LOOTIFY.Events and LOOTIFY.Events.Close) or 'lootify:close'
local evtSync  = (LOOTIFY and LOOTIFY.Events and LOOTIFY.Events.Sync)  or 'lootify:sync'

-- abre a UI e manda snapshot
RegisterCommand('lootify', function()
    local data = lib.callback.await('lootify:open', false)
    SetNuiFocus(true, true)
    SendNUIMessage({ t = 'open', data = data })
end)

-- fecha a UI
RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    cb({ ok = true })
end)

-- quando o servidor disser "sync", busca snapshot atual e renderiza
RegisterNetEvent(evtSync, function(payload)
    local data = lib.callback.await('lootify:open', false)
    SendNUIMessage({ t = 'sync', data = data })
end)
