-- Backpack item: 32 slots total (1x 4x4) + (4x 2x2)
-- Category "backpack" so it equips in the 'backpack' slot and spawns container:backpack inventory with these grids.

Items = Items or {}

Items["bag_ranger32"] = {
  label = "Mochila Ranger 32",
  description = "Mochila média com 1 compartimento 4x4 e 4 bolsos 2x2 (32 slots).",
  size = { w = 3, h = 4 },
  stack = 1,
  weight = 4.0,
  category = "backpack",
  grids = {
    { key = "bp_main", w = 4, h = 4 }, -- compartimento principal 4x4
    { key = "bp_p1",  w = 2, h = 2 },  -- bolsos 2x2
    { key = "bp_p2",  w = 2, h = 2 },
    { key = "bp_p3",  w = 2, h = 2 },
    { key = "bp_p4",  w = 2, h = 2 },
  },
}
