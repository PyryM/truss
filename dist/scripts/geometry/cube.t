-- geometry/cube.t
--
-- functions for making cubes

local m = {}
local math = require("math")
local gfx = require("gfx")

function m.cube_data(opts)
  -- extents and half extents
  opts = opts or {}
  local sx = opts.sx or opts[1] or 1
  local sy = opts.sy or opts[2] or sx
  local sz = opts.sz or opts[3] or sy
  local hx, hy, hz = sx/2, sy/2, sz/2
  local u0, u1 = 0.0, 1.0
  local v0, v1 = 0.0, 1.0
  local Vector = math.Vector

  local position = {
    Vector(-hx,  hy,  hz),
    Vector( hx,  hy,  hz),
    Vector(-hx, -hy,  hz),
    Vector( hx, -hy,  hz),

    Vector(-hx,  hy, -hz),
    Vector( hx,  hy, -hz),
    Vector(-hx, -hy, -hz),
    Vector( hx, -hy, -hz),

    Vector( hx,  hy,  hz),
    Vector(-hx,  hy,  hz),
    Vector( hx,  hy, -hz),
    Vector(-hx,  hy, -hz),

    Vector( hx, -hy,  hz),
    Vector(-hx, -hy,  hz),
    Vector( hx, -hy, -hz),
    Vector(-hx, -hy, -hz),

    Vector( hx,  hy,  hz),
    Vector( hx, -hy,  hz),
    Vector( hx,  hy, -hz),
    Vector( hx, -hy, -hz),

    Vector(-hx,  hy,  hz),
    Vector(-hx, -hy,  hz),
    Vector(-hx,  hy, -hz),
    Vector(-hx, -hy, -hz)
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

m._geometries = {cube = m.cube_data}

return m
