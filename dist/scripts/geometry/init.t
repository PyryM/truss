-- geometry/init.t
--
-- geometry metamodule

local moduleutils = require("core/module.t")
local geometry = {}

moduleutils.include_submodules({
  "geometry/cube.t",
  "geometry/cylinder.t",
  "geometry/debugcube.t",
  "geometry/icosphere.t",
  "geometry/plane.t",
  "geometry/polygon.t",
  "geometry/uvsphere.t",
  "geometry/widgets.t",
  "geometry/geoutils.t"
}, geometry)

return geometry
