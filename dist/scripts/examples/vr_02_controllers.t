-- vr_01_vr.t
--
-- demonstration of using vrapp for vr

local VRApp = require("vr/vrapp.t").VRApp
local icosphere = require("geometry/icosphere.t")
local pbr = require("shaders/pbr.t")
local gfx = require("gfx")
local plotting = require("gui/plotting.t")
local futureplot = require("gui/futureplot.t")
local openvr = require("vr/openvr.t")

ControllerApp = VRApp:extend("ControllerApp")

uiwidth, uiheight = 1024, 1024

guistuff = {}

function uiSetupStuff()
    local fp = futureplot.FuturePlot({gridrows = 4, gridcols = 4},
                                        uiwidth, uiheight)

    guistuff.infos = {{}, {}}
    for i = 1,2 do
        for j = 1,4 do
            local k = "box_" .. i .. "_" .. j
            local b = plotting.TextBox({title = k, fontsize = 20})
            fp:add(b, k, j, 1 + (i-1)*2, 1, 2)
            guistuff.infos[i][j] = b
        end
    end
    guistuff.fp = fp
end

function format2digit(v)
    if not v then return "?" end
    return tostring(math.floor(v * 100.0) / 100.0)
end

function axisToText(axis)
    if not axis then return "(missing)" end
    return "(" .. format2digit(axis.x) .. ", " .. format2digit(axis.y) .. ")"
end

function buttonToText(buttonstate)
    local ret = ""
    for k,v in pairs(buttonstate) do
        if v then ret = ret .. k .. "," end
    end
    return ret
end

function uiDrawStuff(stage, nvg, width, height)
    guistuff.fp:draw(nvg)
end

function ControllerApp:onControllerConnected(idx, controllerobj)
    local axisObj = gfx.Object3D(axisGeo, axisMat)
    controllerobj:add(axisObj)
    log.info("Added axis?")
end

function ControllerApp:preRender()
    local controllers = openvr.controllers
    for i = 1,2 do
        if controllers[i] and controllers[i].connected then
            local target = controllers[i]
            guistuff.infos[i][1]:setText("pad: " .. axisToText(target.trackpad1))
            guistuff.infos[i][2]:setText("tri: " .. axisToText(target.trigger1))
            guistuff.infos[i][3]:setText("t: " .. buttonToText(target.touched))
            guistuff.infos[i][4]:setText("p: " .. buttonToText(target.pressed))
            target:vibrate(target.trigger1.x)
        else
            for j = 1,4 do guistuff.infos[i][j]:setText("...") end
        end
    end
end

function ControllerApp:initPipeline()
    self:setupTargets()
    self.nvgBuffer = gfx.RenderTarget(uiwidth, uiheight):makeRGB8()
    self.nvgTexture = self.nvgBuffer.attachments[1]
    self.pipeline = gfx.Pipeline()

    -- set up nvg pass
    local nvgpass = gfx.NanoVGStage({
        renderTarget = self.nvgBuffer,
        clear = {color = 0x300000ff},
        draw = uiDrawStuff
    })
    nvgpass.extraNvgSetup = function(stage)
        stage.nvgfont = nanovg.nvgCreateFont(stage.nvgContext, "sans", "font/VeraMono.ttf")
    end
    self.pipeline:add("uipass", nvgpass)

    -- set up individual eye passes by creating one forward pass and then
    -- duplicating it twice
    local pbr = require("shaders/pbr.t")
    local flat = require("shaders/flat.t")
    local forwardpass = gfx.MultiShaderStage({
        renderTarget = nil,
        clear = {color = 0x303030ff},
        shaders = {solid = pbr.PBRShader(),
                   flatTextured = flat.FlatShader({texture=true})}
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

function randu(magnitude)
    return (math.random() * 2.0 - 1.0)*(magnitude or 1.0)
end

function createGeometry()
    local geo = icosphere.icosphereGeo(0.5, 3, "sphere")
    local mat = pbr.PBRMaterial("solid"):roughness(0.8):tint(0.1,0.1,0.1)

    local nspheres = 20
    for i = 1,nspheres do
        local sphere = gfx.Object3D(geo, mat)
        sphere.position:set(randu(5), randu(5), randu(5))
        sphere:updateMatrix()
        app.scene:add(sphere)
    end

    local uiGeo = require("geometry/plane.t").planeGeo(1.0, 1.0, 2, 2, "uigeo")
    local uiMat = require("shaders/flat.t").FlatMaterial({diffuseMap = app.nvgTexture})
    uiPlane = gfx.Object3D(uiGeo, uiMat)
    uiPlane.position:set(0, 1, 0)
    uiPlane:updateMatrix()
    app.scene:add(uiPlane)

    log.info("Created axis stuff")
    axisGeo = require("geometry/widgets.t").axisWidgetGeo("axis_widget_geo", 0.1)
    axisMat = pbr.PBRMaterial("solid"):roughness(0.8):diffuse(0.2,0.2,0.2)

    app.scene:add(gfx.Object3D(axisGeo, axisMat))
end

function init()
    app = ControllerApp({title = "vr_01_vr",
                         width = 1280,
                         height = 720})
    uiSetupStuff()
    createGeometry()
end

function update()
    app:update()
end
