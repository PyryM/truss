-- plane.t
--
-- makes a (subdivided) plane

local m = {}
local math = require("math")
local Vector = math.Vector

function m.plane_data(opts)
  local position = {}
  local texcoord0 = {}
  local normal = {}
  local indices = {}

  opts = opts or {}
  local width, height = opts.width or 1, opts.height or 1
  local divs = opts.segments
  local wdivs, hdivs = opts.wdivs or divs or 2, opts.hdivs or divs or 2
  local umin, umax = opts.umin or 0, opts.umax or 1
  local vmin, vmax = opts.vmin or 0, opts.vmax or 1

  local dx = width / wdivs
  local dy = height / hdivs

  local x0 = -(width / 2)
  local y0 = -(height / 2)

  local umult, uoffset = umax - umin, umin
  local vmult, voffset = vmax - vmin, vmin

  -- create vertices
  for iy = 0, hdivs do
    for ix = 0, wdivs do
      local x, y = x0 + ix*dx, y0 + iy*dy
      local u, v = ix / wdivs, iy / hdivs
      u, v = u*umult + uoffset, v*vmult + voffset
      table.insert(position, Vector(x, y, 0))
      table.insert(texcoord0, Vector(u, v))
      table.insert(normal, Vector(0, 0, 1))
    end
  end

  local function v(ix,iy)
    return iy*(wdivs+1) + ix
  end

  -- create indices
  -- 3:(0,1) +------+ 2:(1,1)
  --         |    / |
  --         | /    |
  -- 0:(0,0) +------+ 1:(1,0)
  for iy = 0, (hdivs-1) do
    for ix = 0, (wdivs-1) do
      table.insert(indices, {v(ix,iy), v(ix+1,iy), v(ix+1,iy+1)})
      table.insert(indices, {v(ix,iy), v(ix+1,iy+1), v(ix,iy+1)})
    end
  end

  return {indices = indices,
          attributes = {position = position,
                        normal = normal,
                        texcoord0 = texcoord0}
          }
end

m._geometries = {plane = m.plane_data}

return m
