-- Interações com a UI (NUI)

-- mover item
RegisterNUICallback('move', function(data, cb)
    local ok, err = lib.callback.await('lootify:move', false, data)
    cb({ ok = ok, err = err })
end)

-- split stack
RegisterNUICallback('split', function(data, cb)
    local ok, err = lib.callback.await('lootify:split', false, data)
    cb({ ok = ok, err = err })
end)

-- stack stacks
RegisterNUICallback('stack', function(data, cb)
    local ok, err = lib.callback.await('lootify:stack', false, data)
    cb({ ok = ok, err = err })
end)

-- equip
RegisterNUICallback('equip', function(data, cb)
    local ok, err = lib.callback.await('lootify:equip', false, data)
    cb({ ok = ok, err = err })
end)

-- unequip
RegisterNUICallback('unequip', function(data, cb)
    local ok, err = lib.callback.await('lootify:unequip', false, data)
    cb({ ok = ok, err = err })
end)
