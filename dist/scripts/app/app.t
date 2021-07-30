-- App.t
--
-- a convenience class for handling a lot of boilerplate

local class = require('class')
local math = require("math")
local gfx = require("gfx")
local ecs = require("ecs")
local graphics = require("graphics")

local App = class('App')

function App:init(options)
  log.debug("App: init")
  options = options or {}
  self.headless = not not options.headless
  if not self.headless then
    self.window = require("input/windowing.t").create()
    self.window:create_window(
      options.width or 1280, 
      options.height or 720,
      options.title or 'truss',
      not not options.fullscreen,
      options.display or 0
    )
    local bounds = self.window:get_window_bounds(false)
    self.width, self.height = bounds.w, bounds.h
    self.stats = options.stats
    options.window = self.window
  else
    self.width, self.height = options.width or 256, options.height or 256
    self.stats = false
  end
  options.debugtext = self.stats
  gfx.init_gfx(options)
  log.debug("App: window+gfx initialized")
  self.clear_color = options.clear_color or 0x000000ff
  if (not self.headless) and options.error_console ~= false then
    self:install_console()
  end
  self._init_options = options

  self:init_ecs()
  self:init_pipeline(options)
  self:init_scene()
end

-- Note! This doesn't automatically resize rendertargets you've made!
-- (maybe it should?)
-- You will need to update the pipeline yourself.
function App:reset_graphics(newoptions)
  if self.headless then error("Reset NYI for headless mode!") end
  local options = self._init_options
  for k,v in pairs(newoptions) do
    options[k] = v
  end
  self.window:resize_window(options.width or 1280, options.height or 720,
                            options.fullscreen and 1)
  local bounds = self.window:get_window_bounds(false)
  self.width, self.height = bounds.w, bounds.h
  gfx.reset_gfx(options)
  if self.camera then
    self.camera.camera:make_projection(65, self.width / self.height, 
                                       0.01, 30.0)
  end
  if self.pipeline then
    self.pipeline:bind()
  end
end

function App:install_console()
  require("dev/miniconsole.t").install()
end

function App:init_ecs()
  -- create ecs
  local ECS = ecs.ECS()
  self.ECS = ECS
  if not self.headless then
    local sdl_input = require("input/sdl_input.t")
    ECS:add_system(sdl_input.SDLInputSystem{window=self.window})
    ECS.systems.input:on("keydown", self, self.keydown)
  end
  ECS:add_system(ecs.System("update", "update"))
  if self.async ~= false then
    ECS:add_system(require("async").AsyncSystem())
  end
  ECS:add_system(graphics.RenderSystem())
  if self.stats then ECS:add_system(graphics.DebugTextStats()) end
end

-- this creates a basic forward pbr pipeline; if you want something fancier,
-- feel free to override this
function App:init_pipeline(options)
  if self.headless then
    self.forward_target = gfx.ColorDepthTarget{width = self.width, height = self.height}
  else
    self.forward_target = gfx.BACKBUFFER
  end

  local Vector = math.Vector
  -- just requiring this should cause appropriate global uniforms
  -- to be registered
  local pbr = require("material/pbr.t")
  local p = graphics.Pipeline({verbose = true})
  if options.use_tasks ~= false then
    p:add_stage(graphics.TaskRunnerStage{
                          num_workers = options.num_workers or 1})
  end
  p:add_stage(graphics.Stage{
    name = "forward",
    always_clear = true,
    clear = {color = self.clear_color or 0x000000ff, depth = 1.0},
    globals = p.globals,
    render_ops = {graphics.DrawOp(), graphics.CameraControlOp()},
    render_target = self.forward_target,
  })
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
  if options.nvg_draw or (options.use_nvg ~= false) then
    self.nvg_stage = p:add_stage(graphics.NanoVGStage{
      name = "nanovg",
      clear = false,
      setup = options.nvg_setup,
      draw = options.nvg_draw,
      render_target = self.forward_target,
    })
  end

  self.pipeline = p
  self.ECS.systems.render:set_pipeline(p)
end

-- this just makes a default camera;
-- feel free to override
function App:init_scene()
  self.camera = self.ECS.scene:create_child(graphics.Camera, "camera",
                                            {fov = 65,
                                             aspect = self.width / self.height})
  self.scene = self.ECS.scene
end

function App:save_headless_screenshot(fn)
  assert(fn)
  if not self.async then 
    truss.error("save_headless_screenshot requires async") 
  end
  local async = require("async")
  local imwrite = require("io/imagewrite.t")
  if not self.forward_readback then
    self.forward_readback = gfx.ReadbackTexture(self.forward_target)
  end
  async.await(self.forward_readback:async_read_rt())
  imwrite.write_tga(self.width, self.height, self.forward_readback.cdata, fn)
  print("Saved headless screenshot: " .. fn)
end

function App:keydown(evtname, evt)
  local keyname, modifiers = evt.keyname, evt.modifiers
  if keyname == "F12" then
    print("Saving screenshot!")
    gfx.save_screenshot("screenshot.png")
  end
end

function App:capture_mouse(capture)
  self.window:set_fps_mouse_mode(capture)
end

function App:update()
  self.ECS:update()
end

local m = {}
m.App = App
return m
