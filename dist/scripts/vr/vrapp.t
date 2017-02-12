-- vr/vrapp.t
--
-- extension of AppScaffold to simplify vr

local class = require("class")
local math = require("math")
local gfx = require("gfx")
local sdl = require("addons/sdl.t")
local openvr = require("vr/openvr.t")

local ecs = require("ecs/ecs.t")
local component = require("ecs/component.t")
local entity = require("ecs/entity.t")
local sdl_input = require("ecs/sdl_input.t")

local pipeline = require("graphics/pipeline.t")
local framestats = require("graphics/framestats.t")
local camera = require("graphics/camera.t")

local m = {}

local VRApp = class("VRApp")

function VRApp:init(options)
  self.options = options or {}
  openvr.init()
  local vw, vh = 800, 1280
  if openvr.available then
    vw, vh = openvr.get_target_size()
  end

  self.vr_width = math.floor((options.vr_width or 1.0) * vw)
  self.vr_height = math.floor((options.vr_height or 1.0) * vh)
  log.info("VRApp init: w= " .. self.vr_width .. ", h= " .. self.vr_height)

  log.info("gfx init!")
  self:gfx_init()

  self.stereo_cams = {
    camera.Camera({tag="left"}),
    camera.Camera({tag="right"})
  }

  local testprojL = {{0.36, 0.00, -0.06, 0.00},
                     {0.00, 0.68, -0.00, 0.00},
                     {0.00, 0.00, -1.00, -0.05},
                     {0.00, 0.00, -1.00, 0.00}}
  local testprojR = {{0.36, 0.00, 0.06, 0.00},
                     {0.00, 0.68, -0.00, 0.00},
                     {0.00, 0.00, -1.00, -0.05},
                     {0.00, 0.00, -1.00, 0.00}}
  self.stereo_cams[1].camera.proj_mat:from_table(testprojL)
  self.stereo_cams[2].camera.proj_mat:from_table(testprojR)
  log.info("ProjL: " .. tostring(self.stereo_cams[1].camera.proj_mat))

  -- controller objects
  self.controllerObjects = {}
  self.maxControllers = 0

  -- used to draw screen space quads to composite things
  self.composite_proj = math.Matrix4():orthographic_projection(0, 1, 0, 1, -1, 1)
  self.identitymat = math.Matrix4():identity()
  self.quadgeo = gfx.TransientGeometry()
  log.info("got this far?")
  self.composite_sampler = gfx.TexUniform("s_srcTex", 0)
  log.info("got this far2?")
  self.composite_program = gfx.load_program("vs_fullscreen",
                                            "fs_fullscreen_copy")
  log.info("got this far3?")


  local hipd = 6.4 / 2.0 -- half ipd
  self.offsets = {
      math.Matrix4():translation(math.Vector(-hipd, 0.0, 0.0)),
      math.Matrix4():translation(math.Vector( hipd, 0.0, 0.0))
  }

  log.info("eh?")
  self:ecs_init()
end

function VRApp:gfx_init()
  log.info("gfx init")
  sdl.create_window(self.options.width or 1280,
                    self.options.height or 800,
                    self.options.title or 'title')
  local gfx_opts = {msaa = true,
                    debugtext = true,
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
  ECS:add_system(sdl_input.SDLInputSystem())
  ECS:add_system(framestats.DebugTextStats())

  ECS.scene:add_component(sdl_input.SDLInputComponent())
  ECS.scene:on("keydown", function(entity, evt)
    local keyname = ffi.string(evt.keycode)
    if keyname == "F12" then
      print("Saving screenshot!")
      gfx.save_screenshot("screenshot.png")
    end
  end)

  self:init_pipeline()

  ECS.scene:add(self.stereo_cams[1])
  ECS.scene:add(self.stereo_cams[2])
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

  local p = self.ECS:add_system(pipeline.Pipeline({verbose = true}))
  local left = p:add_stage(pipeline.Stage({
    name = "solid_geo_left",
    clear = {color = 0x303050ff, depth = 1.0},
    render_target = self.targets[1]
  }, {pipeline.GenericRenderOp(), camera.CameraControlOp("left")}))
  local right = p:add_stage(pipeline.Stage({
    name = "solid_geo_right",
    clear = {color = 0x303050ff, depth = 1.0},
    render_target = self.targets[2]
  }, {pipeline.GenericRenderOp(), camera.CameraControlOp("right")}))
  local composite = p:add_stage(pipeline.Stage({
    name = "composite",
    render_target = self.backbuffer
  }))

  self.composite_view = composite.view

  -- finalize pipeline
  self.pipeline = p
  self.pipeline:bind()
end

function VRApp:composite(rt, x0, y0, x1, y1)
  gfx.set_state() -- set default state
  gfx.set_transform(self.identitymat)
  self.quadgeo:quad(x0, y0, x1, y1, 0.0):bind()
  self.composite_sampler:set(rt.attachments[1]):bind()
  gfx.submit(self.composite_view, self.composite_program)
end

function VRApp:_update_cameras()
  local cams = self.stereo_cams
  if openvr.available then -- use openvr provided camera positions
    for i = 1,2 do
      cams[i].camera:set_projection(openvr.eye_projections[i])
      cams[i].matrix:copy(openvr.eye_poses[i])
    end
  else                     -- emulate a generic stereo rig
    -- TODO: fix this
  end
end

function VRApp:createPlaceholderControllerObject(controller)
    log.debug("Creating placeholder controller!")
    if self.controllerGeo == nil then
        self.controllerGeo = require("geometry/icosphere.t").icosphereGeo(0.1, 3, "controller_sphere")
    end
    if self.controllerMat == nil then
        self.controllerMat = require("shaders/pbr.t").PBRMaterial("solid"):roughness(0.8):tint(0.05,0.05,0.05):diffuse(0.005,0.005,0.005)
    end
    return gfx.Object3D(self.controllerGeo, self.controllerMat)
end

function VRApp:onControllerModelLoaded(data, target)
    log.debug("Controller model loaded!")
    target:setGeometry(data.model.geo)
    -- ignore texture for now
end

function VRApp:updateControllers_()
    self.maxControllers = openvr.maxControllers
    for i = 1,self.maxControllers do
        local controller = openvr.controllers[i]
        if controller and controller.connected then
            if self.controllerObjects[i] == nil then
                self.controllerObjects[i] = self:createPlaceholderControllerObject(controller)
                self.controllerObjects[i].controller = controller
                self.roomroot:add(self.controllerObjects[i])
                local targetself = self
                local targetobj = self.controllerObjects[i]
                openvr.loadModel(controller, function(loadresult)
                    targetself:onControllerModelLoaded(loadresult, targetobj)
                end)
                if self.onControllerConnected then
                    self:onControllerConnected(i, self.controllerObjects[i])
                end
            end
            self.controllerObjects[i].matrix:copy(controller.pose)
        end
    end
end

function VRApp:update()
  if openvr.available then
      openvr.begin_frame()
      self:_update_cameras()
      --self:updateControllers_()
      --self.controllers = openvr.controllers
  end

  self.composite_view:set_matrices(self.identitymat, self.composite_proj)
  self.composite_view:set_render_target(self.backbuffer)

  -- Note: here it looks like we're compositing before we render the eyes,
  -- but bgfx renders views in order so we can submit them out of order
  for i = 1,2 do
    local x0 = (i-1) * 0.5
    local x1 = x0 + 0.5
    self:composite(self.targets[i], x0, 0, x1, 1.0)
  end

  self.ECS:update() -- this does main rendering
  openvr.submit_frame(self.eye_texes)
end

m.VRApp = VRApp
return m
