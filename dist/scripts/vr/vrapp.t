-- vr/vrapp.t
--
-- extension of AppScaffold to simplify vr

local class = require("class")
local math = require("math")
local gfx = require("gfx")
local sdl = require("addons/sdl.t")
local openvr = require("vr/openvr.t")
local vrcomps = require("vr/components.t")

local ecs = require("ecs")
local graphics = require("graphics")

local m = {}

local VRApp = class("VRApp")

function VRApp:init(options)
  self.options = options or {}
  openvr.init()
  local vw, vh = 800, 1280
  if openvr.available then
    vw, vh = openvr.get_target_size()
  end

  if self.options.width and self.options.width < 1.0 then
    self.window_width = self.options.width * vw
    self.window_height = self.options.width * vh
  else
    self.window_width = self.options.width or (vw / 2)
    self.window_height = self.options.height or (vh / 2)
  end

  if self.options.mirror == "both" then
    self.window_width = self.window_width * 2
  end

  self.vr_width = math.floor((options.vr_width or 1.0) * vw)
  self.vr_height = math.floor((options.vr_height or 1.0) * vh)
  log.info("VRApp init: w= " .. self.vr_width .. ", h= " .. self.vr_height)

  log.info("gfx init!")
  self:gfx_init()

  log.info("got this far3?")
  self:ecs_init()
end

function VRApp:gfx_init()
  log.info("gfx init")
  sdl.create_window(self.window_width or 1280,
                    self.window_height or 800,
                    self.options.title or 'title')
  local gfx_opts = {msaa = true,
                    debugtext = self.options.debugtext,
                    window = sdl,
                    lowlatency = true}
  gfx_opts.vsync = (not openvr.available) -- enable vsync if no openvr
  gfx.init_gfx(gfx_opts)
  log.info("gfx init done")
end

function VRApp:ecs_init()
  -- create ecs
  local ECS = ecs.ECS()
  self.ECS = ECS
  --ECS:add_system(vrcomps.VRBeginFrameSystem())
  ECS:add_system(sdl_input.SDLInputSystem())
  ECS:add_system(ecs.System("preupdate", "preupdate"))
  ECS:add_system(ecs.ScenegraphSystem())
  ECS:add_system(ecs.System("update", "update"))
  ECS:add_system(graphics.RenderSystem())
  if self.stats then ECS:add_system(graphics.DebugTextStats()) end
  --ECS:add_system(vrcomps.VRSubmitSystem())
  ECS.systems.input:on("keydown", self, self.keydown)

  self:init_pipeline()
  self:init_scene()
end

function VRApp:setup_targets()
  local w,h = self.vr_width, self.vr_height
  self.targets = {gfx.RenderTarget(w,h):make_RGB8(true),
                  gfx.RenderTarget(w,h):make_RGB8(true)}
  self.backbuffer = gfx.RenderTarget(self.width, self.height):make_backbuffer()
  self.eye_texes = {self.targets[1].attachments[1],
                   self.targets[2].attachments[1]}
end

function VRApp:init_pipeline()
  self:setup_targets()

  local composite_ops
  if self.options.mirror == "left" then
    composite_ops = {left = {source = self.targets[1], 
                             x0 = 0.0, y0 = 0.0,
                             x1 = 1.0, y1 = 1.0}}
  elseif self.options.mirror == "right" then
    composite_ops = {right = {source = self.targets[2], 
                              x0 = 0.0, y0 = 0.0, 
                              x1 = 1.0, y1 = 1.0}}
  else -- mirror both
    composite_ops = {left =  {source = self.targets[1], 
                              x0 = 0.0, y0 = 0.0, 
                              x1 = 0.5, y1 = 1.0},
                     right = {source = self.targets[2], 
                              x0 = 0.5, y0 = 0.0, 
                              x1 = 1.0, y1 = 1.0}}
  end

  local clear = {color = 0x303050ff, depth = 1.0}
  local p = graphics.Pipeline({verbose = true}))
  p:add_stage(graphics.MultiViewStage{
    name = "stereo_forward",
    globals = p.globals,
    render_ops = {graphics.GenericRenderOp(), vrcomps.VRCameraControl()},
    views = {
      {name = "left",  clear = clear, render_target = self.targets[1]},
      {name = "right", clear = clear, render_target = self.targets[2]}
    }
  })
  p:add_stage(graphics.CompositeStage{
    name = "composite",
    clear = {color = 0xff0000ff, depth = 1.0},
    render_target = self.backbuffer,
    composite_ops = composite_ops
  })

  -- set pipeline
  self.pipeline = p
  self.ECS.systems.render:set_pipeline(p)
end

function VRApp:init_scene()
  self.hmd_cam = ECS.scene:create_child(vrcomps.VRCamera, "hmd_camera")
end

function VRApp:update()
  openvr.begin_frame()
  self.ECS:update() -- this does main rendering
  openvr.submit_frame(self.eye_texes)
end

m.VRApp = VRApp
return m
