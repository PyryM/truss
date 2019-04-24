-- vr_basic.t
--
-- basic demonstration of vr

local VRApp = require("vr/vrapp.t").VRApp
local geometry = require("geometry")
local pbr = require("material/pbr.t")
local gfx = require("gfx")
local graphics = require("graphics")
local ecs = require("ecs")
local Grid = require("graphics/grid.t").Grid
local vrcomps = require("vr/components.t")

function randu(magnitude)
  return (math.random() * 2.0 - 1.0)*(magnitude or 1.0)
end

local Jiggler = ecs.UpdateComponent:extend("Jiggler")
function Jiggler:update()
  local p = self.ent.position
  p.elem.x = p.elem.x + randu(0.01)
  p.elem.y = p.elem.y + randu(0.01)
  p.elem.z = p.elem.z + randu(0.01)
  self.ent:update_matrix()
end

function create_geometry()
  local geo = geometry.icosphere_geo{radius = 0.1, detail = 3}
  local mat = pbr.PBRMaterial{
    diffuse = {0.03,0.03,0.03,1.0},
    tint = {0.001, 0.001, 0.001}, 
    roughness = 0.7
  }
  for i = 1, 200 do
    local sphere = app.scene:create_child(graphics.Mesh, 'sphere', geo, mat)
    sphere:add_component(Jiggler())
    sphere.position:set(randu(0.5), randu(0.5)+1.0, randu(0.5))
    sphere:update_matrix()
  end
end

function init()
  app = VRApp{
    title = "vr_basic", stats = true,
    width = 1280, height = 720,
    create_controllers = true
  }
  local grid = app.scene:create_child(Grid, "grid", {
    thickness = 0.005, color = {0.6, 0.6, 0.6, 1}
  })
  grid.quaternion:euler({x = math.pi / 2.0, y = 0.0, z = 0.0})
  grid:update_matrix()

  local bounds = app.scene:create_child(vrcomps.Bounds, "bounds", {
    color = {0.6, 0.6, 0.3, 1}, thickness = 0.2
  })

  create_geometry()
end

function update()
  app:update()
end
