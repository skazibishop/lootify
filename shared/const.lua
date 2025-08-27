LOOTIFY = LOOTIFY or {}

LOOTIFY.Events = {
    Open = 'lootify:open',
    Close = 'lootify:close',
    Sync = 'lootify:sync',
    RequestMove = 'lootify:requestMove',
    RequestSplit = 'lootify:requestSplit',
    RequestStack = 'lootify:requestStack',
    RequestEquip = 'lootify:requestEquip',
    RequestUnequip = 'lootify:requestUnequip',
    RequestDrop = 'lootify:requestDrop',
    RequestPickup = 'lootify:requestPickup',
    RequestTrade = 'lootify:requestTrade'
}

LOOTIFY.Inventories = {
    PLAYER = 'player',      -- inventário principal do jogador
    STASH  = 'stash',       -- baú pessoal
    CONTAINER = 'container' -- world containers
}
