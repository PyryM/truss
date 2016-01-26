-- 00_buffercube.t
-- 
-- manually create a cube mesh and use it to draw multiple cubes spinning

bgfx = core.bgfx
bgfx_const = core.bgfx_const
terralib = core.terralib
trss = core.trss
sdl = addons.sdl
TRSS_ID = core.TRSS_ID

local Vector = require("math/vec.t").Vector
local Matrix4 = require("math/matrix.t").Matrix4
local Quaternion = require("math/quat.t").Quaternion
local StaticGeometry = require("gfx/geometry.t").StaticGeometry
local vertexInfo = require("gfx/vertexdefs.t").createPosColorVertexInfo()
local shaderutils = require('utils/shaderutils.t')

function makeCubeGeometry()
    local positions = {
                        {-1.0,  1.0,  1.0},
                        { 1.0,  1.0,  1.0},
                        {-1.0, -1.0,  1.0},
                        { 1.0, -1.0,  1.0},
                        {-1.0,  1.0, -1.0},
                        { 1.0,  1.0, -1.0},
                        {-1.0, -1.0, -1.0},
                        { 1.0, -1.0, -1.0}
                       }

    local colors = {
                        { 0.0, 0.0, 0.0, 255},
                        { 255, 0.0, 0.0, 255},
                        { 0.0, 255, 0.0, 255},
                        { 255, 255, 0.0, 255},
                        { 0.0, 0.0, 255, 255},
                        { 255, 0.0, 255, 255},
                        { 0.0, 255, 255, 255},
                        { 255, 255, 255, 255}    
                    }

    local indices = {
                        0, 2, 1,
                        1, 2, 3,
                        4, 5, 6, 
                        5, 7, 6,
                        0, 4, 2, 
                        4, 6, 2,
                        1, 3, 5, 
                        5, 3, 7,
                        0, 1, 4, 
                        4, 1, 5,
                        2, 6, 3, 
                        6, 7, 3 
                    }

    local cubegeo = StaticGeometry("cube"):allocate(vertexInfo, #positions, #indices)
    cubegeo:setIndices(indices)
    cubegeo:setAttribute("position", positions)
    cubegeo:setAttribute("color", colors)
    cubegeo:build()
    return cubegeo
end

function init()
    log.info("cube.t init")
    sdl:createWindow(width, height, '00 buffercube')
    log.info("created window")
    initBGFX()
    local rendererType = bgfx.bgfx_get_renderer_type()
    local rendererName = ffi.string(bgfx.bgfx_get_renderer_name(rendererType))
    log.info("Renderer type: " .. rendererName)
end

width = 800
height = 600
frame = 0
time = 0.0

function updateEvents()
    for evt in sdl:events() do
        if evt.event_type == sdl.EVENT_WINDOW and evt.flags == 14 then
            log.info("Received window close, stopping interpreter...")
            trss.trss_stop_interpreter(TRSS_ID)
        end
    end
end

function initBGFX()
    -- Basic init

    local debug = bgfx_const.BGFX_DEBUG_TEXT
    local reset = bgfx_const.BGFX_RESET_VSYNC + bgfx_const.BGFX_RESET_MSAA_X8

    log.info("going to init bgfx")
    bgfx.bgfx_init(bgfx.BGFX_RENDERER_TYPE_COUNT, 0, 0, nil, nil)
    --bgfx.bgfx_init(bgfx.BGFX_RENDERER_TYPE_DIRECT3D9, 0, 0, nil, nil)
    bgfx.bgfx_reset(width, height, reset)
    log.info("initted bgfx")

    -- Enable debug text.
    bgfx.bgfx_set_debug(debug)

    bgfx.bgfx_set_view_clear(0, 
    0x0001 + 0x0002, -- clear color + clear depth
    0x303030ff,
    1.0,
    0)

    log.info("Initted bgfx I hope?")

    -- Init the cube

    cubegeo = makeCubeGeometry()

    -- load shader program
    log.info("Loading program")
    program = shaderutils.loadProgram("vs_cubes", "fs_cubes")

    -- create matrices
    projmat = Matrix4():makeProjection(70, 800/600, 0.1, 100.0)
    viewmat = Matrix4():identity()
    modelmat = Matrix4():identity()
    posvec = Vector(0.0, 0.0, -10.0)
    scalevec = Vector(1.0, 1.0, 1.0)
    rotquat = Quaternion():identity()
end

function drawCube(xpos, ypos, phase)
    -- Compute the cube's transformation
    rotquat:fromEuler({x = time + phase, y = time + phase, z = 0.0})
    posvec:set(xpos, ypos, -10.0)
    modelmat:composeRigid(posvec, rotquat)
    bgfx.bgfx_set_transform(modelmat.data, 1) -- only one matrix in array

    -- Bind the cube buffers
    cubegeo:bind()

    -- Setting default state is not strictly necessary, but good practice
    bgfx.bgfx_set_state(bgfx_const.BGFX_STATE_DEFAULT, 0)
    bgfx.bgfx_submit(0, program, 0)
end

frametime = 0.0

function update()
    frame = frame + 1
    time = time + 1.0 / 60.0

    local startTime = tic()

    -- Deal with input events
    updateEvents()

    -- Set view 0 default viewport.
    bgfx.bgfx_set_view_rect(0, 0, 0, width, height)

    -- This dummy draw call is here to make sure that view 0 is cleared
    -- if no other draw calls are submitted to view 0.
    --bgfx.bgfx_submit(0, 0)

    -- Use debug font to print information about this example.
    bgfx.bgfx_dbg_text_clear(0, false)

    bgfx.bgfx_dbg_text_printf(0, 1, 0x4f, "scripts/examples/cube.t")
    bgfx.bgfx_dbg_text_printf(0, 2, 0x6f, "frame time: " .. frametime*1000.0 .. " ms")

    -- Set viewprojection matrix
    bgfx.bgfx_set_view_transform(0, viewmat.data, projmat.data)

    -- draw four cubes
    drawCube( 3,  3, 0.0)
    drawCube(-3,  3, 1.0)
    drawCube(-3, -3, 2.0)
    drawCube( 3, -3, 3.0)

    -- Advance to next frame. Rendering thread will be kicked to
    -- process submitted rendering primitives.
    bgfx.bgfx_frame()

    frametime = toc(startTime)
end