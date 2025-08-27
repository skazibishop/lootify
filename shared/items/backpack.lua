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
    { key = "bp_main", w = 4, h = 4 },
    { key = "bp_p1",  w = 2, h = 2 },
    { key = "bp_p2",  w = 2, h = 2 },
    { key = "bp_p3",  w = 2, h = 2 },
    { key = "bp_p4",  w = 2, h = 2 },
  },
  layout = {
    cols = 2, rows = 3,
    cells = {
      { key = "bp_main", col = 1, row = 1, colSpan = 2 },
      { key = "bp_p1",   col = 1, row = 2 },
      { key = "bp_p2",   col = 2, row = 2 },
      { key = "bp_p3",   col = 1, row = 3 },
      { key = "bp_p4",   col = 2, row = 3 },
    }
  }
}
