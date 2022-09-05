-- vr_input.t
--
-- 'new' openvr input system

local gfx = require("gfx")
local math = require("math")
local ecs = require("ecs")
local graphics = require("graphics")
local geometry = require("geometry")
local grid = require("graphics/grid.t")

local VRApp = require("vr/vrapp.t").VRApp

local pbr = require("material/pbr.t")
local flat = require("material/flat.t")

function vr_button_event(_, evtname, evt)
  print("VR button event: " .. evt.path .. " => " .. evt.down)
end

function vr_pose_event(_, evtname, evt)
  if not pose_follower then return end
  pose_follower.matrix:copy(evt.matrix)
end

function init()
  -- OpenVR needs to actually write a .json to disk so we
  -- need write paths to be properly set
  truss.set_app_directories("truss", "vr_input_example")
  app = VRApp{
    title = "vr input", nvg = false,
    mirror = "both", stats = true, 
    create_controllers = true,
    new_input = true
  }
  local actions = app.action_sets.main
  actions.primary:on("change", app, vr_button_event)
  actions.secondary:on("change", app, vr_button_event)
  actions.mainhand:on("change", app, vr_pose_event)
  create_scene(app.ECS.scene)
end

function update()
  app:update()
end

----------------------------------------------------------------------------
--- Scene setup
----------------------------------------------------------------------------
function create_scene(root)
  local thegrid = root:create_child(grid.Grid, "grid", 
                                    {spacing = 0.5, numlines = 8,
                                     color = {0.8, 0.8, 0.8}, 
                                     thickness = 0.003})
  thegrid.quaternion:euler({x = -math.pi / 2.0, y = 0, z = 0}, 'ZYX')
  thegrid:update_matrix()

  local axis_geo = geometry.axis_widget_geo{}
  local axis_mat = pbr.FacetedPBRMaterial{
    diffuse = {0.2,0.03,0.01,1.0},
    tint = {0.001, 0.001, 0.001}, 
    roughness = 0.7
  }
  pose_follower = root:create_child(graphics.Mesh, "axis0", axis_geo, axis_mat)
  pose_follower.position:set(0.0, 1.0, 0.0)
  pose_follower.scale:set(0.2, 0.2, 0.2)
  pose_follower:update_matrix()
end