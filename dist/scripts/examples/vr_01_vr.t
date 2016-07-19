-- vr_01_vr.t
--
-- demonstration of using vrapp for vr

local VRApp = require("vr/vrapp.t").VRApp
local icosphere = require("geometry/icosphere.t")
local pbr = require("shaders/pbr.t")
local gfx = require("gfx")

function randu(magnitude)
    return (math.random() * 2.0 - 1.0)*(magnitude or 1.0)
end

function createGeometry()
    local geo = icosphere.icosphereGeo(0.5, 3, "sphere")
    local mat = pbr.PBRMaterial("solid"):roughness(0.8):tint(0.1,0.1,0.1)

    local nspheres = 200
    for i = 1,nspheres do
        local sphere = gfx.Object3D(geo, mat)
        sphere.position:set(randu(5), randu(5), randu(5))
        sphere:updateMatrix()
        app.scene:add(sphere)
    end
end

function init()
    app = VRApp({title = "vr_01_vr",
                       width = 1280,
                       height = 720})
    createGeometry()
end

function update()
    app:update()
end
