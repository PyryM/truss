-- loadmesh.t
--
-- an example of loading and displaying a mesh

scaffold = require('utils/appscaffold.t')
orbitcam = require('gui/orbitcam.t')
objloader = require('loaders/objloader.t')
meshutils = require('mesh/mesh.t')
grid = require('gui/grid.t')
sixense = require('input/sixense.t')
class = require('class')
bgfx = core.bgfx
bgfx_const = core.bgfx_const

-- define some globals
camera = nil
controllers = {}

-- need a special material for the 'ghost' effect
local GhostMaterial = class("GhostMaterial")

function GhostMaterial:init(color)
    local sutils = require("utils/shaderutils.t")
    self.program = sutils.loadProgram("vs_ghost", "fs_ghost")
    -- TODO: share uniforms??
    self.color_u = bgfx.bgfx_create_uniform("u_baseColor", 
                            bgfx.BGFX_UNIFORM_TYPE_VEC4, 1)
    self.color4f = terralib.new(float[4])
    for i = 1,4 do 
        self.color4f[i-1] = color[i] or 1.0 
    end
end

function GhostMaterial:apply()
    bgfx.bgfx_set_uniform(self.color_u, self.color4f, 1)
end

function init()
    app = scaffold.AppScaffold({
            width = 1280,
            height = 720
        })

    camera = orbitcam()
    app:setEventHandler(onEvent)

    -- load in the mesh
    objloader.verbose = true
    local modeldata = objloader.loadOBJ("models/hydra_controller.obj", false)
    local modelgeo = meshutils.Geometry():fromData(app.renderer.vertexInfo,
                                                   modeldata)
    local modelmaterial = {roughness = 0.8, 
                           fresnel = {0.6, 0.6, 0.6}, 
                           color = {0.05, 0.05, 0.05}}

    local ghostmaterials = {GhostMaterial({1.0, 0.0, 0.0}),
                            GhostMaterial({0.0, 1.0, 0.0})}

    for i = 1,2 do
        local curmodel = meshutils.Mesh(modelgeo, ghostmaterials[i])
        app.renderer:add(curmodel)
        controllers[i] = curmodel
    end

    local basedata = objloader.loadOBJ("models/hydra_base.obj", false)
    local basegeo = meshutils.Geometry():fromData(app.renderer.vertexInfo, basedata)
    thebase = meshutils.Mesh(basegeo, modelmaterial)
    thebase.position.y = -0.5
    app.renderer:add(thebase)

    local thegrid = grid.createLineGrid()
    thegrid.quaternion:fromEuler({x = math.pi / 2.0, y = 0.0, z = 0.0}, 'XYZ')
    app.renderer:add(thegrid)

    initHydra()
end

function onEvent(evt)
    camera:updateFromSDL(evt)
end

function initHydra()
    sixense.init()
end

function updateHydra()
    sixense.update()
    for i = 1,2 do
        controllers[i].quaternion:fromArray(sixense.controllers[i].quat)
        local xp = sixense.controllers[i].pos
        controllers[i].position = {x = xp[1] / 100.0, y = xp[2] / 100.0, z = xp[3] / 100.0}
    end
    updateCameraFromHydra()
end

function updateCameraFromHydra()
    local dtheta = sixense.controllers[1].joy[1] * 4.0
    local dphi = sixense.controllers[1].joy[2] * 3.0

    camera:moveTheta(dtheta)
    camera:movePhi(dphi)

    local dx = sixense.controllers[2].joy[1] * 0.5
    local dy = sixense.controllers[2].joy[2] * 0.5
    camera:panOrbitPoint(dx, dy)
end

function ourUpdate()
    updateHydra()
    camera:update(1.0 / 60.0)
    app.renderer:setCameraTransform(camera.mat)
end

function update()
    app:update(ourUpdate)
end