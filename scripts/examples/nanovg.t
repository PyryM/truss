-- nanovg.t
--
-- example of using nanovg

bgfx = libs.bgfx
bgfx_const = libs.bgfx_const
terralib = libs.terralib
trss = libs.trss
sdl = libs.sdl
sdlPointer = libs.sdlPointer
TRSS_ID = libs.TRSS_ID
nanovg = libs.nanovg

width = 800
height = 600
frame = 0
time = 0.0
mousex, mousey = 0, 0

function init()
	trss.trss_log(TRSS_ID, "nanovg.t init")
	sdl.trss_sdl_create_window(sdlPointer, width, height, 'TRUSS TEST')
	initBGFX()
	initNVG()
	local rendererType = bgfx.bgfx_get_renderer_type()
	local rendererName = ffi.string(bgfx.bgfx_get_renderer_name(rendererType))
	trss.trss_log(TRSS_ID, "Renderer type: " .. rendererName)
end

mtx = truss_import("math/matrix.t")

function setViewMatrices()
	mtx.makeProjMat(projmat, 60.0, width / height, 0.01, 100.0)
	mtx.setIdentity(viewmat)

	bgfx.bgfx_set_view_transform(0, viewmat, projmat)
end

function updateEvents()
	local nevents = sdl.trss_sdl_num_events(sdlPointer)
	for i = 1,nevents do
		local evt = sdl.trss_sdl_get_event(sdlPointer, i-1)
		if evt.event_type == sdl.TRSS_SDL_EVENT_MOUSEMOVE then
			mousex = evt.x
			mousey = evt.y
		elseif evt.event_type == sdl.TRSS_SDL_EVENT_WINDOW and evt.flags == 14 then
			trss.trss_log(TRSS_ID, "Received window close, stopping interpreter...")
			trss.trss_stop_interpreter(TRSS_ID)
		end
	end
end

function log(msg)
	trss.trss_log(TRSS_ID, msg)
end

function initBGFX()
	-- Basic init

	local debug = bgfx_const.BGFX_DEBUG_TEXT
	local reset = bgfx_const.BGFX_RESET_VSYNC + bgfx_const.BGFX_RESET_MSAA_X8

	bgfx.bgfx_init(7, 0, 0, nil, nil)
	bgfx.bgfx_reset(width, height, reset)

	-- Enable debug text.
	bgfx.bgfx_set_debug(debug)

	bgfx.bgfx_set_view_clear(0, 
	0x0001 + 0x0002, -- clear color + clear depth
	0x303030ff,
	1.0,
	0)

	trss.trss_log(0, "Initted bgfx I hope?")
end

function initNVG()
	-- create context, indicate to bgfx that drawcalls to view
	-- 0 should happen in the order that they were submitted
	nvg = nanovg.nvgCreate(1, 0)
	bgfx.bgfx_set_view_seq(0, true)

	-- load font
	nvgfont = nanovg.nvgCreateFont(nvg, "sans", "font/roboto-regular.ttf")
end

frametime = 0.0

lines = {"this is a set of text lines",
		 "here is the next one",
		 "woo yay",
		 "text"}

function drawNVG()
		nanovg.nvgBeginFrame(nvg, width, height, 1.0)

		nanovg.nvgSave(nvg)
		nanovg.nvgBeginPath(nvg)
		--nanovg.nvgRect(nvg, 100, 100, width-200, height-200)
		nanovg.nvgCircle(nvg, 100, 100, 100)
		local color = nanovg.nvgRGBA(128,128,128,128)
		nanovg.nvgFillColor(nvg, color)
		nanovg.nvgFill(nvg)
		nanovg.nvgRestore(nvg)

		nanovg.nvgSave(nvg)
		nanovg.nvgFontFace(nvg, "sans");
		local lineheight = 15
		local x0 = 30
		local y0 = 100
		local nlines = #lines
		for i = 1,nlines do
			local y = y0 + lineheight * (i-1)
			nanovg.nvgText(nvg, x0, y, lines[i], nil)
		end
		nanovg.nvgRestore(nvg)

		nanovg.nvgEndFrame(nvg)
end

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

	drawNVG()

	-- Advance to next frame. Rendering thread will be kicked to
	-- process submitted rendering primitives.
	bgfx.bgfx_frame()

	frametime = toc(startTime)
end