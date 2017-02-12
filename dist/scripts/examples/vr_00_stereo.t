-- vr_00_stereo.t
--
-- demonstration of using vrapp for a simple stereo pipeline

local VRApp = require("vr/vrapp.t").VRApp
local icosphere = require("geometry/icosphere.t")
local gfx = require("gfx")
local math = require("math")
local entity = require("ecs/entity.t")
local pipeline = require("graphics/pipeline.t")

local function rand_on_sphere(tgt)
  local ret = tgt or math.Vector()
  ret:set(1.0, 1.0, 1.0, 0.0)
  while ret:length() > 0.5 do
    ret:set(math.random()-0.5, math.random()-0.5, math.random()-0.5)
  end
  ret:normalize3()
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

  local thingy = entity.Entity3d()
  thingy.position:set(0.0, 0.5, 0.0)
  thingy:update_matrix()
  thingy:add_component(pipeline.MeshShaderComponent(geo, mat))
  root:add(thingy)

  for i = 1,100 do
    local subthingy = entity.Entity3d()
    subthingy:add_component(pipeline.MeshShaderComponent(geo, mat))
    rand_on_sphere(subthingy.position)
    subthingy.scale:set(0.2, 0.2, 0.2)
    subthingy:update_matrix()
    thingy:add(subthingy)
  end
end

function init()
  app = VRApp({title = "vr_00_stereo",
               width = 1280,
               height = 720})
  create_scene(app.ECS.scene)
end

local printed_projection = false
function update()
  app:update()
  if not printed_projection then
    log.info("Projection: " .. app.stereo_cams[1].camera.proj_mat:prettystr())
    printed_projection = true
  end
end
