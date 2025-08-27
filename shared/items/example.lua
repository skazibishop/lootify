Items = Items or {}

-- Exemplo de item
Items["water"] = {
    label = "Garrafa de Água",
    size = { w = 1, h = 2 },
    stack = 5,
    weight = 0.5,
    category = "consumable"
}

Items["rig_basic"] = {
    label = "Rig Simples",
    size = { w = 3, h = 3 },
    stack = 1,
    weight = 3.0,
    category = "rig",
    -- rigs e mochilas podem ter grids próprios
    grids = {
        { name = "RigGridA", w = 3, h = 3 }
    }
}
