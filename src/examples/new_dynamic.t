-- new_dynamic.t
--

local App = require("app/app.t").App
local gfx = require("gfx")
local geometry = require("geometry")
local graphics = require("graphics")
local pbr = require("material/pbr.t")
local orbitcam = require("graphics/orbitcam.t")
local simplex = require("procgen/simplex.t")

local function chained_simplex(x, y, z, mults)
  for _, m in ipairs(mults) do
    local nx = simplex.simplex_3d(x*m, y*m, z*m)
    local ny = simplex.simplex_3d((x+0.2)*m, (y+0.2)*m, (z+0.2)*m)
    local nz = simplex.simplex_3d((x+0.3)*m, (y+0.3)*m, (z+0.3)*m)
    x, y, z = nx, ny, nz
  end
  return x, y, z
end

local function update_geo(geo)
  local nverts = geo.n_verts
  local mult = 0.0001
  for i = 0, nverts-1 do
    local pos = geo.verts[i].position
    local x, y, z = pos[0], pos[1], pos[2]
    local dx, dy, dz = chained_simplex(x, y, z, {1,1.1})
    pos[0], pos[1], pos[2] = x+(dx*mult), y+(dy*mult), z+(dz*mult)
  end
  geo:update_vertices() -- could also do geo:update()
end

local function create_geo()
  local data = geometry.icosahedron_data{radius = 0.75}
  data.attributes.texcoord0 = nil
  for i = 1,6 do
    data = geometry.util.subdivide(data)
  end
  return gfx.DynamicGeometry("tri"):from_data(data)
end

local dyngeo = nil
function init()
  app = App{
    width = 1280, height = 720, 
    title = "Dynamic Geometry Example", 
    msaa = true
  }
  app.camera:add_component(orbitcam.OrbitControl{
    min_rad = 1, max_rad = 4
  })

  dyngeo = create_geo()
  local mat = pbr.FacetedPBRMaterial{
    diffuse = {0.002, 0.002, 0.002, 1.0}, 
    tint = {0.1, 0.1, 0.1}, 
    roughness = 0.7
  }
  app.scene:create_child(graphics.Mesh, "dynamic_cube", dyngeo, mat)
end

function update()
  update_geo(dyngeo)
  app:update()
end
