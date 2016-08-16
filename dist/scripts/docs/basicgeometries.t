-- Basic Geometry Generators
-- =========================

-- These are small modules that generate meshes for various "primitives"
-- (although they aren't truly primitives in this case, they're regular meshes)
-- like spheres, cubes, etc.

-- For this example we will just keep on replacing the geometry of one object
-- that's already in the scene (this is safe because Object3Ds are lightweight)
function basicGeometryExamples(app)
    local target = app.exampleObject

    -- #### geometry/cube.t
    -- A 'cube' (rectangular prism) defined by size on each axis
    local sX, sY, sZ = 2, 2, 2
    target.geo = require("geometry/cube.t").cubeGeo(sX, sY, sZ, "cube")

    -- ![Image of a basic cube](images/basicgeo_cube.png)
    app:present("docs/images/basicgeo_cube.png")

    -- #### geometry/cylinder.t
    -- A cylinder, in capped and uncapped forms
    local radius = 1.0
    local height = 2.0
    local numSegs = 40
    local capped = true
    local cylinder = require("geometry/cylinder.t")
    target.geo = cylinder.cylinderGeo(radius, height, numSegs, capped, "capped")

    -- ![Image of cylinders](images/basicgeo_cylinder.png)
    app:present("docs/images/basicgeo_cylinder.png")

    -- #### geometry/icosphere.t
    -- An icosphere, a subdivided icosahedron
    local radius = 1.5
    local subdivisions = 3
    local icosphere = require("geometry/icosphere.t")
    target.geo = icosphere.icosphereGeo(radius, subdivisions, "icosphere")

    -- ![Image of an icosphere](images/basicgeo_icosphere.png)
    app:present("docs/images/basicgeo_icosphere.png")

    -- #### geometry/uvsphere.t
    -- A uvsphere, a familiar latitude/longitude sphere
    local uvsphereOptions = {
        rad = 1.5,
        latDivs = 20,
        lonDivs = 20
    }
    local uvsphere = require("geometry/uvsphere.t")
    target.geo = uvsphere.uvSphereGeo(uvsphereOptions, "uvsphere")

    -- ![Image of a uvsphere](images/basicgeo_uvsphere.png)
    app:present("docs/images/basicgeo_uvsphere.png")
end

----------------------------------

-- Example setup stuff
-- -------------------
function init()
    -- Use the DocScaffold app to run our example script
    gfx = require("gfx")
    app = require("docs/docscaffold.t").DocScaffold({})

    -- Create a somewhat plastic-y white material
    local pbr = require("shaders/pbr.t")
    local mat = pbr.PBRMaterial("solid"):roughness(0.7):tint(0.1,0.1,0.1)
    mat:diffuse(0.3,0.3,0.3)

    -- Create the example object. Since empty objects are allowed, we can
    -- safely created a stub object without any geometry.
    app.exampleObject = gfx.Object3D(nil, mat)

    -- Try to position the object at an angle
    app.exampleObject.quaternion:fromEuler({0.0, 0.7, 0.0})
    app.exampleObject:updateMatrix()
    app.scene:add(app.exampleObject)

    -- Set the camera to be looking down
    app.camera.position:set(0.0, 2.0, 3.0)
    app.camera.quaternion:fromEuler({-0.6, 0.0, 0.0}, 'ZYX')
    app.camera:updateMatrix()

    app:startScript(basicGeometryExamples)
end

function update()
    app:update()
end
