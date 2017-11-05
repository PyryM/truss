-- geometry/maxvol8.t
--
-- the maximum volume 8 vertex polyhedron that fits in unit sphere
-- (I dunno what the use of this is but...)

local m = {}
local math = require("math")
local geoutils = require("geometry/geoutils.t")

function m.maxvol8_data()
  local phi = math.acos(math.sqrt((15 + math.sqrt(145)) / 40))
  local V = math.Vector
  local verts = {
    V( math.sin(3*phi), 0, math.cos(3*phi)), 
    V(-math.sin(3*phi), 0, math.cos(3*phi)),
    V( math.sin(phi), 0, math.cos(phi)),
    V(-math.sin(phi), 0, math.cos(phi)),
    V(0,  math.sin(3*phi), -math.cos(3*phi)),
    V(0, -math.sin(3*phi), -math.cos(3*phi)),
    V(0,  math.sin(phi), -math.cos(phi)),
    V(0, -math.sin(phi), -math.cos(phi))
  }
  return geoutils.brute_force_hull(verts)
end
m._geometries = {maxvol8 = m.maxvol8_data}

return m