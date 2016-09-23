-- 07_scaffold.t
--
-- demonstration of how to use AppScaffold to simplify setup

local AppScaffold = require("utils/appscaffold.t").AppScaffold
local icosphere = require("geometry/icosphere.t")
local cube = require("geometry/cube.t")
local pbr = require("shaders/pbr.t")
local gfx = require("gfx")
local orbitcam = require("gui/orbitcam.t")

function randu(mag) return (math.random() * 2.0 - 1.0)*(mag or 1.0) end

function createGeometry()
    local cylinder = require("geometry/cylinder.t")
    --local geo = cube.cubeGeo(1.0, 1.0, 1.0, "cube")
    local geo = cylinder.cylinderGeo(0.5, 2.0, 20, true, "cylinder")
    local mat = pbr.PBRMaterial("solid"):roughness(0.8):tint(0.1,0.1,0.1)

    for i = 1,5000 do
        local sphere = gfx.Object3D(geo, mat)
        sphere.position:set(randu(5), randu(5), randu(5))
        sphere.quaternion:fromEuler({x = randu(), y = randu(), z = randu()})
        sphere:updateMatrix()
        app.scene:add(sphere)
    end
end

function init()
    app = AppScaffold({title = "07_scaffold",
                       width = 1280,
                       height = 720,
                       usenvg = false})
    app.userEventHandler = onSdlEvent
    app:onKey("F12", function(key, mod)
        app:takeScreenshot("test.png")
    end)
    app:onKey("F10", function(key, mod)
        app:thisFunctionDoesntExist()
    end)
    camerarig = orbitcam.OrbitCameraRig(app.camera)
    camerarig:setZoomLimits(1.0, 30.0)
    camerarig:set(0, 0, 15.0)
    createGeometry()
end

function onSdlEvent(selfapp, evt)
    camerarig:updateFromSDL(evt)
end

function update()
    camerarig:update(1.0 / 60.0)
    app:update()
end
