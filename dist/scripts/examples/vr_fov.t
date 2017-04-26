-- vr_fov.t
--
-- fov testing

local VRApp = require("vr/vrapp.t").VRApp
local icosphere = require("geometry/icosphere.t")
local gfx = require("gfx")
local math = require("math")
local entity = require("ecs/entity.t")
local pipeline = require("graphics/pipeline.t")
local openvr = require("vr/openvr.t")
local vrcomps = require("vr/components.t")
local grid = require("graphics/grid.t")
local pbr = require("shaders/pbr.t")
local flat = require("shaders/flat.t")
local plane = require("geometry/plane.t")

function init()
  app = VRApp({title = "vr fov testing", nvg = false,
               mirror = "both", debugtext = true})
  create_scene(app.ECS.scene)
  openvr.on("trackable_connected", add_trackable)
  openvr.print_debug_info()
end

function update()
  app:update()
end

function add_trackable(trackable)
  local device_class = trackable.device_class_name
  if device_class == "Controller" then
    add_trackable_model(trackable)
  end
end

----------------------------------------------------------------------------
--- Graphics setup
----------------------------------------------------------------------------


-- create a big red ball so that there's something to see at least
function create_scene(root)
  local geo = icosphere.icosphere_geo(1.0, 3, "ico")
  -- uniforms.u_baseColor:set(math.Vector(0.2,0.03,0.01,1.0))
  -- uniforms.u_pbrParams:set(math.Vector(0.001, 0.001, 0.001, 0.7))

  local mat = pbr.FacetedPBRMaterial({0.2,0.03,0.01,1.0},
                                     {0.001, 0.001, 0.001}, 0.7)
  sphere_geo = geo
  sphere_mat = mat

  local thegrid = grid.Grid({ spacing = 0.5, numlines = 8,
                              color = {0.8, 0.8, 0.8}, thickness = 0.003})
  thegrid.quaternion:euler({x= -math.pi / 2.0, y=0, z=0}, 'ZYX')
  thegrid:update_matrix()
  root:add(thegrid)

  local axis_geo = require("geometry/widgets.t").axis_widget_geo("axis", 0.4, 0.2, 6)
  root:add(pipeline.Mesh("axis0", axis_geo, mat))

  local m2 = pipeline.Mesh("axis0", axis_geo, mat)
  m2.position:set(0.0, 1.0, -1.0)
  m2:update_matrix()
  root:add(m2)

  add_target(root)
end

function add_target(root)
  local tex = gfx.load_texture("textures/test_pattern.png")
  local mat = flat.FlatMaterial{texture = tex}
  local geo = plane.plane_geo(1.0, 1.0, 2, 2, "plane")

  local target = pipeline.Mesh("calibtarget", geo, mat)
  target.position:set(0.0, 1.0, 0.0)
  target.quaternion:euler({x = 0.0, y = math.pi, z = 0.0})
  target:update_matrix()
  root:add(target)
end

-- adds the controller model in
function add_trackable_model(trackable)
  local geo = icosphere.icosphere_geo(0.1, 3, "cico")
  local m2 = {
    state = sphere_mat.state,
    program = sphere_mat.program,
    uniforms = sphere_mat.uniforms:clone()
  }
  m2.uniforms.u_baseColor:set(math.Vector(0.03,0.03,0.03,1.0))
  m2.uniforms.u_pbrParams:set(math.Vector(0.001, 0.001, 0.001, 0.7))

  local controller = entity.Entity3d()
  controller:add_component(pipeline.MeshShaderComponent(geo, m2))
  controller:add_component(vrcomps.VRTrackableComponent(trackable))
  controller.vr_trackable:load_geo_to_component("mesh_shader")

  app.ECS.scene:add(controller)
end
