-- vr_00_stereo.t
--
-- demonstration of using vrapp for a simple stereo pipeline

local VRApp = require("vr/vrapp.t").VRApp
local icosphere = require("geometry/icosphere.t")
local gfx = require("gfx")
local math = require("math")
local entity = require("ecs/entity.t")
local pipeline = require("graphics/pipeline.t")
local openvr = require("vr/openvr.t")
local vrcomps = require("vr/components.t")

local function rand_on_sphere(tgt, m)
  local ret = tgt or math.Vector()
  ret:set(1.0, 1.0, 1.0, 0.0)
  while ret:length() > 0.5 do
    ret:set(math.random()-0.5, math.random()-0.5, math.random()-0.5)
  end
  ret:normalize3()
  ret:multiply(m or 1.0)
  return ret
end

function create_uniforms()
  local uniforms = gfx.UniformSet()
  uniforms:add(gfx.VecUniform("u_baseColor"))
  uniforms:add(gfx.VecUniform("u_pbrParams"))
  uniforms:add(gfx.VecUniform("u_lightDir", 4))
  uniforms:add(gfx.VecUniform("u_lightRgb", 4))

  uniforms.u_lightDir:set_multiple({
          math.Vector( 1.0,  1.0,  0.0),
          math.Vector(-1.0,  1.0,  0.0),
          math.Vector( 0.0, -1.0,  1.0),
          math.Vector( 0.0, -1.0, -1.0)})

  uniforms.u_lightRgb:set_multiple({
          math.Vector(0.8, 0.8, 0.8),
          math.Vector(1.0, 1.0, 1.0),
          math.Vector(0.1, 0.1, 0.1),
          math.Vector(0.1, 0.1, 0.1)})

  uniforms.u_baseColor:set(math.Vector(0.2,0.03,0.01,1.0))
  uniforms.u_pbrParams:set(math.Vector(0.001, 0.001, 0.001, 0.7))
  return uniforms
end

function create_scene(root)
  -- create material and geometry
  local geo = require("geometry/icosphere.t").icosphere_geo(1.0, 3, "ico")
  local mat = {
    state = gfx.create_state(),
    uniforms = create_uniforms(),
    program = gfx.load_program("vs_basicpbr", "fs_basicpbr_faceted_x4")
  }
  sphere_geo = geo
  sphere_mat = mat

  local thingy = entity.Entity3d()
  thingy.position:set(0.0, 0.5, 0.0)
  thingy:update_matrix()
  thingy:add_component(pipeline.MeshShaderComponent(geo, mat))
  root:add(thingy)

  for i = 1,100 do
    local subthingy = entity.Entity3d()
    subthingy:add_component(pipeline.MeshShaderComponent(geo, mat))
    rand_on_sphere(subthingy.position, 1.4)
    subthingy.scale:set(0.2, 0.2, 0.2)
    subthingy:update_matrix()
    thingy:add(subthingy)
  end
end

function add_controller(trackable)
  if trackable.device_class_name ~= "Controller" then return end

  local geo = require("geometry/icosphere.t").icosphere_geo(0.1, 3, "cico")
  local m2 = {
    state = sphere_mat.state,
    program = sphere_mat.program,
    uniforms = sphere_mat.uniforms:clone()
  }
  m2.uniforms.u_baseColor:set(math.Vector(0.03,0.03,0.03,1.0))
  m2.uniforms.u_pbrParams:set(math.Vector(0.001, 0.001, 0.001, 0.7))

  local controller = entity.Entity3d()
  controller:add_component(pipeline.MeshShaderComponent(geo, m2))
  controller:add_component(vrcomps.VRControllerComponent(trackable))

  app.ECS.scene:add(controller)
end

function init()
  app = VRApp({title = "vr_00_stereo",
               mirror = "left"})
  create_scene(app.ECS.scene)
  openvr.on("trackable_connected", add_controller)
end

function update()
  app:update()
end
