--
-- Plain wall
--

PREFABS.Wall_plain =
{
  file   = "wall/wall_16.wad",
  map    = "MAP01",

  nolimit_compat = true,

  prob   = 50,

  where  = "edge",
  deep   = 16,

  bound_z1 = 0,
  bound_z2 = 2,

  x_fit  = "stretch",
  z_fit  = "stretch",
}


PREFABS.Wall_plain_diag =
{
  file   = "wall/wall_16.wad",
  map    = "MAP02",

  nolimit_compat = true,

  prob   = 50,

  where  = "diagonal",

  bound_z1 = 0,
  bound_z2 = 2,

  z_fit  = "stretch",
}
