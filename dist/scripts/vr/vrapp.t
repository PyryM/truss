-- vr/vrapp.t
--
-- extension of AppScaffold to simplify vr

local class = require("class")
local math = require("math")
local gfx = require("gfx")
local appscaffold = require("utils/appscaffold.t")
local shaderutils = require("utils/shaderutils.t")
local openvr = require("vr/openvr.t")

local m = {}

local VRApp = appscaffold.AppScaffold:extend("VRApp")

function VRApp:init(options)
    openvr.init()
    local vw, vh = 800, 1280
    if openvr.available then
        vw, vh = openvr.getRecommendedTargetSize()
    end
    self.extraFlags = true
    self.vrWidth = math.floor((options.vrWidth or 1.0) * vw)
    self.vrHeight = math.floor((options.vrHeight or 1.0) * vh)
    log.info("VRApp insdfdit: w= " .. self.vrWidth .. ", h= " .. self.vrHeight)

    VRApp.super.init(self, options)
    self.stereoCameras = {
        gfx.Camera():makeProjection(70, self.vrWidth/self.vrHeight, 0.1, 100.0),
        gfx.Camera():makeProjection(70, self.vrWidth/self.vrHeight, 0.1, 100.0)
    }
    self.roomroot = gfx.Object3D()
    self.roomroot:add(self.stereoCameras[1])
    self.roomroot:add(self.stereoCameras[2])
    self.scene:add(self.roomroot)

    local testprojL = {{0.76, 0.00, -0.06, 0.00},
                       {0.00, 0.68, -0.00, 0.00},
                       {0.00, 0.00, -1.00, -0.05},
                       {0.00, 0.00, -1.00, 0.00}}
    local testprojR = {{0.76, 0.00, 0.06, 0.00},
                       {0.00, 0.68, -0.00, 0.00},
                       {0.00, 0.00, -1.00, -0.05},
                       {0.00, 0.00, -1.00, 0.00}}
    self.stereoCameras[1].projMat:fromPrettyArray(testprojL)
    self.stereoCameras[2].projMat:fromPrettyArray(testprojR)
    log.info("ProjL: " .. tostring(self.stereoCameras[1].projMat))

    -- controller objects
    self.controllerObjects = {}

    -- used to draw screen space quads to composite things
    self.orthocam = gfx.Camera():makeOrthographic(0, 1, 0, 1, -1, 1)
    self.identitymat = math.Matrix4():identity()
    self.quadgeo = gfx.TransientGeometry()
    self.compositeSampler = gfx.TexUniform("s_srcTex", 0)
    self.compositePgm = shaderutils.loadProgram("vs_fullscreen",
                                                "fs_fullscreen_copy")

    local hipd = 6.4 / 2.0 -- half ipd
    self.offsets = {
        math.Matrix4():makeTranslation(math.Vector(-hipd, 0.0, 0.0)),
        math.Matrix4():makeTranslation(math.Vector( hipd, 0.0, 0.0))
    }
end

function VRApp:initBGFX()
    -- Basic init
    -- no anti-aliasing or vsync in VR
    local reset = 0
    if self.extraFlags then
        reset = bgfx_const.BGFX_RESET_FLIP_AFTER_RENDER +
                  bgfx_const.BGFX_RESET_FLUSH_AFTER_RENDER
    end
    --local cbInterfacePtr = sdl.truss_sdl_get_bgfx_cb(sdlPointer)
    local cbInterfacePtr = nil
    bgfx.bgfx_init(bgfx.BGFX_RENDERER_TYPE_COUNT, 0, 0, cbInterfacePtr, nil)
    bgfx.bgfx_reset(self.width, self.height, reset)

    local debug = 0 -- debug text doesn't play nice with views other than 0
    bgfx.bgfx_set_debug(debug)

    log.info("VRApp: initted bgfx")
    local rendererType = bgfx.bgfx_get_renderer_type()
    local rendererName = ffi.string(bgfx.bgfx_get_renderer_name(rendererType))
    log.info("Renderer type: " .. rendererName)
end

function VRApp:setupTargets()
    local w,h = self.vrWidth, self.vrHeight
    self.targets = {gfx.RenderTarget(w,h):makeRGB8(true),
                    gfx.RenderTarget(w,h):makeRGB8(true)}
    self.backbuffer = gfx.RenderTarget(self.width, self.height):makeBackbuffer()
    self.eyeTexes = {self.targets[1].attachments[1],
                     self.targets[2].attachments[1]}
    self.eyeContexts = {{}, {}}
