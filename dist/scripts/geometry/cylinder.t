-- geometry/cylinder.t
--
-- generates a cylinder

local m = {}
local math = require("math")
local Vector = math.Vector

function m.cylinder_data(radius, height, nsegs, capped)
  capped = (capped == nil) or capped -- make it default to true

  local dtheta = 2.0 * math.pi / nsegs

  -- create vertices
  local positions = {}
  local yTop = height/2.0
  local yBot = -yTop
  for i = 1,nsegs do
    local theta = (i-1) * dtheta
    local x = math.cos(theta) * radius
    local z = math.sin(theta) * radius
    table.insert(positions, Vector(x, yTop, z, 0))
    table.insert(positions, Vector(x, yBot, z, 0))
  end

  local indices = {}
  -- tube
  for i = 0,nsegs-1 do
    local v0 = (i*2  ) % (nsegs * 2)
    local v1 = (i*2+1) % (nsegs * 2)
    local v2 = (i*2+2) % (nsegs * 2)
    local v3 = (i*2+3) % (nsegs * 2)
    table.insert(indices, {v0, v2, v1})
    table.insert(indices, {v1, v2, v3})
  end
  -- caps
  if capped then
    table.insert(positions, Vector(0, yTop, 0, 0))
    table.insert(positions, Vector(0, yBot, 0, 0))

    local v_top = #(positions)-2
    local v_bot = v_top + 1

    -- need to copy side vertices so they can have different normals in
    -- order to get a sharp edge on the caps
    for i = 1,nsegs*2 do
      table.insert(positions, Vector():copy(positions[i]))
    end

    for i = 0,nsegs-1 do
      local v0 = (v_bot + 1) + (i*2  ) % (nsegs * 2)
      local v1 = (v_bot + 1) + (i*2+2) % (nsegs * 2)
      table.insert(indices, {v1,   v0,   v_top})
      table.insert(indices, {v0+1, v1+1, v_bot})
    end
  end

  return {indices = indices, attributes = {position = positions}}
end

function m.cylinder_geo(radius, height, nsegs, capped, gname)
  local gfx = require("gfx")
  local geoutils = require("geometry/geoutils.t")
  local cylinder_data = m.cylinder_data(radius, height, nsegs, capped)
  geoutils.compute_normals(cylinder_data)
  return gfx.StaticGeometry(gname):from_data(cylinder_data)
end

return m
