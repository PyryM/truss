
do

  end
--[[
  -- Timing test, 3D case
  local S = M.Simplex3D
  local mmin, mmax = math.min, math.max
  local fmin, fmax = 10000, -10000
  local v = require("jit.dump")
  local t1 = os.clock()
-- v.start("tisH", "SOME_DIRECTORY/Simplex3D.html")	-- Customize this
  for i = -50, 50 do
  for j = -50, 50 do
  for k = -50, 50 do
  local f = S(i + .5, j + .4, k + .1)
  fmin = mmin(fmin, f)
  fmax = mmax(fmax, f)
  end
  end
  end
-- v.off()
  printf("Simplex3D: time / call = %.9f, min = %f, max = %f", (os.clock() - t1) / (101 * 101 * 101), fmin, fmax)
--]]
end

do


  -- 4D weight contribution
  local function GetN (ix, iy, iz, iw, x, y, z, w)
  local t = .6 - x * x - y * y - z * z - w * w
  local index = band(Perms[ix + Perms[iy + Perms[iz + Perms[iw]]]], 0x1F)

  return max(0, (t * t) * (t * t)) * (Grads4[index][0] * x + Grads4[index][1] * y + Grads4[index][2] * z + Grads4[index][3] * w)
  end

  -- Convert the above indices to masks that can be shifted / anded into offsets --
  for i = 1, 64 do
  Simplex[i][0] = lshift(1, Simplex[i][0]) - 1
  Simplex[i][1] = lshift(1, Simplex[i][1]) - 1
  Simplex[i][2] = lshift(1, Simplex[i][2]) - 1
  Simplex[i][3] = lshift(1, Simplex[i][3]) - 1
  end

  ---
  -- @param x
  -- @param y
  -- @param z
  -- @param w
  -- @return Noise value in the range [-1, +1]
  function M.Simplex4D (x, y, z, w)
  --[[
  4D skew factors:
  F = (math.sqrt(5) - 1) / 4
  G = (5 - math.sqrt(5)) / 20
  G2 = 2 * G
  G3 = 3 * G
  G4 = 4 * G - 1
  ]]

  -- Skew the input space to determine which simplex cell we are in.
  local s = (x + y + z + w) * 0.309016994 -- F
  local ix, iy, iz, iw = floor(x + s), floor(y + s), floor(z + s), floor(w + s)

  -- Unskew the cell origin back to (x, y, z) space.
  local t = (ix + iy + iz + iw) * 0.138196601 -- G
  local x0 = x + t - ix
  local y0 = y + t - iy
  local z0 = z + t - iz
  local w0 = w + t - iw

  -- For the 4D case, the simplex is a 4D shape I won't even try to describe.
  -- To find out which of the 24 possible simplices we're in, we need to
  -- determine the magnitude ordering of x0, y0, z0 and w0.
  -- The method below is a good way of finding the ordering of x,y,z,w and
  -- then find the correct traversal order for the simplex we’re in.
  -- First, six pair-wise comparisons are performed between each possible pair
  -- of the four coordinates, and the results are used to add up binary bits
  -- for an integer index.
  local c1 = band(rshift(floor(y0 - x0), 26), 32)
  local c2 = band(rshift(floor(z0 - x0), 27), 16)
  local c3 = band(rshift(floor(z0 - y0), 28), 8)
  local c4 = band(rshift(floor(w0 - x0), 29), 4)
  local c5 = band(rshift(floor(w0 - y0), 30), 2)
  local c6 = rshift(floor(w0 - z0), 31)

  -- Simplex[c] is a 4-vector with the numbers 0, 1, 2 and 3 in some order.
  -- Many values of c will never occur, since e.g. x>y>z>w makes x<z, y<w and x<w
  -- impossible. Only the 24 indices which have non-zero entries make any sense.
  -- We use a thresholding to set the coordinates in turn from the largest magnitude.
  local c = c1 + c2 + c3 + c4 + c5 + c6

  -- The number 3 (i.e. bit 2) in the "simplex" array is at the position of the largest coordinate.
  local i1 = rshift(Simplex[c][0], 2)
  local j1 = rshift(Simplex[c][1], 2)
  local k1 = rshift(Simplex[c][2], 2)
  local l1 = rshift(Simplex[c][3], 2)

  -- The number 2 (i.e. bit 1) in the "simplex" array is at the second largest coordinate.
  local i2 = band(rshift(Simplex[c][0], 1), 1)
  local j2 = band(rshift(Simplex[c][1], 1), 1)
  local k2 = band(rshift(Simplex[c][2], 1), 1)
  local l2 = band(rshift(Simplex[c][3], 1), 1)

  -- The number 1 (i.e. bit 0) in the "simplex" array is at the second smallest coordinate.
  local i3 = band(Simplex[c][0], 1)
  local j3 = band(Simplex[c][1], 1)
  local k3 = band(Simplex[c][2], 1)
  local l3 = band(Simplex[c][3], 1)

  -- Work out the hashed gradient indices of the five simplex corners
  -- Sum up and scale the result to cover the range [-1,1]
  ix, iy, iz, iw = band(ix, 255), band(iy, 255), band(iz, 255), band(iw, 255)

  local n0 = GetN(ix, iy, iz, iw, x0, y0, z0, w0)
  local n1 = GetN(ix + i1, iy + j1, iz + k1, iw + l1, x0 + 0.138196601 - i1, y0 + 0.138196601 - j1, z0 + 0.138196601 - k1, w0 + 0.138196601 - l1) -- G
  local n2 = GetN(ix + i2, iy + j2, iz + k2, iw + l2, x0 + 0.276393202 - i2, y0 + 0.276393202 - j2, z0 + 0.276393202 - k2, w0 + 0.276393202 - l2) -- G2
  local n3 = GetN(ix + i3, iy + j3, iz + k3, iw + l3, x0 + 0.414589803 - i3, y0 + 0.414589803 - j3, z0 + 0.414589803 - k3, w0 + 0.414589803 - l3) -- G3
  local n4 = GetN(ix + 1, iy + 1, iz + 1, iw + 1, x0 - 0.447213595, y0 - 0.447213595, z0 - 0.447213595, w0 - 0.447213595) -- G4

  return 27 * (n0 + n1 + n2 + n3 + n4)
  end

