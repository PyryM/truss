-- appscaffold.t
--
-- a basic app scaffold that does setup, event handling, etc.

local class = require('class')
local bgfx = core.bgfx
local bgfx_const = core.bgfx_const
local terralib = core.terralib
local truss = core.truss
local sdl = addons.sdl
local nanovg = core.nanovg

local math = require("math")
local gfx = require("gfx")

local AppScaffold = class('AppScaffold')

function AppScaffold:init(options)
    options = options or {}
    self.width = options.width or 1280
    self.height = options.height or 720
    self.quality = options.quality or 1.0 -- highest quality by default
    self.title = options.title or 'truss'

    self.frame = 0
    self.time = 0.0

    self.scripttime = 0.0
    self.frametime = 0.0

    self.downkeys = {}
    self.keybindings = {}

    log.info("AppScaffold init")
    sdl:createWindow(self.width, self.height, self.title)

    self:initBGFX()
    self:initPipeline()
    self:initScene()

    self.startTime = tic()
end

function AppScaffold:initBGFX()
    -- Basic init
    local debug = bgfx_const.BGFX_DEBUG_TEXT
    local reset = bgfx_const.BGFX_RESET_VSYNC + bgfx_const.BGFX_RESET_MSAA_X8
    --local reset = bgfx_const.BGFX_RESET_MSAA_X8

    --local cbInterfacePtr = sdl.truss_sdl_get_bgfx_cb(sdlPointer)
    local cbInterfacePtr = nil

    bgfx.bgfx_init(bgfx.BGFX_RENDERER_TYPE_COUNT, 0, 0, cbInterfacePtr, nil)
    bgfx.bgfx_reset(self.width, self.height, reset)

    -- Enable debug text.
    bgfx.bgfx_set_debug(debug)

    log.info("AppScaffold: initted bgfx")
    local rendererType = bgfx.bgfx_get_renderer_type()
    local rendererName = ffi.string(bgfx.bgfx_get_renderer_name(rendererType))
    log.info("Renderer type: " .. rendererName)
end

function AppScaffold:setDefaultLights()
    -- set default lights
    local Vector = math.Vector
    local forwardpass = self.forwardpass
    forwardpass.globals.lightDirs:setMultiple({
            Vector( 1.0,  1.0,  0.0),
            Vector(-1.0,  1.0,  0.0),
            Vector( 0.0, -1.0,  1.0),
            Vector( 0.0, -1.0, -1.0)})

    forwardpass.globals.lightColors:setMultiple({
            Vector(0.8, 0.8, 0.8),
            Vector(1.0, 1.0, 1.0),
            Vector(0.1, 0.1, 0.1),
            Vector(0.1, 0.1, 0.1)})
end

function AppScaffold:initPipeline()
    local pbr = require("shaders/pbr.t")

    self.pipeline = gfx.Pipeline()

    local backbuffer = gfx.RenderTarget(self.width, self.height):makeBackbuffer()
    local forwardpass = gfx.MultiShaderStage({
        renderTarget = backbuffer,
        clear = {color = 0x303030ff},
        shaders = {solid = pbr.PBRShader()}
    })
    self.forwardpass = forwardpass
    self.pipeline:add("forwardpass", forwardpass)
    self.pipeline:setupViews(0)

    self:setDefaultLights()
end

function AppScaffold:initScene()
    self.scene = gfx.Object3D()
    self.camera = gfx.Camera():makeProjection(70, self.width/self.height,
                                            0.1, 100.0)
end

function AppScaffold:onKeyDown_(keyname, modifiers)
    log.info("Keydown: " .. keyname .. " | " .. modifiers)
    if self.keybindings[keyname] ~= nil then
        self.keybindings[keyname](keyname, modifiers)
    end
end

function AppScaffold:setKeyBinding(keyname, func)
    self.keybindings[keyname] = func
end

function AppScaffold:onKey(keyname, func)
    self:setKeyBinding(keyname, func)
end

function AppScaffold:onMouseMove(func)
    self.mousemove = func
end

function AppScaffold:updateEvents()
    for evt in sdl:events() do
        if evt.event_type == sdl.EVENT_KEYDOWN or evt.event_type == sdl.EVENT_KEYUP then
            local keyname = ffi.string(evt.keycode)
            if evt.event_type == sdl.EVENT_KEYDOWN then
                if not self.downkeys[keyname] then
                    self.downkeys[keyname] = true
                    self:onKeyDown_(keyname, evt.flags)
                end
            else -- keyup
                self.downkeys[keyname] = false
            end
        elseif evt.event_type == sdl.EVENT_WINDOW and evt.flags == 14 then
            log.info("Received window close, stopping interpreter...")
            truss.truss_stop_interpreter(core.TRUSS_ID)
        end
        if self.userEventHandler then
            self:userEventHandler(evt)
        end
    end
end

function AppScaffold:updateScene()
    self.scene:updateMatrices()
end

function AppScaffold:render()
    self.pipeline:render({camera = self.camera,
                          scene  = self.scene})
end

function AppScaffold:update()
    self.frame = self.frame + 1
    self.time = self.time + 1.0 / 60.0

    -- Deal with input events
    self:updateEvents()

    -- Set view 0,1 default viewport.
    bgfx.bgfx_set_view_rect(0, 0, 0, self.width, self.height)
    bgfx.bgfx_set_view_rect(1, 0, 0, self.width, self.height)

    -- Touch the view to make sure it is cleared even if no draw
    -- calls happen
    -- bgfx.bgfx_touch(0)

    -- Use debug font to print information about this example.
    bgfx.bgfx_dbg_text_clear(0, false)
    bgfx.bgfx_dbg_text_printf(0, 1, 0x6f, "total: " .. self.frametime*1000.0
                                                    .. " ms, script: "
                                                    .. self.scripttime*1000.0
                                                    .. " ms")
    if self.preRender then
        self:preRender()
    end

    self:updateScene()
    self:render()
    self.scripttime = toc(self.startTime)

    -- Advance to next frame. Rendering thread will be kicked to
    -- process submitted rendering primitives.
    bgfx.bgfx_frame(false)

    self.frametime = toc(self.startTime)
    self.startTime = tic()
end

local m = {}
m.AppScaffold = AppScaffold
return m
