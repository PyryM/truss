-- loadmesh.t
--
-- an example of loading and displaying a mesh

scaffold = require('utils/appscaffold.t')
orbitcam = require('gui/orbitcam.t')
objloader = require('loaders/objloader.t')
meshutils = require('mesh/mesh.t')
grid = require('gui/grid.t')

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
    local modeldata = objloader.loadOBJ("models/myface_big.obj", false)
    local modelgeo = meshutils.Geometry():fromData(app.renderer.vertexInfo,
                                                   modeldata)
    local modelmaterial = {roughness = 0.8, 
                           fresnel = {0.7, 0.7, 0.3}, 
                           color = {0.1, 0.1, 0.1}}

    themodel = meshutils.Mesh(modelgeo, modelmaterial)
    app.renderer:add(themodel)
    local thegrid = grid.createLineGrid()
    thegrid.quaternion:fromEuler({x = math.pi / 2.0, y = 0.0, z = 0.0}, 'XYZ')
    app.renderer:add(thegrid)
end

function ourUpdate()
    camera:update(1.0 / 60.0)
    app.renderer:setCameraTransform(camera.mat)
end

function update()
    app:update(ourUpdate)
end