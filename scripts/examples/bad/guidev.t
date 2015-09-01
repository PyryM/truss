-- guidev.t
--
-- example of live-reloading for gui development

bgfx = core.bgfx
bgfx_const = core.bgfx_const
terralib = core.terralib
trss = core.trss
sdl = raw_addons.sdl.functions
sdlPointer = raw_addons.sdl.pointer
TRSS_ID = core.TRSS_ID
nanovg = core.nanovg

width = 1280
height = 720
frame = 0
time = 0.0
mousex, mousey = 0, 0

screenshotid = 0

function init()
	log.info("guidev.t init")
	sdl.trss_sdl_create_window(sdlPointer, width, height, 'TRUSS TEST')
	initBGFX()
	initNVG()
	local rendererType = bgfx.bgfx_get_renderer_type()
	local rendererName = ffi.string(bgfx.bgfx_get_renderer_name(rendererType))
	log.info("Renderer type: " .. rendererName)
end

function onKeyDown(keyname, modifiers)
	log.info("Keydown: " .. keyname)

	if keyname == "F10" then
		bgfx.bgfx_save_screen_shot("screenshot_" .. screenshotid .. ".png")
		screenshotid = screenshotid + 1
	end

	if keyname == "F5" then
		reloadModule()
	end
end

function onKeyUp(keyname)
	-- nothing to do
end

downkeys = {}

function updateEvents()
	local nevents = sdl.trss_sdl_num_events(sdlPointer)
	for i = 1,nevents do
		local evt = sdl.trss_sdl_get_event(sdlPointer, i-1)
		if evt.event_type == sdl.TRSS_SDL_EVENT_KEYDOWN or evt.event_type == sdl.TRSS_SDL_EVENT_KEYUP then
			local keyname = ffi.string(evt.keycode)
			if evt.event_type == sdl.TRSS_SDL_EVENT_KEYDOWN then
				if not downkeys[keyname] then
					downkeys[keyname] = true
					onKeyDown(keyname, evt.flags)
				end
			else -- keyup
				downkeys[keyname] = false
				onKeyUp(keyname)
			end
		elseif evt.event_type == sdl.TRSS_SDL_EVENT_WINDOW and evt.flags == 14 then
			log.info("Received window close, stopping interpreter...")
			trss.trss_stop_interpreter(TRSS_ID)
		end
	end
end

function initBGFX()
	local debug = bgfx_const.BGFX_DEBUG_TEXT
	local reset = bgfx_const.BGFX_RESET_VSYNC + bgfx_const.BGFX_RESET_MSAA_X8
	--local reset = bgfx_const.BGFX_RESET_MSAA_X8

	local cbInterfacePtr = sdl.trss_sdl_get_bgfx_cb(sdlPointer)

	bgfx.bgfx_init(bgfx.BGFX_RENDERER_TYPE_COUNT, 0, 0, cbInterfacePtr, nil)
	bgfx.bgfx_reset(width, height, reset)

	-- Enable debug text.
	bgfx.bgfx_set_debug(debug)

	bgfx.bgfx_set_view_clear(0, 
	0x0001 + 0x0002, -- clear color + clear depth
	0x000000ff,
	1.0,
	0)

	log.info("Initted bgfx I hope?")
end

function initNVG()
	-- create context, indicate to bgfx that drawcalls to view
	-- 0 should happen in the order that they were submitted
	nvg = nanovg.nvgCreate(1, 0) -- make sure to have antialiasing on
	bgfx.bgfx_set_view_seq(0, true)

	-- load font
	--nvgfont = nanovg.nvgCreateFont(nvg, "sans", "font/roboto-regular.ttf")
	nvgfont = nanovg.nvgCreateFont(nvg, "sans", "font/VeraMono.ttf")

	if gui and gui.init then
		gui.init(nvg, width, height)
	end
end

frametime = 0.0
scripttime = 0.0

guiSrc = "gui/futureplot.t"
gui = require(guiSrc)

function reloadModule()
	gui = require(guiSrc, true) -- force reload
	if gui and gui.init then
		gui.init(nvg, width, height)
	end
end

function drawNVG()
	nanovg.nvgBeginFrame(nvg, width, height, 1.0)

	if gui then
		gui.draw(nvg, width, height)
	end

	nanovg.nvgEndFrame(nvg)
end

-- converts a floating point value in seconds to
-- milliseconds, truncated to 3 decimal places
function to_ms(s)
	return math.floor(s * 1000000.0) / 1000.0
end

function update()
	frame = frame + 1
	time = time + frametime

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

	bgfx.bgfx_dbg_text_printf(0, 1, 0x4f, "scripts/examples/guidev.t")
	bgfx.bgfx_dbg_text_printf(0, 2, 0x6f, "ft: " .. to_ms(frametime) .. " ms, st: " .. to_ms(scripttime) .. " ms")

	drawNVG()

	scripttime = toc(startTime)

	-- Advance to next frame. Rendering thread will be kicked to
	-- process submitted rendering primitives.
	bgfx.bgfx_frame()

	frametime = toc(startTime)
end