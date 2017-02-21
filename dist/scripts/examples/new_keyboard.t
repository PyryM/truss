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
local nvg = require("graphics/nanovg.t")

local camera = require("graphics/camera.t")
local orbitcam = require("gui/orbitcam.t")

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

function create_geo()
  return require("geometry/icosphere.t").icosphere_geo(1.0, 3, "ico")
end

local Jumper = component.Component:extend("Jumper")
function Jumper:init(k, p0, d)
  self.k = k
  self.p0 = p0:clone()
  self.d = d:clone()
  self.d.elem.w = 0.0
  self.d:normalize3()
  self.v = 0.0
  self.h = 0.0
end

local ACC = -2.0
local JUMP_V = 2.0
local JUMP_P = 0.25
function Jumper:on_update()
  local dt = 1.0 / 60.0
  self.v = self.v + ACC * dt
  self.h = self.h + self.v * dt
  if self.h < 0.0 then self.h = 0.0 end
  -- position = p0*1.0 + d*h
  self._entity.position:lincomb(self.p0, self.d, 1.0, self.h)
  self._entity:update_matrix()
end

function Jumper:on_keydown(evt)
  if self.h > 0.0 then return end
  if math.random() > JUMP_P then return end
  local keyname = ffi.string(evt.keycode)
  if keyname == self.k then
    self.v = (1.0 + math.random()*0.3) * JUMP_V
  end
end

local function rand_on_sphere(tgt)
  local ret = tgt or math.Vector()
  ret:set(1.0, 1.0, 1.0, 0.0)
  while ret:length() > 0.5 do
    ret:set(math.random()-0.5, math.random()-0.5, math.random()-0.5)
  end
  ret:normalize3()
  return ret
end

function create_scene(geo, mat, root)
  local thingy = entity.Entity3d()
  thingy:add_component(pipeline.MeshShaderComponent(geo, mat))
  root:add(thingy)

  local keys = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  for i = 1,1000 do
    local subthingy = entity.Entity3d()
    subthingy:add_component(pipeline.MeshShaderComponent(geo, mat))
    subthingy:add_component(sdl_input.SDLInputComponent())
    rand_on_sphere(subthingy.position)
    local k = string.sub(keys, ((i-1) % 26) + 1, ((i-1) % 26) + 1)
    subthingy:add_component(Jumper(k, subthingy.position, subthingy.position))
    subthingy.scale:set(0.2, 0.2, 0.2)
    subthingy:update_matrix()
    thingy:add(subthingy)
  end
end

width = 800
height = 600

function init()
  -- basic init
  sdl.create_window(width, height, 'keyboard events')
  gfx.init_gfx({msaa = true, debugtext = true, window = sdl})

  -- create material and geometry
  local geo = create_geo()
  local mat = {
    state = gfx.create_state(),
    uniforms = create_uniforms(),
    program = gfx.load_program("vs_basicpbr", "fs_basicpbr_faceted_x4")
  }

  -- create ecs
  ECS = ecs.ECS()
  ECS:add_system(sdl_input.SDLInputSystem())
  local p = ECS:add_system(pipeline.Pipeline({verbose = true}))
  p:add_stage(pipeline.Stage({
    name = "solid_geo",
    clear = {color = 0x303050ff, depth = 1.0},
  }, {pipeline.GenericRenderOp(), camera.CameraControlOp()}))
  p:add_stage(nvg.NanoVGStage({
    name = "nanovg_overlay",
    clear = {color = false, depth = false}
  }))

  ECS:add_system(framestats.DebugTextStats())

  ECS.scene:add_component(sdl_input.SDLInputComponent())
  ECS.scene:add_component(nvg.NanoVGDrawable(function(comp, stage, ctx)
    local font = ctx:load_font("font/VeraMono.ttf", "sans")
    comp.color = comp.color or ctx:RGB(255,255,0)
    comp.color2 = comp.color2 or ctx:RGBA(0,255,255,128)

    ctx:FillColor(comp.color)
    ctx:Ellipse(ctx.width/2, ctx.height/2, 50, 50)
    ctx:Fill()

    ctx:FillColor(comp.color2)
    ctx:FontFaceId(font)
    ctx:FontSize(32.0)
    ctx:Text(ctx.width/2, ctx.height/2, "Hello nvg!", nil)
  end))
  ECS.scene:on("keydown", function(entity, evt)
    local keyname = ffi.string(evt.keycode)
    if keyname == "F12" then
      print("Saving screenshot!")
      gfx.save_screenshot("screenshot.png")
    end
  end)

  local cam = camera.Camera({fov = 65, aspect = width/height})
  cam:add_component(sdl_input.SDLInputComponent())
  cam:add_component(orbitcam.OrbitControl({min_rad = 1.0, max_rad = 15.0}))
  ECS.scene:add(cam)

  -- create the scene
  create_scene(geo, mat, ECS.scene)
end

function update()
  -- update ecs
  ECS:update()
end
