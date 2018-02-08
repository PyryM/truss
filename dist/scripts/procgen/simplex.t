-- procgen/simplex.t

--
-- Based on code in "Simplex noise demystified", by Stefan Gustavson
-- www.itn.liu.se/~stegu/simplexnoise/simplexnoise.pdf
--
-- Thanks to Mike Pall for some cleanup and improvements (and for LuaJIT!)
--
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
--
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--
-- [ MIT license: http://www.opensource.org/licenses/mit-license.php ]
--

-- Ported to Terra by Pyry Matikainen 2017

-- Modules --
local bit = require("bit")
local ffi = require("ffi")
local math = require("math")

-- switch this to float if you want e.g., float based functions (faster?)
local scalar_type = double

local cmath = require("math/cmath.t")
local cmax, cmin, cfloor
if scalar_type == double then
  cmax, cmin, cfloor = cmath.fmax, cmath.fmin, cmath.floor
else -- float, presumably
  cmax, cmin, cfloor = cmath.fmaxf, cmath.fminf, cmath.floorf
end

-- Module table --
local m = {}

local function create_random_perms(random_func)
  if random_func == true then random_func = math.random end
  local vals = {}
  for i = 1, 256 do
    vals[i] = i - 1
  end

  for i = 1,255 do
    local r = random_func(i, 256)
    vals[i], vals[r] = vals[r], vals[i]
  end
  return vals
end

local function create_perms(random_func)
  -- Permutation of 0-255, replicated to allow easy indexing
  -- and also the same permuations mod 12

  local perms = terralib.new(uint8[512])
  local perms12 = terralib.new(uint8[512])

  local vals = nil
  if random_func then
    vals = create_random_perms(random_func)
  else
    vals = {
    151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225,
    140, 36, 103, 30, 69, 142, 8, 99, 37, 240, 21, 10, 23, 190, 6, 148,
    247, 120, 234, 75, 0, 26, 197, 62, 94, 252, 219, 203, 117, 35, 11, 32,
    57, 177, 33, 88, 237, 149, 56, 87, 174, 20, 125, 136, 171, 168, 68,	175,
    74, 165, 71, 134, 139, 48, 27, 166, 77, 146, 158, 231, 83, 111,	229, 122,
    60, 211, 133, 230, 220, 105, 92, 41, 55, 46, 245, 40, 244, 102, 143, 54,
    65, 25, 63, 161, 1, 216, 80, 73, 209, 76, 132, 187, 208, 89, 18, 169,
    200, 196, 135, 130, 116, 188, 159, 86, 164, 100, 109, 198, 173, 186, 3, 64,
    52, 217, 226, 250, 124, 123, 5, 202, 38, 147, 118, 126, 255, 82, 85, 212,
    207, 206, 59, 227, 47, 16, 58, 17, 182, 189, 28, 42, 223, 183, 170, 213,
    119, 248, 152, 2, 44, 154, 163, 70, 221, 153, 101, 155, 167, 43, 172, 9,
    129, 22, 39, 253, 19, 98, 108, 110, 79, 113, 224, 232, 178, 185, 112, 104,
    218, 246, 97, 228, 251, 34, 242, 193, 238, 210, 144, 12, 191, 179, 162, 241,
    81,	51, 145, 235, 249, 14, 239,	107, 49, 192, 214, 31, 181, 199, 106, 157,
    184, 84, 204, 176, 115, 121, 50, 45, 127, 4, 150, 254, 138, 236, 205, 93,
    222, 114, 67, 29, 24, 72, 243, 141, 128, 195, 78, 66, 215, 61, 156, 180 }
  end

  for i,v in ipairs(vals) do
    perms[i-1]     = v
    perms[i+255]   = v
    perms12[i-1]   = v % 12
    perms12[i+255] = v % 12
  end
  return perms, perms12
end

local function copy_nested_lists(target, src, outerdim, innerdim)
  local idx = 0
  for outer_idx = 1,outerdim do
    for inner_idx = 1,innerdim do
      target[idx] = src[outer_idx][inner_idx] or 0
      idx = idx + 1
    end
  end
end

local function create_gradients3d()
  -- Gradients for 2D, 3D case --
  local grads3 = terralib.new(scalar_type[12*3])
  local vals = {{ 1, 1, 0 }, { -1, 1, 0 }, { 1, -1, 0 }, { -1, -1, 0 },
                { 1, 0, 1 }, { -1, 0, 1 }, { 1, 0, -1 }, { -1, 0, -1 },
                { 0, 1, 1 }, { 0, -1, 1 }, { 0, 1, -1 }, { 0, -1, -1 }}
  copy_nested_lists(grads3, vals, 12, 3)
  return grads3
end

local function create_gradients4d()
  -- Gradients for 4D case --
  local grads4 = terralib.new(scalar_type[32*4])
  local vals = {
  { 0, 1, 1, 1 }, { 0, 1, 1, -1 }, { 0, 1, -1, 1 }, { 0, 1, -1, -1 },
  { 0, -1, 1, 1 }, { 0, -1, 1, -1 }, { 0, -1, -1, 1 }, { 0, -1, -1, -1 },
  { 1, 0, 1, 1 }, { 1, 0, 1, -1 }, { 1, 0, -1, 1 }, { 1, 0, -1, -1 },
  { -1, 0, 1, 1 }, { -1, 0, 1, -1 }, { -1, 0, -1, 1 }, { -1, 0, -1, -1 },
  { 1, 1, 0, 1 }, { 1, 1, 0, -1 }, { 1, -1, 0, 1 }, { 1, -1, 0, -1 },
  { -1, 1, 0, 1 }, { -1, 1, 0, -1 }, { -1, -1, 0, 1 }, { -1, -1, 0, -1 },
  { 1, 1, 1, 0 }, { 1, 1, -1, 0 }, { 1, -1, 1, 0 }, { 1, -1, -1, 0 },
  { -1, 1, 1, 0 }, { -1, 1, -1, 0 }, { -1, -1, 1, 0 }, { -1, -1, -1, 0 } }
  copy_nested_lists(grads4, vals, 32, 4)
  return grads4
end

local function create_simplex4d()
  -- A lookup table to traverse the simplex around a given point in 4D.
  -- Details can be found where this table is used, in the 4D noise method.
  local simplex4d = terralib.new(uint8[64*4])
  local vals = {
  { 0, 1, 2, 3 }, { 0, 1, 3, 2 }, {}, { 0, 2, 3, 1 }, {}, {}, {}, { 1, 2, 3 },
  { 0, 2, 1, 3 }, {}, { 0, 3, 1, 2 }, { 0, 3, 2, 1 }, {}, {}, {}, { 1, 3, 2 },
  {}, {}, {}, {}, {}, {}, {}, {},
  { 1, 2, 0, 3 }, {}, { 1, 3, 0, 2 }, {}, {}, {}, { 2, 3, 0, 1 }, { 2, 3, 1 },
  { 1, 0, 2, 3 }, { 1, 0, 3, 2 }, {}, {}, {}, { 2, 0, 3, 1 }, {}, { 2, 1, 3 },
  {}, {}, {}, {}, {}, {}, {}, {},
  { 2, 0, 1, 3 }, {}, {}, {}, { 3, 0, 1, 2 }, { 3, 0, 2, 1 }, {}, { 3, 1, 2 },
  { 2, 1, 0, 3 }, {}, {}, {}, { 3, 1, 0, 2 }, {}, { 3, 2, 0, 1 }, { 3, 2, 1 } }
  copy_nested_lists(simplex4d, vals, 64, 4)

  -- Convert the above indices to masks that can be shifted / anded into offsets
  for i = 0, 63 do
    simplex4d[i*4 + 0] = bit.lshift(1, simplex4d[i*4 + 0]) - 1
    simplex4d[i*4 + 1] = bit.lshift(1, simplex4d[i*4 + 1]) - 1
    simplex4d[i*4 + 2] = bit.lshift(1, simplex4d[i*4 + 2]) - 1
    simplex4d[i*4 + 3] = bit.lshift(1, simplex4d[i*4 + 3]) - 1
  end

  return simplex4d
end

local struct NoiseTable {
  perms:     &uint8;
  perms12:   &uint8;
  grads3:    &scalar_type;
  grads4:    &scalar_type;
  simplex4d: &uint8;
}

local function create_tables()
  local noisetable_c = terralib.new(NoiseTable)
  m._p, m._p12 = create_perms()
  noisetable_c.perms, noisetable_c.perms12 = m._p, m._p12
  m._grads3 = create_gradients3d()
  noisetable_c.grads3 = m._grads3
  m._grads4 = create_gradients4d()
  noisetable_c.grads4 = m._grads4
  m._simplex4d = create_simplex4d()
  noisetable_c.simplex4d = m._simplex4d

  return noisetable_c
end
m.noisetable_c = create_tables()

function m.randomize(random_func)
  m._p, m._p12 = create_perms(random_func)
  m.noisetable_c.perms   = m._p
  m.noisetable_c.perms12 = m._p12
end

-- 2D weight contribution
local terra getn_2d(bx: int32, by: int32, x: scalar_type, y: scalar_type,
                    perms: &uint8, perms12: &uint8, grads: &scalar_type) : scalar_type
  var t = 0.5 - x * x - y * y
  var index = perms12[bx + perms[by]] * 3

  return cmax(0.0, (t*t)*(t*t)) * (grads[index+0]*x + grads[index+1]*y)
end

---
-- @param x
-- @param y
-- @return Noise value in the range [-1, +1]
terra m.simplex_2d_raw(x: scalar_type, y: scalar_type, nt: &NoiseTable): scalar_type
  --[[
  2D skew factors:
  F = (math.sqrt(3) - 1) / 2
  G = (3 - math.sqrt(3)) / 6
  G2 = 2 * G - 1
  ]]

  -- Skew the input space to determine which simplex cell we are in.
  var s = (x + y) * 0.366025403 -- F
  var ix: int32, iy: int32 = cfloor(x + s), cfloor(y + s)

  -- Unskew the cell origin back to (x, y) space.
  var t: scalar_type = (ix + iy) * 0.211324865 -- G
  var x0: scalar_type = x + t - ix
  var y0: scalar_type = y + t - iy

  -- Calculate the contribution from the two fixed corners.
  -- A step of (1,0) in (i,j) means a step of (1-G,-G) in (x,y), and
  -- A step of (0,1) in (i,j) means a step of (-G,1-G) in (x,y).
  ix, iy = (ix and 0xFF), (iy and 0xFF)

  var perms, perms12, grads = nt.perms, nt.perms12, nt.grads3

  var n0 = getn_2d(ix, iy, x0, y0, perms, perms12, grads)
  var n2 = getn_2d(ix + 1, iy + 1, x0 - 0.577350270, y0 - 0.577350270,
                     perms, perms12, grads) -- G2

  --[[
  Determine other corner based on simplex (equilateral triangle) we are in:
  if x0 > y0 then
  ix, x1 = ix + 1, x1 - 1
  else
  iy, y1 = iy + 1, y1 - 1
  end
  ]]
  --var tii: int32 = cfloor(y0 - x0)
  --var xi: uint32 = tii >> 31 -- x0 >= y0 -- overly clever bitshifting
  var xi: int32 = [int32](x0 >= y0) -- let compiler figure it out instead
  var n1 = getn_2d(ix + xi, iy + (1 - xi),
                   x0 + 0.211324865 - xi, y0 - 0.788675135 + xi,
                   perms, perms12, grads) -- x0 + G - xi, y0 + G - (1 - xi)

  -- Add contributions from each corner to get the final noise value.
  -- The result is scaled to return values in the interval [-1,1].
  return 70.0 * (n0 + n1 + n2)
end

function m.simplex_2d(x, y)
  return m.simplex_2d_raw(x, y, m.noisetable_c)
end

-- 3D weight contribution
local terra getn_3d(ix: int32, iy: int32, iz: int32,
                    x: scalar_type, y: scalar_type, z: scalar_type,
                    perms: &uint8, perms12: &uint8, grads: &scalar_type): scalar_type
  var t = 0.6 - x*x - y*y - z*z
  var index = perms12[ix + perms[iy + perms[iz]]] * 3

  if t >= 0.0 then
    return (t*t)*(t*t) * (grads[index+0]*x + grads[index+1]*y + grads[index+2]*z)
  else
    return 0.0
  end
end

---
-- @param x
-- @param y
-- @param z
-- @return Noise value in the range [-1, +1]
terra m.simplex_3d_raw(x: scalar_type, y: scalar_type, z: scalar_type,
                       nt: &NoiseTable): scalar_type
  --[[
  3D skew factors:
  F = 1 / 3
  G = 1 / 6
  G2 = 2 * G
  G3 = 3 * G - 1
  ]]

  -- Skew the input space to determine which simplex cell we are in.
  var s = (x + y + z) / 3.0 -- 0.333333333 -- F
  var ix: int32, iy: int32, iz: int32 = cfloor(x + s), cfloor(y + s), cfloor(z + s)

  -- Unskew the cell origin back to (x, y, z) space.
  var t: scalar_type = (ix + iy + iz) / 6.0 -- 0.166666667 -- G
  var x0: scalar_type = x + t - ix
  var y0: scalar_type = y + t - iy
  var z0: scalar_type = z + t - iz

  -- Calculate the contribution from the two fixed corners.
  -- A step of (1,0,0) in (i,j,k) means a step of (1-G,-G,-G) in (x,y,z);
  -- a step of (0,1,0) in (i,j,k) means a step of (-G,1-G,-G) in (x,y,z);
  -- a step of (0,0,1) in (i,j,k) means a step of (-G,-G,1-G) in (x,y,z).
  ix, iy, iz = (ix and 0xFF), (iy and 0xFF), (iz and 0xFF)

  var perms, perms12, grads = nt.perms, nt.perms12, nt.grads3
  var n0 = getn_3d(ix, iy, iz, x0, y0, z0, perms, perms12, grads)
  var n3 = getn_3d(ix + 1, iy + 1, iz + 1, x0 - 0.5, y0 - 0.5, z0 - 0.5,
                   perms, perms12, grads) -- G3

  --[[
  Determine other corners based on simplex (skewed tetrahedron) we are in:
  local ix2, iy2, iz2 = ix, iy, iz

  if x0 >= y0 then
  ix2, x2 = ix + 1, x2 - 1

  if y0 >= z0 then -- X Y Z
  ix, iy2, x1, y2 = ix + 1, iy + 1, x1 - 1, y2 - 1
  elseif x0 >= z0 then -- X Z Y
  ix, iz2, x1, z2 = ix + 1, iz + 1, x1 - 1, z2 - 1
  else -- Z X Y
  iz, iz2, z1, z2 = iz + 1, iz + 1, z1 - 1, z2 - 1
  end
  else
  iy2, y2 = iy + 1, y2 - 1

  if y0 < z0 then -- Z Y X
  iz, iz2, z1, z2 = iz + 1, iz + 1, z1 - 1, z2 - 1
  elseif x0 < z0 then -- Y Z X
  iy, iz2, y1, z2 = iy + 1, iz + 1, y1 - 1, z2 - 1
  else -- Y X Z
  iy, ix2, y1, x2 = iy + 1, ix + 1, y1 - 1, x2 - 1
  end
  end
  ]]
  var yx: int32 = [int32](x0 > y0)  --rshift(floor(y0 - x0), 31) -- x0 >= y0
  var zy: int32 = [int32](y0 > z0) --rshift(floor(z0 - y0), 31) -- y0 >= z0
  var zx: int32 = [int32](x0 > z0) --rshift(floor(z0 - x0), 31) -- x0 >= z0

  var i1 = yx and (zy or zx) -- x >= y and (y >= z or x >= z)
  var j1 = (1 - yx) and zy -- x < y and y >= z
  var k1 = (1 - zy) and (1 - (yx and zx)) -- y < z and not (x >= y and x >= z)

  var i2 = yx or (zy and zx) -- x >= z or (y >= z and x >= z)
  var j2 = (1 - yx) or zy -- x < y or y >= z
  --var k2 = yx ^ zy -- (x >= y and y < z) xor (x < y and y >= z)
  var k2 = (1 - zx) or (zx and (1 - zy))

  var n1 = getn_3d(ix + i1, iy + j1, iz + k1,
                   x0 + (1.0/6.0) - i1, y0 + (1.0/6.0) - j1, z0 + (1.0/6.0) - k1,
                   perms, perms12, grads) -- G
  var n2 = getn_3d(ix + i2, iy + j2, iz + k2,
                  x0 + (1.0/3.0) - i2,  y0 + (1.0/3.0) - j2, z0 + (1.0/3.0) - k2,
                  perms, perms12, grads) -- G2

  -- Add contributions from each corner to get the final noise value.
  -- The result is scaled to stay just inside [-1,1]
  --return 1000 + yx*100 + zy*10 + k2
  return 32.0 * (n0 + n1 + n2 + n3)
end

function m.simplex_3d(x, y, z)
  return m.simplex_3d_raw_alt(x, y, z, m.noisetable_c)
end

function m.simplex_test(x, y, z)
  local v0 = m.simplex_3d_raw_alt(x, y, z, m.noisetable_c)
  local v1 = m.simplex_3d_raw(x, y, z, m.noisetable_c)
  return v0, v1
end

terra m.simplex_3d_raw_alt(xin: scalar_type, yin: scalar_type, zin: scalar_type,
                           nt: &NoiseTable): scalar_type

  var F2 = 0.5 * (cmath.sqrt(3.0) - 1.0)
  var G2 = (3.0 - cmath.sqrt(3.0)) / 6.0
  var F3 = 1.0 / 3.0
  var G3 = 1.0 / 6.0
  var F4 = (cmath.sqrt(5.0) - 1.0) / 4.0
  var G4 = (5.0 - cmath.sqrt(5.0)) / 20.0

  var permMod12 = nt.perms12
  var perm = nt.perms
  var grad3 = nt.grads3
  var n0: scalar_type, n1: scalar_type, n2: scalar_type, n3: scalar_type
  -- Skew the input space to determine which simplex cell we're in
  var s = (xin + yin + zin) * F3 -- Very nice and simple skew factor for 3D
  var i = cfloor(xin + s)
  var j = cfloor(yin + s)
  var k = cfloor(zin + s)
  var t = (i + j + k) * G3
  var X0 = i - t -- Unskew the cell origin back to (x,y,z) space
  var Y0 = j - t
  var Z0 = k - t
  var x0 = xin - X0 -- The x,y,z distances from the cell origin
  var y0 = yin - Y0
  var z0 = zin - Z0
  -- For the 3D case, the simplex shape is a slightly irregular tetrahedron.
  -- Determine which simplex we are in.
  var i1: int32, j1: int32, k1: int32 -- Offsets for second corner of simplex in (i,j,k) coords
  var i2: int32, j2: int32, k2: int32 -- Offsets for third corner of simplex in (i,j,k) coords
  if x0 >= y0 then
   if y0 >= z0 then
     i1 = 1
     j1 = 0
     k1 = 0
     i2 = 1
     j2 = 1
     k2 = 0
    -- X Y Z order
  elseif x0 >= z0 then
     i1 = 1
     j1 = 0
     k1 = 0
     i2 = 1
     j2 = 0
     k2 = 1
    --X Z Y order
  else
     i1 = 0
     j1 = 0
     k1 = 1
     i2 = 1
     j2 = 0
     k2 = 1
   end -- Z X Y order
 else  -- x0<y0
   if y0 < z0 then
     i1 = 0
     j1 = 0
     k1 = 1
     i2 = 0
     j2 = 1
     k2 = 1
     -- Z Y X order
   elseif x0 < z0 then
     i1 = 0
     j1 = 1
     k1 = 0
     i2 = 0
     j2 = 1
     k2 = 1
    -- Y Z X order
   else
     i1 = 0
     j1 = 1
     k1 = 0
     i2 = 1
     j2 = 1
     k2 = 0
   end -- Y X Z order
 end
  -- A step of (1,0,0) in (i,j,k) means a step of (1-c,-c,-c) in (x,y,z),
  -- a step of (0,1,0) in (i,j,k) means a step of (-c,1-c,-c) in (x,y,z), and
  -- a step of (0,0,1) in (i,j,k) means a step of (-c,-c,1-c) in (x,y,z), where
  -- c = 1/6.
  var x1 = x0 - i1 + G3 -- Offsets for second corner in (x,y,z) coords
  var y1 = y0 - j1 + G3
  var z1 = z0 - k1 + G3
  var x2 = x0 - i2 + 2.0 * G3 -- Offsets for third corner in (x,y,z) coords
  var y2 = y0 - j2 + 2.0 * G3
  var z2 = z0 - k2 + 2.0 * G3
  var x3 = x0 - 1.0 + 3.0 * G3 -- Offsets for last corner in (x,y,z) coords
  var y3 = y0 - 1.0 + 3.0 * G3
  var z3 = z0 - 1.0 + 3.0 * G3
  -- Work out the hashed gradient indices of the four simplex corners
  var ii = [int32](i) and 255
  var jj = [int32](j) and 255
  var kk = [int32](k) and 255
  -- Calculate the contribution from the four corners
  var t0 = 0.6 - x0 * x0 - y0 * y0 - z0 * z0
  if t0 < 0 then
     n0 = 0.0
  else
   var gi0 = permMod12[ii + perm[jj + perm[kk]]] * 3
   t0 = t0 * t0
   n0 = t0 * t0 * (grad3[gi0] * x0 + grad3[gi0 + 1] * y0 + grad3[gi0 + 2] * z0)
 end
  var t1 = 0.6 - x1 * x1 - y1 * y1 - z1 * z1
  if t1 < 0 then
     n1 = 0.0
  else
   var gi1 = permMod12[ii + i1 + perm[jj + j1 + perm[kk + k1]]] * 3
   t1 = t1 * t1
   n1 = t1 * t1 * (grad3[gi1] * x1 + grad3[gi1 + 1] * y1 + grad3[gi1 + 2] * z1)
 end
  var t2 = 0.6 - x2 * x2 - y2 * y2 - z2 * z2
  if t2 < 0 then
     n2 = 0.0
  else
   var gi2 = permMod12[ii + i2 + perm[jj + j2 + perm[kk + k2]]] * 3
   t2 = t2 * t2
   n2 = t2 * t2 * (grad3[gi2] * x2 + grad3[gi2 + 1] * y2 + grad3[gi2 + 2] * z2)
 end
  var t3 = 0.6 - x3 * x3 - y3 * y3 - z3 * z3
  if t3 < 0 then
     n3 = 0.0
  else
   var gi3 = permMod12[ii + 1 + perm[jj + 1 + perm[kk + 1]]] * 3
   t3 = t3 * t3
   n3 = t3 * t3 * (grad3[gi3] * x3 + grad3[gi3 + 1] * y3 + grad3[gi3 + 2] * z3)
 end
  -- Add contributions from each corner to get the final noise value.
  -- The result is scaled to stay just inside [-1,1]
  return 32.0 * (n0 + n1 + n2 + n3)
  --return k2
end

-- 4D weight contribution
local terra getn_4d(ix: int32, iy: int32, iz: int32, iw: int32,
              x: scalar_type, y: scalar_type, z: scalar_type, w: scalar_type,
              perms: &uint8, simplex: &uint8, grads: &scalar_type): scalar_type
  var t = 0.6 - x * x - y * y - z * z - w * w
  var index = (perms[ix + perms[iy + perms[iz + perms[iw]]]] and 0x1F) * 4

  return cmax(0.0, (t*t)*(t*t)) *
    (grads[index]*x + grads[index+1]*y + grads[index+2]*z + grads[index+3]*w)
end

---
-- @param x
-- @param y
-- @param z
-- @param w
-- @return Noise value in the range [-1, +1]
terra m.simplex_4d_raw(x: scalar_type, y: scalar_type, z: scalar_type, w: scalar_type,
                        nt: &NoiseTable): scalar_type
  --[[
  4D skew factors:
  F = (math.sqrt(5) - 1) / 4
  G = (5 - math.sqrt(5)) / 20
  G2 = 2 * G
  G3 = 3 * G
  G4 = 4 * G - 1
  ]]

  -- Skew the input space to determine which simplex cell we are in.
  var s = (x + y + z + w) * 0.309016994 -- F
  var ix: int32, iy: int32 = cfloor(x + s), cfloor(y + s)
  var iz: int32, iw: int32 = cfloor(z + s), cfloor(w + s)

  -- Unskew the cell origin back to (x, y, z) space.
  var t: scalar_type = (ix + iy + iz + iw) * 0.138196601 -- G
  var x0: scalar_type = x + t - ix
  var y0: scalar_type = y + t - iy
  var z0: scalar_type = z + t - iz
  var w0: scalar_type = w + t - iw

  -- For the 4D case, the simplex is a 4D shape I won't even try to describe.
  -- To find out which of the 24 possible simplices we're in, we need to
  -- determine the magnitude ordering of x0, y0, z0 and w0.
  -- The method below is a good way of finding the ordering of x,y,z,w and
  -- then find the correct traversal order for the simplex we’re in.
  -- First, six pair-wise comparisons are performed between each possible pair
  -- of the four coordinates, and the results are used to add up binary bits
  -- for an integer index.
  -- (do this with casting from booleans rather than brittle bit-shift trickery)
  var c1: int32 = [int32](x0 > y0) * 32 --(cfloor(y0 - x0) >> 26) and 32)
  var c2: int32 = [int32](x0 > z0) * 16 --(cfloor(z0 - x0) >> 27) and 16)
  var c3: int32 = [int32](y0 > z0) * 8  --(cfloor(z0 - y0) >> 28) and 8)
  var c4: int32 = [int32](x0 > w0) * 4  --(cfloor(w0 - x0) >> 29) and 4)
  var c5: int32 = [int32](y0 > w0) * 2  --(cfloor(w0 - y0) >> 30) and 2)
  var c6: int32 = [int32](z0 > w0)      --(cfloor(w0 - z0) >> 31)

  -- Simplex[c] is a 4-vector with the numbers 0, 1, 2 and 3 in some order.
  -- Many values of c will never occur, since e.g. x>y>z>w makes x<z, y<w and x<w
  -- impossible. Only the 24 indices which have non-zero entries make any sense.
  -- We use a thresholding to set the coordinates in turn from the largest magnitude.
  var c: int32 = (c1 + c2 + c3 + c4 + c5 + c6) * 4
  var perms = nt.perms
  var grads = nt.grads4
  var simplex = nt.simplex4d

  -- The number 3 (i.e. bit 2) in the "simplex" array is at the position of the largest coordinate.
  var i1 = simplex[c+0] >> 2
  var j1 = simplex[c+1] >> 2
  var k1 = simplex[c+2] >> 2
  var l1 = simplex[c+3] >> 2

  -- The number 2 (i.e. bit 1) in the "simplex" array is at the second largest coordinate.
  var i2 = (simplex[c+0] >> 1) and 1
  var j2 = (simplex[c+1] >> 1) and 1
  var k2 = (simplex[c+2] >> 1) and 1
  var l2 = (simplex[c+3] >> 1) and 1

  -- The number 1 (i.e. bit 0) in the "simplex" array is at the second smallest coordinate.
  var i3 = simplex[c+0] and 1
  var j3 = simplex[c+1] and 1
  var k3 = simplex[c+2] and 1
  var l3 = simplex[c+3] and 1

  -- Work out the hashed gradient indices of the five simplex corners
  -- Sum up and scale the result to cover the range [-1,1]
  ix, iy, iz, iw = (ix and 0xFF), (iy and 0xFF), (iz and 0xFF), (iw and 0xFF)

  var n0 = getn_4d(ix, iy, iz, iw, x0, y0, z0, w0, perms, simplex, grads)
  var n1 = getn_4d(ix + i1, iy + j1, iz + k1, iw + l1,
    x0 + 0.138196601 - i1, y0 + 0.138196601 - j1, z0 + 0.138196601 - k1, w0 + 0.138196601 - l1,
    perms, simplex, grads) -- G
  var n2 = getn_4d(ix + i2, iy + j2, iz + k2, iw + l2, x0 + 0.276393202 - i2,
    y0 + 0.276393202 - j2, z0 + 0.276393202 - k2, w0 + 0.276393202 - l2,
    perms, simplex, grads) -- G2
  var n3 = getn_4d(ix + i3, iy + j3, iz + k3, iw + l3, x0 + 0.414589803 - i3,
    y0 + 0.414589803 - j3, z0 + 0.414589803 - k3, w0 + 0.414589803 - l3,
    perms, simplex, grads) -- G3
  var n4 = getn_4d(ix + 1, iy + 1, iz + 1, iw + 1, x0 - 0.447213595,
    y0 - 0.447213595, z0 - 0.447213595, w0 - 0.447213595,
    perms, simplex, grads) -- G4

  return 27.0 * (n0 + n1 + n2 + n3 + n4)
end

function m.simplex_4d(x, y, z, w)
  return m.simplex_4d_raw(x, y, z, w, m.noisetable_c)
end

return m
