-- geometry/init.t
--
-- geometry metamodule

local module = require("core/module.t")
local geoutils = require("./geoutils.t")
local geometry = {}

-- creates a geometry from a geometry data using the default vertex type
function geometry.to_basic_geo(data, name, opts)
  local gfx = require("gfx")
  if opts.compute_normals ~= false and not data.attributes.normal then 
    geoutils.compute_normals(data) 
  end
  return gfx.StaticGeometry(name):from_data(data, opts.vertex_info)
end

local geo_registry = {}
local function include_geometry(fn)
  local temp = require("./" .. fn .. ".t")
  if not temp._geometries then return end
  for geo_name, geo_gen in pairs(temp._geometries) do
    if geo_registry[geo_name] then
      truss.error("Geometry " .. geo_name .. " already registered!")
    end
    geo_registry[geo_name] = true
    geometry[geo_name .. "_data"] = geo_gen
    geometry[geo_name .. "_geo"] = function(opts)
      local data = geo_gen(opts)
      return geometry.to_basic_geo(data, geo_name, opts or {})
    end
  end
end

include_geometry("cube")
include_geometry("off_center_cube")
include_geometry("cylinder")
include_geometry("icosphere")
include_geometry("plane")
include_geometry("polygon")
include_geometry("ribbon")
include_geometry("uvsphere")
include_geometry("widgets")
include_geometry("maxvol8")

geometry.util = {}
module.include_submodules({
  "geometry/geoutils.t",
  "geometry/merge.t"
}, geometry.util)

return geometry
