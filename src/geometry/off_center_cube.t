-- geometry/off_center_cube.t
--
-- makes a cube that isn't centered
-- (TODO: refactor into plain cube?)

local m = {}
local math = require("math")
local gfx = require("gfx")

function m.off_center_cube_data(opts)
  -- extents and half extents
  opts = opts or {}
  local sx = opts.sx or opts[1] or 1
  local sy = opts.sy or opts[2] or sx
  local sz = opts.sz or opts[3] or sy
  local u0, u1 = 0.0, (opts.u_mult or 1.0)
  local v0, v1 = 0.0, (opts.v_mult or 1.0)
  local Vector = math.Vector

  local position = {
    Vector(0.0,  sy,  sz),
    Vector( sx,  sy,  sz),
    Vector(0.0, 0.0,  sz),
    Vector( sx, 0.0,  sz),

    Vector(0.0,  sy, 0.0),
    Vector( sx,  sy, 0.0),
    Vector(0.0, 0.0, 0.0),
    Vector( sx, 0.0, 0.0),

    Vector( sx,  sy,  sz),
    Vector(0.0,  sy,  sz),
    Vector( sx,  sy, 0.0),
    Vector(0.0,  sy, 0.0),

    Vector( sx, 0.0,  sz),
    Vector(0.0, 0.0,  sz),
    Vector( sx, 0.0, 0.0),
    Vector(0.0, 0.0, 0.0),

    Vector( sx,  sy,  sz),
    Vector( sx, 0.0,  sz),
    Vector( sx,  sy, 0.0),
    Vector( sx, 0.0, 0.0),

    Vector(0.0,  sy,  sz),
    Vector(0.0, 0.0,  sz),
    Vector(0.0,  sy, 0.0),
    Vector(0.0, 0.0, 0.0)
  }

  local texcoord0 = {
    Vector(u0, v0),
    Vector(u1, v0),
    Vector(u0, v1),
    Vector(u1, v1),

    Vector(u0, v0),
    Vector(u1, v0),
    Vector(u0, v1),
    Vector(u1, v1),

    Vector(u0, v0),
    Vector(u1, v0),
    Vector(u0, v1),
    Vector(u1, v1),

    Vector(u1, v1),
    Vector(u0, v1),
    Vector(u1, v0),
    Vector(u0, v0),

    Vector(u1, v1),
    Vector(u0, v1),
    Vector(u1, v0),
    Vector(u0, v0),

    Vector(u1, v1),
    Vector(u0, v1),
    Vector(u1, v0),
    Vector(u0, v0)
  }

  local indices = {
    { 0,  2,  1},
    { 1,  2,  3},
    { 4,  5,  6},
    { 5,  7,  6},
    { 8, 10,  9},
    { 9, 10, 11},
    {12, 13, 14},
    {13, 15, 14},
    {16, 17, 18},
    {17, 19, 18},
    {20, 22, 21},
    {21, 22, 23}
  }

  return {indices = indices,
          attributes = {position = position, texcoord0 = texcoord0}}
end

m._geometries = {off_center_cube = m.off_center_cube_data}

return m
