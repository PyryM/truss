-- 01_raw_scenegraph.t
--
-- direct use/iteration over a scenegraph without any other rendering
-- conveniences (e.g., renderpass)

sdl = truss.addons.sdl

local math = require("math")
local Vector = math.Vector
local Matrix4 = math.Matrix4
local Quaternion = math.Quaternion
local debugcube = require("geometry/debugcube.t")
local shaderutils = require('utils/shaderutils.t')
local Object3D = require('gfx/object3d.t').Object3D
local StaticGeometry = require("gfx/geometry.t").StaticGeometry
local Camera = require("gfx/camera.t").Camera
local MultiPass = require("gfx/multipass.t").MultiPass
local uniforms = require("gfx/uniforms.t")

width = 1280
height = 720
time = 0.0

function updateEvents()
    for evt in sdl:events() do
        if evt.event_type == sdl.EVENT_WINDOW and evt.flags == 14 then
            log.info("Received window close, stopping interpreter...")
            truss.quit()
        end
    end
end

-- actually creates the cube structure
function createCubeThing()
    local geoutils = require("geometry/geoutils.t")
    local icosphere = require("geometry/icosphere.t")
    local cylinder = require("geometry/cylinder.t")

    local ncubes = 20

    --local cylinderData = icosphere.icosahedronData(1.0) --cylinder.cylinderData(0.5, 1.0, 3, true)
    --cylinderData = geoutils.subdivide(cylinderData)
    --cylinderData = geoutils.subdivide(cylinderData)
    --cylinderData = geoutils.subdivide(cylinderData)

    --geoutils.spherize(cylinderData, 2.0)
    local cylinderData = icosphere.icosphereData(2.0, 3)
    log.info(#cylinderData.attributes.position)
    geoutils.computeNormals(cylinderData)
    --geoutils.colorRandomly(cylinderData)

    local vertInfo = require("gfx/vertexdefs.t").createPosNormalVertexInfo()
    local cylinderGeo = StaticGeometry("cylinder"):fromData(vertInfo, cylinderData)

    -- create a dummy object to move the whole stack in front of the camera
    local rootobj = Object3D()
    rootobj.name = "rootobj"
    rootobj.position:set(0.0, 0.0, 0.0)
    rootobj:updateMatrix()
    sg = rootobj
    rotator = Object3D()
    rootobj:add(rotator)
    rotator:add(camera)
    camera.position:set(0.0, 5.0, 10.0)
    camera:updateMatrix()

    local prevcube = rootobj
    local pbr = require("shaders/pbr.t")

    for i = 1,ncubes do
        local mat = pbr.PBRMaterial("solid"):roughness(0.8):tint(0.1,0.1,0.1)
        local cube = Object3D(cylinderGeo, mat)
        cube.position:set(0.0, 2.0, 0.0)
        cube.frequency = i * 0.1
        cube.phase = math.pi * 6.0 * i/ncubes
        cube.scale:set(0.9, 0.9, 0.9)
        cube.name = "cube_" .. i
        prevcube:add(cube)
        prevcube = cube
    end
end

function twiddleCube(cube)
    --log.info("Twiddling " .. (cube.name or cube.id))
    if cube.frequency then
        local f = cube.frequency
        local theta0 = math.cos(f * 0.9 * time)
        local theta1 = math.cos(f * 1.0 * time)
        local theta2 = math.cos(f * 1.1 * time)
        cube.quaternion:fromEuler({x=theta0, y=theta1, z=theta2})
        cube:updateMatrix()
        local vv = 0.5 + 0.5 * math.cos(3.0 * f * time + (cube.phase or 0))
        cube.mat:diffuse(vv, vv, vv)
    end
end

function updateAndDrawCubes()
    sg:map(twiddleCube)
    rotator.quaternion:fromEuler({x=0,y=time*0.25,z=0})
    rotator:updateMatrix()
    sg:updateMatrices()
    renderpass:render({camera = camera, scene = sg})
end

function setupPipeline()
    renderpass = MultiPass()

    local pbrshader = require("shaders/pbr.t").PBRShader()
    renderpass:addShader("solid", pbrshader)

    -- set default lights
    renderpass.globals.lightDirs:setMultiple({
            Vector( 1.0,  1.0,  0.0),
            Vector(-1.0,  1.0,  0.0),
            Vector( 0.0, -1.0,  1.0),
            Vector( 0.0, -1.0, -1.0)})

    renderpass.globals.lightColors:setMultiple({
            Vector(0.8, 0.8, 0.8),
            Vector(1.0, 1.0, 1.0),
            Vector(0.1, 0.1, 0.1),
            Vector(0.1, 0.1, 0.1)})
end

function init()
    log.info("main script init")
    sdl:createWindow(width, height, '01 raw scenegraph')
    log.info("created window")

    -- basic init
    local resetFlags = bgfx_const.BGFX_RESET_VSYNC +
                       bgfx_const.BGFX_RESET_MSAA_X8

    bgfx.bgfx_init(bgfx.BGFX_RENDERER_TYPE_COUNT, 0, 0, nil, nil)
    bgfx.bgfx_reset(width, height, resetFlags)

    -- Enable debug text.
    bgfx.bgfx_set_debug(bgfx_const.BGFX_DEBUG_TEXT)

    log.info("Basic BGFX init complete!")
    local rendererType = bgfx.bgfx_get_renderer_type()
    local rendererName = ffi.string(bgfx.bgfx_get_renderer_name(rendererType))
    log.info("Renderer type: " .. rendererName)

    bgfx.bgfx_set_view_clear(0, -- viewid 0
    bgfx_const.BGFX_CLEAR_COLOR + bgfx_const.BGFX_CLEAR_DEPTH,
    0x303030ff, -- clearcolor (gray)
    1.0, -- cleardepth (in normalized space: 1.0 = max depth)
    0)

    -- init the cube geometry
    cubegeo = debugcube.createGeo()

    -- load shader program
    log.info("Loading program")
    program = shaderutils.loadProgram("vs_cubes", "fs_cubes")

    -- create camera
    camera = Camera():makeProjection(70, width/height, 0.1, 100.0)

    -- create and populate scenegraph
    createCubeThing()

    -- create pipeline
    setupPipeline()

    -- posvec = Vector(0.0, 0.0, -10.0)
    -- scalevec = Vector(1.0, 1.0, 1.0)
    -- rotquat = Quaternion():identity()
end

frametime = 0.0

function update()
    time = time + 1.0 / 60.0

    local startTime = truss.tic()

    -- Deal with input events
    updateEvents()

    -- Set view 0 default viewport.
    bgfx.bgfx_set_view_rect(0, 0, 0, width, height)

    -- Use debug font to print information about this example.
    bgfx.bgfx_dbg_text_clear(0, false)

    bgfx.bgfx_dbg_text_printf(0, 1, 0x4f, "scripts/examples/03_passes.t")
    bgfx.bgfx_dbg_text_printf(0, 2, 0x6f, "frame time: " .. frametime*1000.0 .. " ms")

    -- update and draw cubes
    updateAndDrawCubes()

    -- Advance to next frame. Rendering thread will be kicked to
    -- process submitted rendering primitives.
    bgfx.bgfx_frame(false)

    frametime = truss.toc(startTime)
end