end

function VRApp:initPipeline()
    self:setupTargets()
    self.pipeline = gfx.Pipeline()

    -- set up individual eye passes by creating one forward pass and then
    -- duplicating it twice
    local pbr = require("shaders/pbr.t")
    local forwardpass = gfx.MultiShaderStage({
        renderTarget = nil,
        clear = {color = 0x303030ff},
        shaders = {solid = pbr.PBRShader()}
    })
    self.forwardpass = forwardpass

    for i = 1,2 do
        local eyePass = forwardpass:duplicate(self.targets[i])
        self.pipeline:add("forward_" .. i, eyePass, self.eyeContexts[i])
    end

    -- finalize pipeline
    self.pipeline:setupViews(0)
    self.windowView = self.pipeline.nextAvailableView
    self.backbuffer:setViewClear(self.windowView, {color = 0x303030ff,
                                                   depth = 1.0})

    self:setDefaultLights()
end

function VRApp:setDefaultLights()
    -- set default lights
    local Vector = math.Vector
    local forwardpass = self.forwardpass
    forwardpass.globals.lightDirs:setMultiple({
            Vector( 1.0,  1.0,  0.0),
            Vector(-1.0,  1.0,  0.0),
            Vector( 0.0, -1.0,  1.0),
            Vector( 0.0, -1.0, -1.0)})

    forwardpass.globals.lightColors:setMultiple({
            Vector(0.8, 0.8, 0.8),
            Vector(1.0, 1.0, 1.0),
            Vector(0.1, 0.1, 0.1),
            Vector(0.1, 0.1, 0.1)})
end

function VRApp:composite(rt, x0, y0, x1, y1)
    bgfx.bgfx_set_state(bgfx_const.BGFX_STATE_DEFAULT, 0)
    bgfx.bgfx_set_transform(self.identitymat.data, 1)
    self.quadgeo:quad(x0, y0, x1, y1, 0.0):bind()
    self.compositeSampler:set(rt.attachments[1]):bind()
    bgfx.bgfx_submit(self.windowView, self.compositePgm, 0, false)
end

function VRApp:updateCameras_()
    local cams = self.stereoCameras
    if openvr.available then
        --self.camera.matrix:copy(openvr.hmd.pose)
        for i = 1,2 do
            cams[i].projMat:copy(openvr.eyeProjections[i])
            cams[i].matrix:copy(openvr.eyePoses[i])
        end
    else
        local offsets = self.offsets
        for i = 1,2 do
            cams[i].matrix:multiply(self.camera.matrix, offsets[i])
        end
    end
end

function VRApp:render()
    self.orthocam:setViewMatrices(self.windowView)
    self.backbuffer:bindToView(self.windowView)
    -- Note: here it looks like we're compositing before we render the eyes,
    -- but bgfx renders views in order so we can submit them out of order
    for i = 1,2 do
        self.eyeContexts[i].scene = self.scene
        self.eyeContexts[i].camera = self.stereoCameras[i]
        local x0 = (i-1) * 0.5
        local x1 = x0 + 0.5
        self:composite(self.targets[i], x0, 0, x1, 1.0)
    end
    self.pipeline:render({scene = self.scene})
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
    for i = 1,2 do
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
    self.frame = self.frame + 1
    self.time = self.time + 1.0 / 60.0

    if openvr.available then
        openvr.beginFrame()
        self:updateCameras_()
        self:updateControllers_()
        self.controllers = openvr.controllers
    end

    -- Deal with input events
    self:updateEvents()

    -- Set the window view to take up the entire target
    --bgfx.bgfx_set_view_rect(self.windowView, 0, 0, self.width, self.height)

    if self.preRender then
        self:preRender()
    end

    self:updateScene()
    self:render()
    self.scripttime = toc(self.startTime)

    -- Have bgfx do its rendering
    bgfx.bgfx_frame(false)

    -- Submit eyes
    openvr.submitFrame(self.eyeTexes)

    self.frametime = toc(self.startTime)

    if self.frame % 60 == 0 then
        log.info("ft: " .. self.frametime)
    end

    self.startTime = tic()
end

m.VRApp = VRApp
return m
