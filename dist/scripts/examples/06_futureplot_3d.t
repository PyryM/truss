-- 06_futureplot_3d.t
--
-- example of rendering nanovg (futureplot) to a texture

local math = require("math")
local gfx = require("gfx")
local shaderutils = require('utils/shaderutils.t')
local futureplot = require("gui/futureplot.t")
local orbitcam = require('gui/orbitcam.t')
local AppScaffold = require("utils/appscaffold.t").AppScaffold

local nanovg = core.nanovg

function myDrawFunction(stage, nvg, width, height)
    futureplot.draw(nvg, width, height)
end

local DemoApp = AppScaffold:extend("DemoApp")
function DemoApp:initPipeline()
    local pbr = require("shaders/pbr.t")
    local flat = require("shaders/flat.t")

    self.pipeline = gfx.Pipeline()

    local backbuffer = gfx.RenderTarget(self.width, self.height):makeBackbuffer()
    local nvgbuffer = gfx.RenderTarget(1024, 1024):makeRGB8()
    self.nvgTexture = nvgbuffer.attachments[1]

    local nvgpass = gfx.NanoVGStage({
        renderTarget = nvgbuffer,
        clear = {color = 0x300000ff},
        draw = myDrawFunction
    })
    nvgpass.extraNvgSetup = function(stage)
        stage.nvgfont = nanovg.nvgCreateFont(stage.nvgContext, "sans", "font/VeraMono.ttf")
    end

    local forwardpass = gfx.MultiShaderStage({
        renderTarget = backbuffer,
        clear = {color = 0x303030ff},
        shaders = {solid = pbr.PBRShader(), flatTextured = flat.FlatShader({texture=true})}
    })
    self.pipeline:add("nvgpass", nvgpass)
    self.pipeline:add("forwardpass", forwardpass)
    self.pipeline:setupViews(0)

    -- set default lights
    local Vector = math.Vector
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

function DemoApp:userEventHandler(evt)
    camerarig:updateFromSDL(evt)
end

function init()
    app = DemoApp({title = "06_futureplot_3d",
                       width = 1280,
                       height = 720,
                       usenvg = false})
    app.userEventHandler = onSdlEvent
    camerarig = orbitcam.OrbitCameraRig(app.camera)
    camerarig:setZoomLimits(1.0, 30.0)
    camerarig:set(0, 0, 15.0)

    local cubegeo = require("geometry/cube.t").cubeGeo(10.0, 10.0, 3.0, "cube")
    local cubemat = require("shaders/flat.t").FlatMaterial({diffuseMap = app.nvgTexture})

    thecube = gfx.Object3D(cubegeo, cubemat)
    app.scene:add(thecube)

    futureplot.init(nvg, 1024, 1024)
end

function update()
    camerarig:update(1.0 / 60.0)
    app:update()
end
