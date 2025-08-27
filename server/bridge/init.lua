-- Seleciona automaticamente o bridge conforme ConVar e recursos ativos
CreateThread(function()
    local framework = (Config and Config.Framework) or 'auto'
    local function hasResource(name)
        return GetResourceState(name) == 'started' or GetResourceState(name) == 'starting'
    end

    local bridge
    if framework == 'esx' or (framework == 'auto' and hasResource('es_extended')) then
        bridge = LOOTIFY_BRIDGE_ESX()
    elseif framework == 'qbox' or (framework == 'auto' and (hasResource('qbx_core') or hasResource('qb-core'))) then
        bridge = LOOTIFY_BRIDGE_QBOX()
    else
        bridge = LOOTIFY_BRIDGE_STANDALONE()
    end

    LOOTIFY.Bridge = bridge
    print(('[Lootify] Bridge selecionado: %s'):format(bridge and bridge.name or 'none'))
end)
