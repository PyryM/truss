-- new_screencap.t
--
-- example of screen capture

local class = require("class")
local gfx = require("gfx")
local ecs = require("ecs/ecs.t")
local component = require("ecs/component.t")
local entity = require("ecs/entity.t")
local sdl_input = require("ecs/sdl_input.t")
local sdl = require("addons/sdl.t")
local math = require("math")
local pipeline = require("graphics/pipeline.t")
local framestats = require("graphics/framestats.t")
local screencap = require("addons/screencap.t")
local camera = require("graphics/camera.t")
local orbitcam = require("gui/orbitcam.t")
local material = require("graphics/material.t")

width = 800
height = 600

function init_ecs()
  -- basic init
  sdl.create_window(width, height, 'screencap')
  gfx.init_gfx({msaa = true, debugtext = true, window = sdl, lowlatency = true})

  -- create ecs
  ECS = ecs.ECS()
  ECS:add_system(sdl_input.SDLInputSystem())
  local p = ECS:add_system(pipeline.Pipeline({verbose = true}))
  p:add_stage(pipeline.Stage({
    name = "solid_geo",
    clear = {color = 0x303050ff, depth = 1.0},
  }, {pipeline.GenericRenderOp(), camera.CameraControlOp()}))
  ECS:add_system(framestats.DebugTextStats())

  local cam = camera.Camera({fov = 65, aspect = width/height})
  cam:add_component(sdl_input.SDLInputComponent())
  cam:add_component(orbitcam.OrbitControl({min_rad = 1.0, max_rad = 15.0}))
  ECS.scene:add(cam)

  ECS.scene:add_component(sdl_input.SDLInputComponent())
  ECS.scene:on("keydown", function(entity, evt)
    local keyname = ffi.string(evt.keycode)
    if keyname == "F1" then
      print("Capturing snapshot!")
      take_snapshot()
    end
  end)
end

function create_uniforms()
  local uniforms = gfx.UniformSet()
  uniforms:add(gfx.VecUniform("u_baseColor"))
  uniforms:add(gfx.TexUniform("s_texAlbedo", 0))
  uniforms.u_baseColor:set(math.Vector(1.0,1.0,1.0,1.0))
  return uniforms
end

function init()
  init_ecs()

  -- create material and geometry
  geo = require("geometry/cube.t").cube_geo(10.0, 10.0, 3.0, "cube")
  live_mat = material.Material{
    state = gfx.create_state(),
    uniforms = create_uniforms(),
    program = gfx.load_program("vs_flat", "fs_flattextured")
  }

  live_mat.uniforms.s_texAlbedo:set(gfx.load_texture('textures/cone.png'))
  snapshot_mat = live_mat:clone()

  local thecube = pipeline.Mesh("cube", geo, live_mat)
  thecube.position:set(-6, 0, 0)
  thecube:update_matrix()
  ECS.scene:add(thecube)

  local cube2 = pipeline.Mesh("cube2", geo, snapshot_mat)
  cube2.position:set(6, 0, 0)
  cube2:update_matrix()
  ECS.scene:add(cube2)

  screencap.start_capture()
end

local captex = nil
local snaptex = nil
function take_snapshot()
  if not captex then return end
  if not snaptex then
    snaptex = gfx.Texture()
  end
  snaptex:copy(captex)
  snapshot_mat.uniforms.s_texAlbedo:set(snaptex)
end

function update()
  -- Note: because of framerate, vsync, etc. timing, not every call to
  -- capture_screen will return a texture.
  local newcaptex = screencap.capture_screen()
  if newcaptex then
    captex = newcaptex
    live_mat.uniforms.s_texAlbedo:set(newcaptex)
  end
  ECS:update()
end
