-- vr/vrapp.t
--
-- extension of AppScaffold to simplify vr

local appscaffold = require("utils/appscaffold.t")
local math = require("math")
local class = require("class")
local rendertarget = require("gfx/rendertarget.t")
local Camera = require("gfx/camera.t").Camera

local m = {}

local VRApp = appscaffold.AppScaffold:extend("VRApp")

function VRApp:init(options)
    self.vrWidth = options.vrWidth or 800
    self.vrHeight = options.vrHeight or 1280
    VRApp.super.init(self, options)
    self.stereoCameras = {
        Camera():makeProjection(70, self.width/self.height, 0.1, 100.0),
        Camera():makeProjection(70, self.width/self.height, 0.1, 100.0)
    }

    -- used to draw screen space quads to composite things
    self.orthocam = Camera():makeOrthographic(0, 1, 0, 1, -1, 1)
    self.identitymat = math.Matrix4():identity()
    self.quadgeo = require("gfx/geometry.t").TransientGeometry()
    self.compositeSampler = require("gfx/uniforms.t").TexUniform("sSrcTex", 0)
    self.compositePgm = shaderutils.loadProgram("vs_fullscreen", "fs_copy")

    -- disable debug text because it doesn't play nice with views other than 0
    bgfx.bgfx_set_debug(0)


    local hipd = 0.064 / 2.0 -- half ipd
    self.offsets = {
        math.Matrix4():makeTranslation(math.Vector(-hipd, 0.0, 0.0)),
        math.Matrix4():makeTranslation(math.Vector( hipd, 0.0, 0.0))
    }
end

function VRApp:createRenderTargets()
    local w,h = self.vrWidth, self.vrHeight
    local RT = rendertarget.RenderTarget
    -- makeRGB8(hasDepth = true)
    self.targets = {RT(w,h):makeRGB8(true),
                    RT(w,h):makeRGB8(true)}

    self.stereoViews = {0,1}
    self.windowView = 2
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

function VRApp:render()
    self.scene:updateMatrices()
    self.orthocam:setViewMatrices(self.windowView)
    local cams = self.stereoCameras
    local offsets = self.offsets
    for i = 1,2 do
        cams[i].matrix:multiply(offsets[i], self.camera.matrix)
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

    -- Deal with input events
    self:updateEvents()

    -- Set the window view to take up the entire target
    bgfx.bgfx_set_view_rect(self.windowView, 0, 0, self.width, self.height)

    if self.preRender then
        self:preRender()
    end

    self:render()
    self.scripttime = toc(self.startTime)

    -- Advance to next frame. Rendering thread will be kicked to
    -- process submitted rendering primitives.
    bgfx.bgfx_frame()

    self.frametime = toc(self.startTime)
    self.startTime = tic()
end

m.VRApp = VRApp
return m
