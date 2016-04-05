-- 07_scaffold.t
--
-- demonstration of how to use AppScaffold to simplify setup

local AppScaffold = require("utils/appscaffold.t").AppScaffold
local icosphere = require("geometry/icosphere.t")
local pbr = require("shaders/pbr.t")
local Object3D = require('gfx/object3d.t').Object3D

function randu(magnitude)
    return (math.random() * 2.0 - 1.0)*(magnitude or 1.0)
end

function createGeometry()
    local geo = icosphere.icosphereGeo(0.5, 3, "sphere")
    local mat = pbr.PBRMaterial("solid"):roughness(0.8):tint(0.1,0.1,0.1)

    local nspheres = 5000
    for i = 1,nspheres do
        local sphere = Object3D(geo, mat)
        sphere.position:set(randu(5), randu(5), randu(5))
        sphere:updateMatrix()
        app.scene:add(sphere)
    end
end

function preRender(appSelf)
    rotator.quaternion:fromEuler({x=0,y=app.time*0.25,z=0})
    rotator:updateMatrix()
end

function init()
    app = AppScaffold({title = "07_scaffold",
                       width = 1280,
                       height = 720,
                       usenvg = false})
    app.preRender = preRender

    rotator = Object3D()
    app.scene:add(rotator)
    rotator:add(app.camera)

    app.camera.position:set(0.0, 0.0, 10.0)
    app.camera:updateMatrix()
    createGeometry()
end

function update()
    app:update()
end