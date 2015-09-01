-- appscaffold.t
--
-- a basic app scaffold that does setup, event handling, etc.

local class = require('class')
local bgfx = core.bgfx
local bgfx_const = core.bgfx_const
local terralib = core.terralib
local trss = core.trss
local sdl = raw_addons.sdl.functions
local sdlPointer = raw_addons.sdl.pointer
local TRSS_ID = core.TRSS_ID
local nanovg = core.nanovg

local AppScaffold = class('AppScaffold')

pbr_renderer = require("renderers/pbr_renderer.t")

function AppScaffold:init(options)
	options = options or {}
	self.width = options.width or 1280
	self.height = options.height or 720
	self.quality = options.quality or 1.0 -- highest quality by default
	self.title = options.title or 'truss'

	local usenvg = (options.usenvg == nil) or options.usenvg

	self.frame = 0
	self.time = 0.0

	self.scripttime = 0.0
	self.frametime = 0.0

	self.downkeys = {}
	self.keybindings = {}

	log.info("AppScaffold init")
	sdl.trss_sdl_create_window(sdlPointer, 
								self.width, self.height, 
								self.title)
	self:initBGFX()
	if usenvg then
		self:initNVG()
	end
	local rendererType = bgfx.bgfx_get_renderer_type()
	local rendererName = ffi.string(bgfx.bgfx_get_renderer_name(rendererType))
	log.info("Renderer type: " .. rendererName)

	-- Init renderer
	if options.renderer == nil then
		self.renderer = pbr_renderer.PBRRenderer(self.width, self.height)
		self.renderer:setQuality(self.quality)
		self.renderer.autoUpdateMatrices = false
	else
		self.renderer = options.renderer
	end
end

function AppScaffold:initBGFX()
	-- Basic init
	local debug = bgfx_const.BGFX_DEBUG_TEXT
	local reset = bgfx_const.BGFX_RESET_VSYNC + bgfx_const.BGFX_RESET_MSAA_X8
	--local reset = bgfx_const.BGFX_RESET_MSAA_X8

	local cbInterfacePtr = sdl.trss_sdl_get_bgfx_cb(sdlPointer)

	bgfx.bgfx_init(bgfx.BGFX_RENDERER_TYPE_COUNT, 0, 0, cbInterfacePtr, nil)
	bgfx.bgfx_reset(self.width, self.height, reset)

	-- Enable debug text.
	bgfx.bgfx_set_debug(debug)

	bgfx.bgfx_set_view_clear(0, 
	0x0001 + 0x0002, -- clear color + clear depth
	0x303030ff,
	1.0,
	0)

	log.info("AppScaffold: initted bgfx")
end

function AppScaffold:initNVG()
	-- create context, indicate to bgfx that drawcalls to view
	-- 0 should happen in the order that they were submitted
	self.nvg = nanovg.nvgCreate(1, 1) -- make sure to have antialiasing on
	bgfx.bgfx_set_view_seq(1, true)

	-- load font
	--nvgfont = nanovg.nvgCreateFont(nvg, "sans", "font/roboto-regular.ttf")
	self.nvgfont = nanovg.nvgCreateFont(self.nvg, "sans", "font/VeraMono.ttf")
end

function AppScaffold:onKeyDown(keyname, modifiers)
	log.info("Keydown: " .. keyname)
	if self.keybindings[keyname] ~= nil then
		self.keybindings[keyname](keyname, modifiers)
	end
end

function AppScaffold:setKeyBinding(keyname, func)
	self.keybindings[keyname] = func
end

function AppScaffold:setEventHandler(func)
	self.userEventHandler = func
end

function AppScaffold:updateEvents()
	local nevents = sdl.trss_sdl_num_events(sdlPointer)
	for i = 1,nevents do
		local evt = sdl.trss_sdl_get_event(sdlPointer, i-1)
		if evt.event_type == sdl.TRSS_SDL_EVENT_KEYDOWN or evt.event_type == sdl.TRSS_SDL_EVENT_KEYUP then
			local keyname = ffi.string(evt.keycode)
			if evt.event_type == sdl.TRSS_SDL_EVENT_KEYDOWN then
				if not self.downkeys[keyname] then
					self.downkeys[keyname] = true
					self:onKeyDown(keyname, evt.flags)
				end
			else -- keyup
				self.downkeys[keyname] = false
			end
		elseif evt.event_type == sdl.TRSS_SDL_EVENT_WINDOW and evt.flags == 14 then
			log.info("Received window close, stopping interpreter...")
			trss.trss_stop_interpreter(TRSS_ID)
		end
		if self.userEventHandler then
			self.userEventHandler(evt)
		end
	end
end

function AppScaffold:update(userupdate)
	self.frame = self.frame + 1
	self.time = self.time + 1.0 / 60.0

	local startTime = tic()

	-- Deal with input events
	self:updateEvents()

	-- Set view 0,1 default viewport.
	bgfx.bgfx_set_view_rect(0, 0, 0, self.width, self.height)
	bgfx.bgfx_set_view_rect(1, 0, 0, self.width, self.height)

	-- This dummy draw call is here to make sure that view 0 is cleared
	-- if no other draw calls are submitted to view 0.
	bgfx.bgfx_submit(0, 0)

	-- Use debug font to print information about this example.
	bgfx.bgfx_dbg_text_clear(0, false)

	bgfx.bgfx_dbg_text_printf(0, 1, 0x6f, "total: " .. self.frametime*1000.0 
													.. " ms, script: " 
													.. self.scripttime*1000.0 
													.. " ms")
	if userupdate then
		userupdate()
	end

	self.renderer:render()

	self.scripttime = toc(startTime)

	-- Advance to next frame. Rendering thread will be kicked to
	-- process submitted rendering primitives.
	bgfx.bgfx_frame()

	self.frametime = toc(startTime)
end

local m = {}
m.AppScaffold = AppScaffold
return m