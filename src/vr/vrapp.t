-- vr/vrapp.t
--
-- extension of AppScaffold to simplify vr

local class = require("class")
local math = require("math")
local gfx = require("gfx")
local sdl = require("addon/sdl.t")
local sdl_input = require("input/sdl_input.t")
local openvr = require("vr/openvr.t")
local vrcomps = require("vr/components.t")
local timing = require("osnative/timing.t")

local ecs = require("ecs")
local graphics = require("graphics")

local m = {}

local VRApp = class("VRApp")

function VRApp:init(options)
  self.evt = ecs.EventEmitter()

  local t0 = timing.tic()
  self.options = options or {}
  openvr.init{
    legacy_input = (options.legacy_input ~= false),
    new_input = options.new_input
  }
  log.info("up to openvr init: " .. tostring(timing.toc(t0) * 1000.0))

  local vw, vh = 800, 1280
  if openvr.available then
    vw, vh = openvr.get_target_size()
  end

  self.stats = options.stats

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
  log.info("up to bgfx init: " .. tostring(timing.toc(t0) * 1000.0))

  log.info("got this far3?")
  self:ecs_init()
  log.info("up to ecs init: " .. tostring(timing.toc(t0) * 1000.0))

  if options.new_input then
    self:register_actions(options)
  end

  self:init_scene()

  if options.create_controllers then
    self.controllers = {}
    self:create_default_controllers()
  end
end

function VRApp:on(...)
  self.evt:on(...)
end

function VRApp:register_actions(options)
  self.action_sets = openvr.input.register_action_sets(options.action_sets or {
    main = {
      primary = {
        kind = 'boolean', description = 'Primary Action'
      },
      secondary = {
        kind = 'boolean', description = 'Secondary Action'
      },
      mainhand = {
        kind = 'pose', description = 'Main Hand'
      },
      cursor = {
        kind = 'vector2', description = 'Emulated Mouse Cursor'
      }
    }
  })
  openvr.input.change_active_sets({options.active_action_set or 'main'})
end

function VRApp:gfx_init()
  log.info("gfx init")
  sdl.create_window(self.window_width or 1280,
                    self.window_height or 800,
                    self.options.title or 'title')
  local gfx_opts = {msaa = true,
                    debugtext = self.stats,
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
  self.scene = ECS.scene
  ECS:add_system(sdl_input.SDLInputSystem())
  ECS:add_system(ecs.System("update", "update"))
  if self.async ~= false then
    ECS:add_system(require("async").AsyncSystem())
  end
  ECS:add_system(graphics.RenderSystem())
  if self.stats then ECS:add_system(graphics.DebugTextStats()) end
  self:init_pipeline()
end

function VRApp:setup_targets()
  local w, h = self.vr_width, self.vr_height
  self.targets = {gfx.ColorDepthTarget{width = w, height = h},
                  gfx.ColorDepthTarget{width = w, height = h}}
  self.backbuffer = gfx.BACKBUFFER
  self.eye_texes = {self.targets[1]:get_attachment_handle(1),
                    self.targets[2]:get_attachment_handle(1)}
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

  local clear = {color = self.options.clear_color or 0x303050ff, depth = 1.0}
  local p = graphics.Pipeline{verbose = true}
  if self.options.use_tasks ~= false then
    p:add_stage(graphics.TaskRunnerStage{
      num_workers = self.options.num_workers or 1
    })
  end
  p:add_stage(graphics.MultiviewStage{
    name = "stereo_forward",
    globals = p.globals,
    render_ops = {graphics.MultiDrawOp(), graphics.MultiCameraOp()},
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

  local Vector = math.Vector
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

  -- set pipeline
  self.pipeline = p
  self.ECS.systems.render:set_pipeline(p)
end

function VRApp:init_scene()
  self.vr_root = self.scene:create_child(vrcomps.RoomRoot, "vr_root")
  self.hmd = self.vr_root:find("hmd")
end

function VRApp:create_default_controllers()
  openvr.on("trackable_connected", function(trackable)
    self:add_controller_model(trackable)
  end)
end

function VRApp:add_controller_model(trackable)
  if trackable.device_class_name ~= "Controller" then
    return
  end

  local geometry = require("geometry")
  local pbr = require("material/pbr.t")
  local geo = geometry.icosphere_geo{radius = 0.1, detail = 3}
  local mat = pbr.FacetedPBRMaterial{
    diffuse = {0.03,0.03,0.03,1.0},
    tint = {0.001, 0.001, 0.001}, 
    roughness = 0.7
  }
  
  local controller = self.vr_root:create_child(ecs.Entity3d, 
                                               "controller")
  controller:add_component(vrcomps.ControllerComponent(trackable))
  controller.controller:create_mesh_parts(geo, mat)
  table.insert(self.controllers, controller)

  self.evt:emit("controller_connected", {
    controller = controller,
    idx = #self.controllers
  })
end

function VRApp:update()
  openvr.begin_frame()
  self.ECS:update() -- this does main rendering
  openvr.submit_frame(self.eye_texes)
end

m.VRApp = VRApp
return m
