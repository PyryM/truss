-- App.t
--
-- a convenience class for handling a lot of boilerplate

local class = require('class')
local math = require("math")
local gfx = require("gfx")
local ecs = require("ecs")
local sdl = require("addons/sdl.t")
local sdl_input = require("input/sdl_input.t")
local graphics = require("graphics")

local App = class('App')

function App:init(options)
  log.debug("App: init")
  options = options or {}
  sdl.create_window(options.width or 1280, options.height or 720,
                    options.title or 'truss',
                    options.fullscreen and 1)
  self.width, self.height = sdl.get_window_size()
  self.stats = options.stats
  options.debugtext = options.stats
  options.window = sdl
  gfx.init_gfx(options)
  log.debug("App: window+gfx initialized")
  self.clear_color = options.clear_color or 0x000000ff
  if options.error_console ~= false then
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
  local options = self._init_options
  for k,v in pairs(newoptions) do
    options[k] = v
  end
  sdl.resize_window(options.width or 1280, options.height or 720,
                    options.fullscreen and 1)
  self.width, self.height = sdl.get_window_size()
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
  require("devtools/miniconsole.t").install()
end

function App:init_ecs()
  -- create ecs
  local ECS = ecs.ECS()
  self.ECS = ECS
  ECS:add_system(sdl_input.SDLInputSystem())
  ECS:add_system(ecs.System("preupdate", "preupdate"))
  ECS:add_system(ecs.ScenegraphSystem())
  ECS:add_system(ecs.System("update", "update"))
  ECS:add_system(graphics.RenderSystem())
  if self.stats then ECS:add_system(graphics.DebugTextStats()) end
  ECS.systems.input:on("keydown", self, self.keydown)
end

-- this creates a basic forward pbr pipeline; if you want something fancier,
-- feel free to override this
function App:init_pipeline(options)
  local Vector = math.Vector
  local pbr = require("shaders/pbr.t")
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
      setup = options.nvg_setup,
      render = options.nvg_render
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

function App:keydown(evtname, evt)
  local keyname, modifiers = evt.keyname, evt.modifiers
  if keyname == "F12" then
    print("Saving screenshot!")
    gfx.save_screenshot("screenshot.png")
  end
end

function App:capture_mouse(capture)
  sdl.set_relative_mouse_mode(capture)
end

function App:update()
  self.ECS:update()
end

local m = {}
m.App = App
return m
