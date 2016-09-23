-- appscaffold.t
--
-- a basic app scaffold that does setup, event handling, etc.

local class = require('class')
local sdl = truss.addons.sdl

local math = require("math")
local gfx = require("gfx")

local AppScaffold = class('AppScaffold')

function AppScaffold:init(options)
    options = options or {}
    self.width = options.width or 1280
    self.height = options.height or 720
    self.quality = options.quality or 1.0 -- highest quality by default
    self.title = options.title or 'truss'
    self.fullscreen = options.fullscreen
    self.debugtext = options.debugtext ~= false
    self.vsync = options.vsync ~= false
    self.msaa = options.msaa ~= false
    self.clearcolor = options.clearcolor or 0x303030ff
    self.consoleOnError = options.consoleOnError
    if self.consoleOnError ~= false then
        self:installFallback()
    end
    if options.renderer then
        self.requestedRenderer = string.upper(options.renderer)
    end
    self.nvgoptions = options.nvgoptions

    self.frame = 0
    self.time = 0.0

    self.scripttime = 0.0
    self.frametime = 0.0

    self.downkeys = {}
    self.keybindings = {}

    log.info("AppScaffold init")
    if self.fullscreen then
        sdl:createWindow(320, 320, self.title, 1)
        self.width = sdl:windowWidth()
        self.height = sdl:windowHeight()
        log.info("Fullscreen dimensions: " .. self.width .. " x " .. self.height)
    else
        sdl:createWindow(self.width, self.height, self.title, 0)
    end

    self:initBGFX()
    self:initPipeline()
    self:initScene()

    self.startTime = truss.tic()
end

function AppScaffold:installFallback()
    if truss.mainEnv.fallbackUpdate then
        log.info("AppScaffold:installFallback : fallback already present.")
        return
    end

    local closureSelf = self
    truss.mainEnv.fallbackUpdate = function()
        closureSelf:fallbackUpdate()
    end
end

function AppScaffold:initBGFX()
    -- Basic init
    local debug = 0
    if self.debugtext then
        debug = debug + bgfx_const.BGFX_DEBUG_TEXT
    end
    local reset = 0
    if self.vsync then
        reset = reset + bgfx_const.BGFX_RESET_VSYNC
    end
    if self.msaa then
        reset = reset + bgfx_const.BGFX_RESET_MSAA_X8
    end
    --local reset = bgfx_const.BGFX_RESET_MSAA_X8

    local cbInterfacePtr = sdl:getBGFXCallback()
    local rendererType = bgfx.BGFX_RENDERER_TYPE_COUNT
    if self.requestedRenderer then
        local rname = "BGFX_RENDERER_TYPE_" .. self.requestedRenderer
        rendererType = bgfx[rname]
    end

    bgfx.bgfx_init(rendererType, 0, 0, cbInterfacePtr, nil)
    bgfx.bgfx_reset(self.width, self.height, reset)
    self.bgfxInitted = true

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
        clear = {color = self.clearcolor},
        shaders = {solid = pbr.PBRShader()}
    })
    self.forwardpass = forwardpass
    self.pipeline:add("forwardpass", forwardpass)
    if self.nvgoptions then
        self.nvgpass = gfx.NanoVGStage({
            draw = self.nvgoptions.draw,
            setup = self.nvgoptions.setup,
            renderTarget = backbuffer,
            clear = false
        })
        self.pipeline:add("nvgpass", self.nvgpass)
    end
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

function AppScaffold:takeScreenshot(filename)
    bgfx.bgfx_save_screen_shot(filename)
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
            log.info("Received window close, quitting...")
            truss.quit()
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

function AppScaffold:drawDebugText()
    if not self.debugtext then return end
    -- Use debug font to print information about this example.
    bgfx.bgfx_dbg_text_clear(0, false)
    bgfx.bgfx_dbg_text_printf(0, 1, 0x6f, "total: " .. self.frametime*1000.0
                                                    .. " ms, script: "
                                                    .. self.scripttime*1000.0
                                                    .. " ms")
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
    self:drawDebugText()

    if self.preRender then
        self:preRender()
    end

    self:updateScene()
    self:render()
    self.scripttime = truss.toc(self.startTime)

    -- Advance to next frame. Rendering thread will be kicked to
    -- process submitted rendering primitives.
    bgfx.bgfx_frame(false)

    self.frametime = truss.toc(self.startTime)
    self.startTime = truss.tic()
end

function AppScaffold:attachWebconsole()
    if self.webconsole then return true end
    local webconsole = require("devtools/webconsole.t")
    if webconsole then
        local connected = webconsole.start()
        if connected then
            self.webconsole = webconsole
            return true
        else
            return false, "connection error"
        end
    else
        return false, "devtools/webconsole.t not present"
    end
end

function AppScaffold:fallbackUpdate()
    if not self.bgfxInitted then
        log.info("Crash before bgfx init; no choice but to quit.")
        truss.quit()
    end

    if not self._inittedFallback then
        self.fbBackBuffer = terralib.new(bgfx.bgfx_frame_buffer_handle_t)
        self.fbBackBuffer.idx = bgfx.BGFX_INVALID_HANDLE
        bgfx.bgfx_set_view_rect(0, 0, 0, self.width, self.height)
        bgfx.bgfx_set_view_clear(0, -- viewid 0
                bgfx_const.BGFX_CLEAR_COLOR + bgfx_const.BGFX_CLEAR_DEPTH,
                0x000000ff, -- clearcolor (black)
                1.0, -- cleardepth (in normalized space: 1.0 = max depth)
                0)
        bgfx.bgfx_set_view_frame_buffer(0, self.fbBackBuffer)
        bgfx.bgfx_set_debug(bgfx_const.BGFX_DEBUG_TEXT)
        local text = {{">>>>>>>>>>>>> CRASH <<<<<<<<<<<<<", 0x83}}
        if self.consoleOnError == "remote" then
            local happy, msg = self:attachWebconsole()
            if happy then msg = "Webconsole connected" end
            table.insert(text, {msg, 0x6f})
        elseif self.consoleOnError ~= false then
            -- local console
            self.fbMiniconsole = require("devtools/miniconsole.t")
            self.fbMiniconsole.init(math.floor(self.width / 8),
                                    math.floor(self.height / 16))
            self.fbMiniconsole.setHeader("Something broke: " .. truss.crashMessage, 0x83)
            self.fbMiniconsole.printMiniHelp()
        else
            table.insert(text, {"Pass 'consoleOnError = true' to AppScaffold to enable debug console.", 0x6f})
        end
        table.insert(text, {truss.crashMessage or "unspecified crash", 0x83})
        self.fbTextLines = text
        self._inittedFallback = true
    end

    if self.webconsole then self.webconsole.update() end
    if self.fbMiniconsole then -- miniconsole will take care of sdl events
        self.fbMiniconsole.update()
    else
        local sdl = truss.addons.sdl
        for evt in sdl:events() do
            if evt.event_type == sdl.EVENT_WINDOW and evt.flags == 14 then
                truss.quit()
            end
        end
        bgfx.bgfx_dbg_text_clear(0, false)
        for i, line in ipairs(self.fbTextLines) do
            local text, color = unpack(line)
            bgfx.bgfx_dbg_text_printf(1, i+1, color or 0x6f, text)
        end
        bgfx.bgfx_touch(0)
        bgfx.bgfx_frame(false)
    end
end

local m = {}
m.AppScaffold = AppScaffold
return m
