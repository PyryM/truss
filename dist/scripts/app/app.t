-- App.t
--
-- a convenience class for handling a lot of boilerplate

local class = require('class')
local sdl = require("addons/sdl.t")

local math = require("math")
local gfx = require("gfx")
local ecs = require("ecs")
local sdl_input = require("ecs/sdl_input.t")
local graphics = require("graphics")

local App = class('App')

function App:init(options)
  log.debug("App: init")
  options = options or {}
  sdl.create_window(options.width or 1280, options.height or 720,
                    options.title or 'truss',
                    options.fullscreen and 1)
  self.width, self.height = sdl.get_window_size()
  gfx.init_gfx({msaa = options.msaa,
                debugtext = options.stats,
                vsync = options.vsync,
                renderer = options.backend,
                window = sdl})
  log.debug("App: window+gfx initialized")
  self.clear_color = options.clear_color or 0x303030ff
  if options.error_console ~= false then
    self:install_console()
  end

  self.frame = 0
  self.time = 0.0

  self:init_ecs()
  self:init_pipeline()
end

function App:install_console()
  -- TODO
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
end

function App:init_pipeline()
  local p = graphics.Pipeline({verbose = true})
  p:add_stage(graphics.Stage{
    name = "forward",
    clear = {color = 0x303050ff, depth = 1.0},
    globals = p.globals,
    render_ops = {graphics.GenericRenderOp(), graphics.CameraControlOp()}
  })
  self.pipeline = p
  self.ecs.systems.render:set_pipeline(p)
end

function App:set_default_lights()
  -- set default lights
  local Vector = math.Vector
  self.pipeline.globals.u_lightDir:set_multiple({
          Vector( 1.0,  1.0,  0.0),
          Vector(-1.0,  1.0,  0.0),
          Vector( 0.0, -1.0,  1.0),
          Vector( 0.0, -1.0, -1.0)})

  self.pipeline.globals.u_lightRgb:set_multiple({
          Vector(0.8, 0.8, 0.8),
          Vector(1.0, 1.0, 1.0),
          Vector(0.1, 0.1, 0.1),
          Vector(0.1, 0.1, 0.1)})
end

function App:initScene()
  self.scene = gfx.Object3D()
  self.camera = gfx.Camera():makeProjection(70, self.width/self.height,
                                          0.1, 100.0)
end

function App:onKeyDown_(keyname, modifiers)
  log.info("Keydown: " .. keyname .. " | " .. modifiers)
  if self.keybindings[keyname] ~= nil then
    self.keybindings[keyname](keyname, modifiers)
  end
end

function App:setKeyBinding(keyname, func)
  self.keybindings[keyname] = func
end

function App:onKey(keyname, func)
  self:setKeyBinding(keyname, func)
end

function App:onMouseMove(func)
  self.mousemove = func
end

function App:takeScreenshot(filename)
  bgfx.bgfx_save_screen_shot(filename)
end

function App:updateEvents()
  for evt in sdl:events() do
      if evt.event_type == sdl.EVENT_KEYDOWN or evt.event_type == sdl.EVENT_KEYUP then
          local keyname = ffi.string(evt.keycode)
          if evt.event_type == sdl.EVENT_KEYDOWN then
              if not self.downkeys[keyname] then
                  self.downkeys[keyname] = true
                  self:onKeyDown_(keyname, evt.flags)
              end
          else -- keyup
              self.downkeys[keyname] = false
          end
      elseif evt.event_type == sdl.EVENT_WINDOW and evt.flags == 14 then
          log.info("Received window close, quitting...")
          truss.quit()
      end
      if self.userEventHandler then
          self:userEventHandler(evt)
      end
  end
end

function App:updateScene()
  self.scene:updateMatrices()
end

function App:render()
  self.pipeline:render({camera = self.camera,
                        scene  = self.scene})
end

function App:drawDebugText()
  if not self.debugtext then return end
  -- Use debug font to print information about this example.
  bgfx.bgfx_dbg_text_clear(0, false)
  bgfx.bgfx_dbg_text_printf(0, 1, 0x6f, "total: " .. self.frametime*1000.0
                                                  .. " ms, script: "
                                                  .. self.scripttime*1000.0
                                                  .. " ms")
end

function App:update()
  self.frame = self.frame + 1
  self.time = self.time + 1.0 / 60.0

  -- Deal with input events
  self:updateEvents()

  -- Set view 0,1 default viewport.
  bgfx.bgfx_set_view_rect(0, 0, 0, self.width, self.height)
  bgfx.bgfx_set_view_rect(1, 0, 0, self.width, self.height)

  -- Touch the view to make sure it is cleared even if no draw
  -- calls happen
  -- bgfx.bgfx_touch(0)
  self:drawDebugText()

  if self.preRender then
      self:preRender()
  end

  self:updateScene()
  self:render()
  self.scripttime = truss.toc(self.startTime)

  -- Advance to next frame. Rendering thread will be kicked to
  -- process submitted rendering primitives.
  bgfx.bgfx_frame(false)

  self.frametime = truss.toc(self.startTime)
  self.startTime = truss.tic()
end

local m = {}
m.App = App
return m
