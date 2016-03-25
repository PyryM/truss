-- 05_line.t
-- 
-- tests line object

bgfx = core.bgfx
bgfx_const = core.bgfx_const
terralib = core.terralib
trss = core.trss
sdl = addons.sdl

local math = require("math")
local Vector = math.Vector
local Matrix4 = math.Matrix4
local Quaternion = math.Quaternion
local debugcube = require("geometry/debugcube.t")
local shaderutils = require('utils/shaderutils.t')
local Object3D = require('gfx/object3d.t').Object3D
local StaticGeometry = require("gfx/geometry.t").StaticGeometry
local Camera = require("gfx/camera.t").Camera
local line = require("geometry/line.t")
local MultiPass = require("gfx/multipass.t").MultiPass

width = 1280
height = 720
time = 0.0

function updateEvents()
    for evt in sdl:events() do
        if evt.event_type == sdl.EVENT_WINDOW and evt.flags == 14 then
            log.info("Received window close, stopping interpreter...")
            trss.trss_stop_interpreter(core.TRSS_ID)
        end
    end
end

function setupPipeline()
    renderpass = MultiPass()

    local pbrshader = require("shaders/pbr.t").PBRShader()
    renderpass:addShader("solid", pbrshader)

    local lineshader = line.LineShader()
    renderpass:addShader("line", lineshader)

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


-- actually creates the cube structure
function createLineThing()
    -- create a dummy object to move the whole stack in front of the camera
    local rootobj = Object3D()
    rootobj.name = "rootobj"
    rootobj.position:set(0.0, 0.0, 0.0)
    rootobj:updateMatrix()
    sg = rootobj
    rotator = Object3D()
    rootobj:add(rotator)
    rotator:add(camera)
    camera.position:set(0.0, 0.0, 10.0)
    camera:updateMatrix()

    local npoints = 200
    local isDynamic = false

    local lineobj = line.LineObject(npoints, isDynamic)
    local f = 5 * math.pi * 2.0

    local linedata = {}
    for i = 1,npoints do
        local t = (i-1) / (npoints-1)
        local x = math.cos(t * f) * t * 3.0
        local y = math.sin(t * f) * t * 3.0
        local z = t * 3.0
        linedata[i] = {x,y,z}
    end

    lineobj:setPoints({linedata})
    lineobj.position:set(0.0, 0.0, 0.0)
    lineobj.material.thickness:set(0.1)
    rootobj:add(lineobj)
end

function init()
    log.info("main script init")
    sdl:createWindow(width, height, '05: Line')
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

    -- create pipeline
    setupPipeline()

    -- create camera
    camera = Camera():makeProjection(70, width/height, 0.1, 100.0)

    -- create and populate scenegraph
    createLineThing()
end

function updateAndDraw()
    rotator.quaternion:fromEuler({x=0,y=time*0.25,z=0})
    rotator:updateMatrix()
    sg:updateMatrices()
    renderpass:render({camera = camera, scene = sg})
end

frametime = 0.0

function update()
    time = time + 1.0 / 60.0

    local startTime = tic()

    -- Deal with input events
    updateEvents()

    -- Set view 0 default viewport.
    bgfx.bgfx_set_view_rect(0, 0, 0, width, height)

    -- Use debug font to print information about this example.
    bgfx.bgfx_dbg_text_clear(0, false)

    bgfx.bgfx_dbg_text_printf(0, 1, 0x4f, "scripts/examples/01_raw_scenegraph.t")
    bgfx.bgfx_dbg_text_printf(0, 2, 0x6f, "frame time: " .. frametime*1000.0 .. " ms")

    -- update and draw cubes
    updateAndDraw()

    -- Advance to next frame. Rendering thread will be kicked to
    -- process submitted rendering primitives.
    bgfx.bgfx_frame()

    frametime = toc(startTime)
end