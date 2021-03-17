-- immediateapp.t
--
-- a convenience class for immediate-mode only rendering

local class = require('class')
local math = require("math")
local gfx = require("gfx")
local ecs = require("ecs")
local graphics = require("graphics")
local imrender = require("graphics/imrender.t")

local ImmediateApp = class('ImmediateApp')

function ImmediateApp:init(options)
  log.debug("ImmediateApp: init")
  options = options or {}
  self.headless = options.headless
  if not self.headless then
    local sdl = require("addon/sdl.t")
    sdl.create_window(options.width or 1280, options.height or 720,
                      options.title or 'truss',
                      options.fullscreen and 1,
                      options.display or 0)
    self.width, self.height = sdl.get_window_size()
    self.stats = options.stats
    options.debugtext = options.stats
    options.window = sdl
  end
  gfx.init_gfx(options)
  log.debug("ImmediateApp: window+gfx initialized")
  if (not self.headless) and options.error_console ~= false then
    self:install_console()
  end
  self._init_options = options

  self:init_ecs()
  self:init_pipeline(options)
end

function ImmediateApp:install_console()
  require("dev/miniconsole.t").install()
end

function ImmediateApp:init_ecs()
  -- create ecs
  local ECS = ecs.ECS()
  self.ECS = ECS
  if not self.headless then
    ECS:add_system(require("input/sdl_input.t").SDLInputSystem())
    ECS.systems.input:on("keydown", self, self.keydown)
  end
  ECS:add_system(ecs.System("update", "update"))
  if self.async ~= false then
    ECS:add_system(require("async").AsyncSystem())
  end
  ECS:add_system(graphics.RenderSystem())
  if self.stats then ECS:add_system(graphics.DebugTextStats()) end
end

-- this creates a pipeline with nothing but an immediate state
function ImmediateApp:init_pipeline(options)
  local p = graphics.Pipeline({verbose = true})
  self.imstage = p:add_stage(imrender.ImmediateStage{
    num_views = options.num_views or 32,
    func = options.immediate_func
  })
  self.pipeline = p
  self.ECS.systems.render:set_pipeline(p)
end

function ImmediateApp:keydown(evtname, evt)
  local keyname, modifiers = evt.keyname, evt.modifiers
  if keyname == "F12" then
    print("Saving screenshot!")
    gfx.save_screenshot("screenshot.png")
  end
end

function ImmediateApp:update()
  self.ECS:update()
end

local m = {}
m.ImmediateApp = ImmediateApp
return m
