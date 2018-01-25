-- vr/vroverlayVROverlayApp.t
--
-- a convenience class for creating vr overlays

local class = require("class")
local math = require("math")
local gfx = require("gfx")
local ecs = require("ecs")
local sdl = require("addons/sdl.t")
local sdl_input = require("input/sdl_input.t")
local graphics = require("graphics")
local openvr = require("vr/openvr.t")
local app = require("app/app.t")

local VROverlayApp = app.App:extend("VROverlayApp")

function VROverlayApp:init(options)
  VROverlayApp.super.init(self, options)
  -- default to 20 fps updates?
  self._overlay_update_decimate = options.decimate or 3
  self._overlay_frame = 0
  self:_create_overlay(options)
  -- The backing texture might not be created for some
  -- frames (due to multithreaded bgfx), so schedule 
  -- actually setting the overlay texture until later
  gfx.schedule(function()
    self.overlay:set_texture(self.targets.overlay)
  end)
end

function VROverlayApp:_create_overlay(options)
  openvr.init{mode = "overlay"}
  self.overlay = openvr.create_overlay{name = options.overlay_name or "truss_overlay"}
end

-- this creates a basic forward pbr pipeline that renders to a 
-- texture (because we need it to dump to the overlay)
function VROverlayApp:init_pipeline(options)
  local Vector = math.Vector
  local pbr = require("shaders/pbr.t")

  local overlay_target = gfx.ColorDepthTarget{width = self.width, 
                                              height = self.height}
  local backbuffer = gfx.BACKBUFFER
  self.targets = {overlay = overlay_target, backbuffer = backbuffer}

  local p = graphics.Pipeline({verbose = true})
  if options.use_tasks ~= false then
    p:add_stage(graphics.TaskRunnerStage{
                          num_workers = options.num_workers or 1})
  end
  p:add_stage(graphics.Stage{
    name = "forward",
    always_clear = true,
    clear = {color = self.clear_color or 0x00000000, depth = 1.0},
    globals = p.globals,
    render_target = overlay_target,
    render_ops = {graphics.GenericRenderOp(), graphics.CameraControlOp()}
  })
  p.globals:merge(pbr.create_pbr_globals())
  p.globals.u_lightDir:set_multiple({
      Vector( 1.0,  1.0,  0.0),
      Vector(-1.0,  1.0,  0.0),
      Vector( 0.0, -1.0,  1.0),
      Vector( 0.0, -1.0, -1.0)})
  p.globals.u_lightRgb:set_multiple({
      Vector(0.8, 0.8, 0.8),
      Vector(1.0, 1.0, 1.0),
      Vector(0.1, 0.1, 0.1),
      Vector(0.1, 0.1, 0.1)})
  if options.nvg_render or options.use_nvg then
    self.nvg_stage = p:add_stage(graphics.NanoVGStage{
      name = "nanovg",
      clear = false,
      render_target = overlay_target,
      setup = options.nvg_setup,
      render = options.nvg_render
    })
  end
  p:add_stage(graphics.CompositeStage{
    name = "composite",
    clear = {color = 0xff0000ff, depth = 1.0},
    render_target = backbuffer,
    composite_ops = {
      copy = {x0 = 0, y0 = 0, x1 = 1, y1 = 1, source = overlay_target}
    }
  })

  self.pipeline = p
  self.ECS.systems.render:set_pipeline(p)
end

function VROverlayApp:update()
  VROverlayApp.super.update(self)
  self._overlay_frame = self._overlay_frame + 1
  if self._overlay_frame % self._overlay_update_decimate == 0 then
    self.overlay:update_texture()
  end
end

local m = {}
m.VROverlayApp = VROverlayApp
return m
