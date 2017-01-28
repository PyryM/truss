local class = require("class")
local gfx = require("gfx")
local ecs = require("ecs/ecs.t")
local component = require("ecs/component.t")
local entity = require("ecs/entity.t")
local sdl_input = require("ecs/sdl_input.t")
local sdl = require("addons/sdl.t")
local math = require("math")

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

  uniforms.u_baseColor:set(math.Vector(0.2,0.2,0.1,1.0))
  uniforms.u_pbrParams:set(math.Vector(1.0, 1.0, 1.0, 0.6))
  return uniforms
end

function create_geo()
  return require("geometry/icosphere.t").icosphere_geo(1.0, 3, "ico")
end

local GfxComponent = component.Component:extend("GfxComponent")
function GfxComponent:init(geo, mat)
  self._mat = mat
  self._geo = geo
end

function GfxComponent:draw()
  if not self._geo or not self._mat then return end
  gfx.set_transform(self._entity.matrix_world)
  self._geo:bind()
  if self._mat.state then gfx.set_state(self._mat.state) end
  if self._mat.uniforms then self._mat.uniforms:bind() end
  gfx.submit(self._mat.view or 0, self._mat.program)
end

function GfxComponent:on_update()
  self:draw()
end

local Rotator = component.Component:extend("Rotator")
function Rotator:on_update()
  self.t = (self.t or 0.0) + (1.0 / 60.0)
  self._entity.quaternion:euler({x = 0.0, y = self.t*0.2, z = 0.0})
  self._entity:update_matrix()
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
function Jumper:on_update()
  local dt = 1.0 / 60.0
  self.v = self.v + ACC * dt
  self.h = self.h + self.v * dt
  if self.h < 0.0 then self.h = 0.0 end
  -- position = p0 + d*h
  self._entity.position:lincomb(self.p0, self.d, 1.0, self.h)
  self._entity:update_matrix()
end

function Jumper:on_keydown(evt)
  if self.h > 0.0 then return end
  local keyname = ffi.string(evt.keycode)
  if keyname == self.k then
    self.v = JUMP_V
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
  thingy:add_component(GfxComponent(geo, mat))
  thingy:add_component(Rotator())
  thingy.position:set(0.0, 0.0, -4.0)
  root:add(thingy)

  local keys = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  for i = 1,26 do
    local subthingy = entity.Entity3d()
    subthingy:add_component(GfxComponent(geo, mat))
    subthingy:add_component(sdl_input.SDLInputComponent())
    rand_on_sphere(subthingy.position)
    local k = string.sub(keys, i, i)
    subthingy:add_component(Jumper(k, subthingy.position, subthingy.position))
    subthingy.scale:set(0.3, 0.3, 0.3)
    subthingy:update_matrix()
    thingy:add(subthingy)
  end
end

width = 800
height = 600
time = 0.0
frametime = 0.0

function init()
  -- basic init
  sdl.create_window(width, height, 'keyboard events')
  gfx.init_gfx({msaa = true, debugtext = true, window = sdl})

  -- set up our one view (rendering directly to backbuffer)
  view = gfx.View(0)
  view:set_clear({color = 0x303030ff, depth = 1.0})
  view:set_viewport(false)

  -- create material and geometry
  local geo = create_geo()
  local mat = {
    state = gfx.create_state(),
    uniforms = create_uniforms(),
    program = gfx.load_program("vs_basicpbr", "fs_basicpbr_faceted_x4")
  }

  -- create matrices
  projmat = math.Matrix4():perspective_projection(70, width/height, 0.1, 100.0)
  viewmat = math.Matrix4():identity()

  -- create ecs
  ECS = ecs.ECS()
  ECS:add_system(sdl_input.SDLInputSystem())

  ECS.scene:add_component(sdl_input.SDLInputComponent())
  ECS.scene:on("keydown", function(entity, evt)
    local keyname = ffi.string(evt.keycode)
    if keyname == "F12" then
      print("Saving screenshot!")
      gfx.save_screenshot("screenshot.png")
    end
  end)

  -- create the scene
  create_scene(geo, mat, ECS.scene)
end

function update()
  time = time + 1.0 / 60.0
  local start_time = truss.tic()

  -- Use debug font to print information about this example.
  bgfx.dbg_text_clear(0, false)

  bgfx.dbg_text_printf(0, 1, 0x4f, "scripts/examples/new_keyboard.t")
  bgfx.dbg_text_printf(0, 2, 0x6f, "frame time: " .. frametime*1000.0 .. " ms")

  -- Set viewprojection matrix
  view:set_matrices(viewmat, projmat)

  -- update ecs
  ECS:update()

  -- Advance to next frame.
  --bgfx.touch(0)
  gfx.frame()

  frametime = truss.toc(start_time)
end
