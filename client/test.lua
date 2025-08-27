RegisterCommand('lf_pickup', function(_, args)
    local name = args[1] or 'water'
    local amount = tonumber(args[2] or '1')
    local ok, err = lib.callback.await('lootify:pickup', false, { name=name, amount=amount })
    print('pickup', ok, err or 'ok')
end)

RegisterCommand('lf_equip_vest', function(_, args)
    -- expects you have an item selected in 'player' inv; this is just a stub demo
    -- in real UI, you'll pass item_id. Here we request snapshot and pick first matching category 'rig'
    local snap = lib.callback.await('lootify:open', false)
    local itemId
    for _, it in ipairs(snap.player.items or {}) do
        local def = Items[it.name]; if def and def.category == 'rig' then itemId = it.id break end
    end
    if not itemId then print('no rig item in player inv'); return end
    local ok, err = lib.callback.await('lootify:equip', false, { from_inv=snap.player.id, item_id=itemId, slot_key='vest' })
    print('equip vest', ok, err or 'ok')
end)

RegisterCommand('lf_unequip_vest', function()
    local ok, err = lib.callback.await('lootify:unequip', false, { slot_key='vest' })
    print('unequip vest', ok, err or 'ok')
end)
