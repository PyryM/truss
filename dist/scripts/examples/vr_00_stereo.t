-- vr_00_stereo.t
--
-- demonstration of using vrapp for a simple stereo pipeline

local VRApp = require("vr/vrapp.t").VRApp
local icosphere = require("geometry/icosphere.t")
local pbr = require("shaders/pbr.t")
local Object3D = require('gfx/object3d.t').Object3D
local orbitcam = require('gui/orbitcam.t')

function randu(magnitude)
    return (math.random() * 2.0 - 1.0)*(magnitude or 1.0)
end

function createGeometry()
    local geo = icosphere.icosphereGeo(0.5, 3, "sphere")
    local mat = pbr.PBRMaterial("solid"):roughness(0.8):tint(0.1,0.1,0.1)

    local nspheres = 200
    for i = 1,nspheres do
        local sphere = Object3D(geo, mat)
        sphere.position:set(randu(5), randu(5)-5, randu(5))
        sphere:updateMatrix()
        app.scene:add(sphere)
    end
end

function init()
    app = VRApp({title = "vr_00_stereo",
                       width = 1280,
                       height = 720,
                       vrWidth = math.floor(1.4 * 1280/2),
                       vrHeight = math.floor(1.4 * 720),
                       usenvg = false})
    app.userEventHandler = onSdlEvent
    camerarig = orbitcam.OrbitCameraRig(app.camera)
    camerarig:setZoomLimits(1.0, 30.0)
    camerarig:set(0, 0, 15.0)
    createGeometry()
    log.info(app.stereoCameras[1])
    log.info("Projection: " .. app.stereoCameras[1].projMat:prettystr())
end

function onSdlEvent(selfapp, evt)
    camerarig:updateFromSDL(evt)
end

function update()
    camerarig:update(1.0 / 60.0)
    app:update()
end
