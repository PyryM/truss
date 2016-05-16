-- vr_01_vr.t
--
-- demonstration of using vrapp for vr

local VRApp = require("vr/vrapp.t").VRApp
local icosphere = require("geometry/icosphere.t")
local pbr = require("shaders/pbr.t")
local Object3D = require('gfx/object3d.t').Object3D
local objloader = require('loaders/objloader.t')
local geometry = require('gfx/geometry.t')
local vdefs = require('gfx/vertexdefs.t')

function randu(magnitude)
    return (math.random() * 2.0 - 1.0)*(magnitude or 1.0)
end

function loadOBJ(filename)
    local basicdef = vdefs.createStandardVertexType({"position", "normal"})
    local objdata = objloader.loadOBJ(filename)
    local tempgeo = geometry.StaticGeometry(filename):fromData(basicdef, objdata)
    return tempgeo
end

function createGeometry()
    local geo = icosphere.icosphereGeo(0.5, 3, "sphere")
    local mat = pbr.PBRMaterial("solid"):roughness(0.8):tint(0.1,0.1,0.1)

    local mgeo = loadOBJ("models/module.obj")
    moduleobj = Object3D(mgeo, mat)
    moduleobj.position:set(0,0,0)
    moduleobj:updateMatrix()
    app.scene:add(moduleobj)

    -- local nspheres = 200
    -- for i = 1,nspheres do
    --     local sphere = Object3D(facegeo, mat)
    --     sphere.position:set(randu(5), randu(5), randu(5))
    --     sphere:updateMatrix()
    --     app.scene:add(sphere)
    -- end
end

function init()
    app = VRApp({title = "vr_01_vr",
                       width = 1280,
                       height = 720,
                       usenvg = false})
    createGeometry()
end

function update()
    app:update()
end