--[[
  -- Timing test, 4D case
  local S = M.Simplex4D
  local mmin, mmax = math.min, math.max
  local fmin, fmax = 10000, -10000
  local v = require("jit.dump")
  local t1 = os.clock()
-- v.start("tisH", "SOME_DIRECTORY/Simplex4D.html")
  for i = -25, 25 do
  for j = -25, 25 do
  for k = -25, 25 do
  for l = -25, 25 do
  local f = S(i + .5, j + .4, k + .1, l + .7)
  fmin = mmin(fmin, f)
  fmax = mmax(fmax, f)
  end
  end
  end
  end
-- v.off()
  printf("Simplex4D: time / call = %.9f, min = %f, max = %f", (os.clock() - t1) / (51 * 51 * 51 * 51), fmin, fmax)
--]]
end

-- For testing, uncomment this:
  -- printf("%.9f", os.clock() - t1) -- Total test time

--[=[
-- Customize as needed to dump values to a file, e.g. to compare against other implementations:
local F = io.open("SOME_DIRECTORY/LuaOut.txt", "w")
if F then
--[[
  for i = 1, 50 do
  for j = 1, 50 do
  local f = M.Simplex2D(i + .5, j + .3)
  F:write(string.format("(%i, %i): %f\n", i, j, f))
  end
  end
--]]
--[[
  for i = -1, -50, -1 do
  for j = -1, -50, -1 do
  for k = -1, -50, -1 do
  local f = M.Simplex3D(i + .5, j + .4, k + .1)
  F:write(string.format("(%i, %i, %i): %f\n", i, j, k, f))
  end
  end
  end
--]]
--[[
  for i = -1, -50, -1 do
  for j = -1, -50, -1 do
  for k = -1, -50, -1 do
  for l = -1, -50, -1 do
  local f = M.Simplex4D(i + .5, j + .4, k + .1, l + .7)
  F:write(string.format("(%i, %i, %i, %i): %f\n", i, j, k, l, f))
  end
  end
  end
  end
--]]
  F:close()
end
--]=]

-- Export the module.
return M
