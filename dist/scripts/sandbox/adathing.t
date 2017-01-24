-- adathing.t
--
-- testing armatures blah

-- start at very beginning to get most log messages
local webconsole = require("devtools/webconsole.t")
--webconsole.start()

local AppScaffold = require("utils/appscaffold.t").AppScaffold
local icosphere = require("geometry/icosphere.t")
local pbr = require("shaders/pbr.t")
local Object3D = require('gfx/object3d.t').Object3D
local Armature = require('sandbox/armature.t').Armature
local json = require('lib/json.lua')
local objloader = require('loaders/objloader.t')
local stlloader = require('loaders/stlloader.t')
local StaticGeometry = require('gfx/geometry.t').StaticGeometry
local vdefs = require('gfx/vertexdefs.t')
local line = require('geometry/line.t')
local grid = require('geometry/grid.t')

function createGeometry()
    local defaultgeo = icosphere.icosphereGeo(0.5, 3, "sphere")
    thematerial = pbr.PBRMaterial("solid")
    thematerial:diffuse(0.01,0.01,0.01)
    thematerial:tint(0.5, 0.5, 0.2)
    thematerial:roughness(0.67)

    local partGeos = {}
    local vertinfo = vdefs.createStandardVertexType({"position", "normal"})

    adaArm = Armature()
    adaArm.loadModel = function(arm, filename, dest, color)
        local geo = partGeos[filename]
        local mat = pbr.PBRMaterial("solid")
        mat:diffuse(color[1], color[2], color[3])
        mat:roughness(0.5)
        mat:tint(0.2,0.2,0.2)
        if not geo then
            -- force obj loading
            local geodata = nil
            local extension = filename:sub(-4):lower()
            if extension == ".obj" then
                geodata = objloader.loadOBJ("data/" .. filename, false)
            elseif extension == ".stl" then
                geodata = stlloader.loadSTL("data/" .. filename, false)
            end
            geo = StaticGeometry():fromData(vertinfo, geodata)
            partGeos[filename] = geo
        end
        local temp = Object3D(geo, thematerial)
        dest:add(temp)
    end
    local urdfData = json:decode(loadStringFromFile("data/mico-modified-updated.json"))
    adaArm:build(urdfData, "base_link")
    adaArm.root.quaternion:fromEuler({-math.pi/2, 0, 0})
    adaArm.root:updateMatrix()

    app.scene:add(adaArm.root)
end

function preRender(appSelf)
    rotator.quaternion:fromEuler({x=0,y=app.time*0.25,z=0})
    rotator:updateMatrix()
end

function init()
    app = AppScaffold({title = "adathing",
                       width = 1280,
                       height = 720,
                       usenvg = false})
    app.preRender = preRender

    rotator = Object3D()
    app.scene:add(rotator)
    rotator:add(app.camera)

    app.camera.position:set(0.0, 0.2, 0.75)
    app.camera:updateMatrix()

    app.pipeline:addShader("line", line.LineShader("vs_line", "fs_line_depth"))
    thegrid = grid.Grid({thickness = 0.01})
    thegrid.quaternion:fromEuler({math.pi/2, 0, 0})
    thegrid:updateMatrix()
    app.scene:add(thegrid)

    createGeometry()
end

function update()
    --webconsole.update()
    app:update()
end
