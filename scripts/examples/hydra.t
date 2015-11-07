-- loadmesh.t
--
-- an example of loading and displaying a mesh

scaffold = require('utils/appscaffold.t')
orbitcam = require('gui/orbitcam.t')
objloader = require('loaders/objloader.t')
meshutils = require('mesh/mesh.t')
grid = require('gui/grid.t')
sixense = require('input/sixense.t')

-- define some globals
camera = nil
controllers = {}

function init()
    app = scaffold.AppScaffold({
            width = 1280,
            height = 720
        })

    camera = orbitcam()
    app:setEventHandler(function(evt)
                            camera:updateFromSDL(evt)
                        end)

    -- load in the mesh
    objloader.verbose = true
    local modeldata = objloader.loadOBJ("models/hydra_controller.obj", false)
    local modelgeo = meshutils.Geometry():fromData(app.renderer.vertexInfo,
                                                   modeldata)
    local modelmaterial = {roughness = 0.8, 
                           fresnel = {0.7, 0.7, 0.3}, 
                           color = {0.1, 0.1, 0.1}}

    for i = 1,2 do
        local curmodel = meshutils.Mesh(modelgeo, modelmaterial)
        app.renderer:add(curmodel)
        controllers[i] = curmodel
    end

    local thegrid = grid.createLineGrid()
    thegrid.quaternion:fromEuler({x = math.pi / 2.0, y = 0.0, z = 0.0}, 'XYZ')
    app.renderer:add(thegrid)

    initHydra()
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
end

function ourUpdate()
    updateHydra()
    camera:update(1.0 / 60.0)
    app.renderer:setCameraTransform(camera.mat)
end

function update()
    app:update(ourUpdate)
end