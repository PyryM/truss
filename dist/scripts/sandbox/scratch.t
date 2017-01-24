-- scratch.t
--
-- a file to hold functions being worked on

local webconsole = require("devtools/webconsole.t")
local math = require("math")
local App = require("utils/appscaffold.t").AppScaffold
local orbitcam = require("gui/orbitcam.t")
local gfx = require("gfx")
local icosphere = require("geometry/icosphere.t")
local widgets = require("geometry/widgets.t")
local pbr = require("shaders/pbr.t")

--webconsole.start()

function init()
    app = App({
        width = 1280,
        height = 720,
        title = "test"
    })

    local mat = pbr.PBRMaterial("solid"):roughness(0.8):tint(0.1,0.1,0.1)
    local spheregeo = icosphere.icosphereGeo(0.05, 2, "icosphere")
    local widgetgeo = widgets.axisWidgetGeo("widget")

    local Vector = require("math").Vector
    local axes = {Vector(0.0,0.0,0.0),
                  Vector(1.0,0.0,0.0), Vector(0.0,1.0,0.0), Vector(0.0,0.0,1.0)}
    local colors = {{0.3, 0.3, 0.3}, {1.0,0.0,0.0}, {0.0,1.0,0.0}, {0.0,0.0,1.0}}
    local mat = pbr.PBRMaterial("solid"):roughness(0.8):tint(0.001,0.001,0.001)

    for idx, axispos in ipairs(axes) do
        local gmat = pbr.PBRMaterial("solid"):roughness(0.8):tint(0.001,0.001,0.001)
        gmat:diffuse(unpack(colors[idx]))
        local obj = gfx.Object3D(spheregeo, gmat)
        obj.position:copy(axispos)
        obj:updateMatrix()
        app.scene:add(obj)
    end
    app.scene:add(gfx.Object3D(widgetgeo, mat))

    app.userEventHandler = onSdlEvent
    camerarig = orbitcam.OrbitCameraRig(app.camera)
    camerarig:setZoomLimits(0.2, 5.0)
    camerarig:set(0, 0, 1.0)
end

function onSdlEvent(selfapp, evt)
    camerarig:updateFromSDL(evt)
end

function update()
    camerarig:update(1.0 / 60.0)
    app:update()
end
