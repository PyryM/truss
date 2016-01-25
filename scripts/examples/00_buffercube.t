-- cube.t
-- 
-- a totally from-scratch example of how to draw a cube with
-- just raw bgfx and (almost no) helper libraries

bgfx = core.bgfx
bgfx_const = core.bgfx_const
terralib = core.terralib
trss = core.trss
sdl = raw_addons.sdl.functions
sdlPointer = raw_addons.sdl.pointer
TRSS_ID = core.TRSS_ID

local Vector = require("math/vector.t").Vector
local StaticGeometry = require("gfx/geometry.t").StaticGeometry
local vertexInfo = require("gfx/vertexdefs.t").createPosColorVertexInfo()

function makeCubeGeometry()
    local positions = {
                        Vector(-1.0,  1.0,  1.0),
                        Vector( 1.0,  1.0,  1.0),
                        Vector(-1.0, -1.0,  1.0),
                        Vector( 1.0, -1.0,  1.0),
                        Vector(-1.0,  1.0, -1.0),
                        Vector( 1.0,  1.0, -1.0),
                        Vector(-1.0, -1.0, -1.0),
                        Vector( 1.0, -1.0, -1.0)
                       }

    local colors = {
                        Vector( 0.0, 0.0, 0.0, 1.0),
                        Vector( 1.0, 0.0, 0.0, 1.0),
                        Vector( 0.0, 1.0, 0.0, 1.0),
                        Vector( 1.0, 1.0, 0.0, 1.0),
                        Vector( 0.0, 0.0, 1.0, 1.0),
                        Vector( 1.0, 0.0, 1.0, 1.0),
                        Vector( 0.0, 1.0, 1.0, 1.0),
                        Vector( 1.0, 1.0, 1.0, 1.0)    
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
    cubegeo:setAttribute("position", positions)
    cubegeo:setAttribute("color0", colors)
    cubegeo:build()
    return cubegeo
end

function init()
    log.info("cube.t init")
    sdl.trss_sdl_create_window(sdlPointer, width, height, '00 buffercube')
    initBGFX()
    local rendererType = bgfx.bgfx_get_renderer_type()
    local rendererName = ffi.string(bgfx.bgfx_get_renderer_name(rendererType))
    log.info("Renderer type: " .. rendererName)
end

width = 800
height = 600
frame = 0
time = 0.0

-- ok, I lied: we're going to use a tiny helper library to do the shader loading
-- because different platforms use different shaders

function loadProgram(vshadername, fshadername)
    local shaderutils = require('utils/shaderutils.t')
    return shaderutils.loadProgram(vshadername, fshadername)
end

-- ok, I lied a bit more: we're also going to use the matrix libary because
-- there's no point in cluttering up this with code that creates projection
-- matrices

function setViewMatrices()
    mtx = require("math/matrix.t")

    mtx.makeProjMat(projmat, 60.0, width / height, 0.01, 100.0)
    mtx.setIdentity(viewmat)

    bgfx.bgfx_set_view_transform(0, viewmat, projmat)
end

function updateEvents()
    local nevents = sdl.trss_sdl_num_events(sdlPointer)
    for i = 1,nevents do
        local evt = sdl.trss_sdl_get_event(sdlPointer, i-1)
        if evt.event_type == sdl.TRSS_SDL_EVENT_WINDOW and evt.flags == 14 then
            log.info("Received window close, stopping interpreter...")
            trss.trss_stop_interpreter(TRSS_ID)
        end
    end
end

function initBGFX()
    -- Basic init

    local debug = bgfx_const.BGFX_DEBUG_TEXT
    local reset = bgfx_const.BGFX_RESET_VSYNC + bgfx_const.BGFX_RESET_MSAA_X8

    bgfx.bgfx_init(bgfx.BGFX_RENDERER_TYPE_COUNT, 0, 0, nil, nil)
    bgfx.bgfx_reset(width, height, reset)

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
    program = loadProgram("vs_cubes", "fs_cubes")

    -- create matrices
    projmat = Matrix()
    viewmat = Matrix()
    modelmat = Matrix()
end

function drawCube()
    -- Set viewprojection matrix
    setViewMatrices()

    -- Render our cube
    bgfx.bgfx_set_transform(modelmat.data, 1) -- only one matrix in array
    cubegeo:bind()

    bgfx.bgfx_set_state(bgfx_const.BGFX_STATE_DEFAULT, 0)
    bgfx.bgfx_submit(0, program, 0)
end

terra calcDeltaTime(startTime: uint64)
    var curtime = trss.trss_get_hp_time()
    var freq = trss.trss_get_hp_freq()
    var deltaF : float = curtime - startTime
    return deltaF / [float](freq)
end

frametime = 0.0

function update()
    frame = frame + 1
    time = time + 1.0 / 60.0

    local startTime = trss.trss_get_hp_time()

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

    drawCube()

    -- Advance to next frame. Rendering thread will be kicked to
    -- process submitted rendering primitives.
    bgfx.bgfx_frame()

    frametime = calcDeltaTime(startTime)
end