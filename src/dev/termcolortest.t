local colorspaces = require("math/colorspaces.t")
local term = truss.term

local function tofloatarr(c)
  local fc = terralib.new(float[3])
  c = colorspaces.parse_color_to_rgbf(c)
  fc[0] = c[1]
  fc[1] = c[2]
  fc[2] = c[3]
  colorspaces.rgb2lab(fc, fc, true)
  return fc
end

local function fromfloatarr(fc)
  local ret = {}
  for idx = 0, 2 do ret[idx+1] = math.floor(fc[idx]) end
  return ret
end

local function linterp(a, b, dest, alpha)
  for idx = 0, 2 do 
    dest[idx] = a[idx] + (b[idx] - a[idx])*alpha 
  end
end

local function gradient(a, b, nsteps, blocksize)
  nsteps = nsteps or 64
  blocksize = blocksize or 1
  local blocks = {}
  local c0 = tofloatarr(a)
  local c1 = tofloatarr(b)
  local interpc = terralib.new(float[3])
  local body = (" "):rep(blocksize)
  for idx = 0, nsteps-1 do
    local alpha = idx / (nsteps-1)
    linterp(c0, c1, interpc, alpha)
    colorspaces.lab2rgb(interpc, interpc, false)
    local rgb = fromfloatarr(interpc)
    local block = term.color_rgb({0, 0, 0}, rgb) .. body .. term.RESET
    table.insert(blocks, block)
  end
  return table.concat(blocks)
end

local function main()
  log.crit("_PKGPATH:", _PKGPATH)
  log.crit("_FILEPATH:", _FILEPATH)
  log.crit(gradient(0xFFAA00FF, 0xFF0000FF))
  log.crit(gradient(0x00FFFFFF, 0x00FF00FF))
  log.crit(gradient(0xFFFFFFFF, 0x000000FF))
  log.crit(gradient(0xCC11FFFF, 0x0000FFFF))
end

return {main = main}