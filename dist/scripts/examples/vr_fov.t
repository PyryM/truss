-- vr_fov.t
--
-- fov testing

local gfx = require("gfx")
local math = require("math")
local ecs = require("ecs")
local graphics = require("graphics")
local geometry = require("geometry")
local grid = require("graphics/grid.t")

local VRApp = require("vr/vrapp.t").VRApp
local openvr = require("vr/openvr.t")
local vrcomps = require("vr/components.t")

local pbr = require("shaders/pbr.t")
local flat = require("shaders/flat.t")


function init()
  app = VRApp({title = "vr fov testing", nvg = false,
               mirror = "both", stats = true, 
               create_controllers = true})
  create_scene(app.ECS.scene)
end

function update()
  app:update()
  if not debug_printed then
    openvr.print_debug_info()
    debug_printed = true
  end
end

----------------------------------------------------------------------------
--- Scene setup
----------------------------------------------------------------------------

-- create a big red ball so that there's something to see at least
function create_scene(root)
  local geo = geometry.icosphere_geo(1.0, 3, "ico")
  local mat = pbr.FacetedPBRMaterial({0.2,0.03,0.01,1.0},
                                     {0.001, 0.001, 0.001}, 0.7)

  local thegrid = root:create_child(grid.Grid, {spacing = 0.5, numlines = 8,
                                                color = {0.8, 0.8, 0.8}, 
                                                thickness = 0.003})
  thegrid.quaternion:euler({x = -math.pi / 2.0, y = 0, z = 0}, 'ZYX')
  thegrid:update_matrix()

  local axis_geo = geometry.axis_widget_geo(0.4, 0.2, 6)
  local m2 = root:create_child(graphics.Mesh, "axis0", axis_geo, mat)
  m2.position:set(0.0, 1.0, -1.0)
  m2:update_matrix()

  local tex = gfx.load_texture("textures/test_pattern.png")
  local mat = flat.FlatMaterial{texture = tex}
  local geo = geometry.plane_geo(1.0, 1.0, 2, 2, "plane")

  local target = root:create_child(graphics.Mesh, "calibtarget", geo, mat)
  target.position:set(0.0, 1.0, 0.0)
  target.quaternion:euler({x = 0.0, y = math.pi, z = 0.0})
  target:update_matrix()
end