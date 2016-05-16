-- vr/vrapp.t
--
-- extension of AppScaffold to simplify vr

local appscaffold = require("utils/appscaffold.t")
local math = require("math")
local class = require("class")
local rendertarget = require("gfx/rendertarget.t")
local Camera = require("gfx/camera.t").Camera
local shaderutils = require("utils/shaderutils.t")
local uniforms = require("gfx/uniforms.t")
local geometry = require("gfx/geometry.t")
local openvr = require("vr/openvr.t")

local m = {}

local VRApp = appscaffold.AppScaffold:extend("VRApp")

function VRApp:init(options)
    openvr.init()
    local vw, vh = 800, 1280
    if openvr.available then
        vw, vh = openvr.getRecommendedTargetSize()
    end
    self.vrWidth = math.floor((options.vrWidth or 1.0) * vw)
    self.vrHeight = math.floor((options.vrHeight or 1.0) * vh)
    log.info("VRApp init: w= " .. self.vrWidth .. ", h= " .. self.vrHeight)

    VRApp.super.init(self, options)
    self.stereoCameras = {
        Camera():makeProjection(70, self.vrWidth/self.vrHeight, 0.1, 100.0),
        Camera():makeProjection(70, self.vrWidth/self.vrHeight, 0.1, 100.0)
    }

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

    -- used to draw screen space quads to composite things
    self.orthocam = Camera():makeOrthographic(0, 1, 0, 1, -1, 1)
    self.identitymat = math.Matrix4():identity()
    self.quadgeo = geometry.TransientGeometry()
    self.compositeSampler = uniforms.TexUniform("s_srcTex", 0)
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

function VRApp:createRenderTargets()
    local w,h = self.vrWidth, self.vrHeight
    local RT = rendertarget.RenderTarget
    -- makeRGB8(hasDepth = true)
    self.targets = {RT(w,h):makeRGB8(true),
                    RT(w,h):makeRGB8(true)}
    self.eyeTexes = {self.targets[1].attachments[1],
                     self.targets[2].attachments[1]}
    self.stereoViews = {0,1}
    self.clearColors = {0x303030ff, 0x303030ff}
    self.windowView = 2

    bgfx.bgfx_set_view_clear(self.windowView,
    0x0001 + 0x0002, -- clear color + clear depth
    0x303030ff,
    1.0,
    0)

    for i = 1,2 do
        bgfx.bgfx_set_view_clear(self.stereoViews[i],
                                 001 + 0x0002, -- clear color + clear depth
                                 self.clearColors[i],
                                 1.0, 0)
    end
end

function VRApp:initPipeline()
    VRApp.super.initPipeline(self)
    self:createRenderTargets()
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
        self.camera.matrix:copy(openvr.hmd.pose)
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
    self.scene:updateMatrices()
    self.orthocam:setViewMatrices(self.windowView)
    local cams = self.stereoCameras
    for i = 1,2 do
        self.pipeline:render({camera = cams[i],
                              scene = self.scene,
                              view = self.stereoViews[i],
                              rendertarget = self.targets[i]})
        local x0 = (i-1) * 0.5
        local x1 = x0 + 0.5
        self:composite(self.targets[i], x0, 0, x1, 1.0)
    end
end

function VRApp:update()
    self.frame = self.frame + 1
    self.time = self.time + 1.0 / 60.0

    if openvr.available then
        openvr.beginFrame()
        self:updateCameras_()
    end

    -- Deal with input events
    self:updateEvents()

    -- Set the window view to take up the entire target
    bgfx.bgfx_set_view_rect(self.windowView, 0, 0, self.width, self.height)

    if self.preRender then
        self:preRender()
    end

    self:render()
    self.scripttime = toc(self.startTime)

    -- Have bgfx do its rendering
    bgfx.bgfx_frame()

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
