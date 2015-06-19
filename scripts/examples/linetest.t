-- linetest.t
--
-- dynamic lines test

bgfx = libs.bgfx
bgfx_const = libs.bgfx_const
terralib = libs.terralib
trss = libs.trss
sdl = libs.sdl
sdlPointer = libs.sdlPointer
TRSS_ID = libs.TRSS_ID
nanovg = libs.nanovg

function init()
	trss.trss_log(TRSS_ID, "vgr_dev.t init")
	sdl.trss_sdl_create_window(sdlPointer, width, height, 'Very Good: Risky')
	initBGFX()
	local rendererType = bgfx.bgfx_get_renderer_type()
	local rendererName = ffi.string(bgfx.bgfx_get_renderer_name(rendererType))
	trss.trss_log(TRSS_ID, "Renderer type: " .. rendererName)
end

width = 1280
height = 720
frame = 0
time = 0.0
mousex, mousey = 0, 0

frametime = 0.0

objectmanager = truss_import("vgr/objectmanager.t")
simple_renderer = truss_import("renderers/simple_renderer.t")
matrixlib = truss_import("math/matrix.t")
quatlib = truss_import("math/quat.t")
local Matrix4 = matrixlib.Matrix4
local Quaternion = quatlib.Quaternion
local OrbitCam = truss_import("gui/orbitcam.t")
grid = truss_import("geometry/grid.t")
Line = truss_import("mesh/line.t")

function onTextInput(tstr)
	log("Text input: " .. tstr)
end

function onKeyDown(keyname, modifiers)
	log("Keydown: " .. keyname)
	if keyname == "F10" then
		takeScreenshot()
	end
end

function onKeyUp(keyname)
	-- nothing to do
end

screenshotid = 0
screenshotpath = ""

function takeScreenshot()
	local fn = screenshotpath .. "img_" .. screenshotid .. ".png"
	bgfx.bgfx_save_screen_shot(fn)
	screenshotid = screenshotid + 1
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
		elseif evt.event_type == sdl.TRSS_SDL_EVENT_TEXTINPUT then
			onTextInput(ffi.string(evt.keycode))
		elseif evt.event_type == sdl.TRSS_SDL_EVENT_WINDOW and evt.flags == 14 then
			trss.trss_log(0, "Received window close, stopping interpreter...")
			trss.trss_stop_interpreter(TRSS_ID)
		end
		orbitcam:updateFromSDL(evt)
	end
end

function log(msg)
	trss.trss_log(0, msg)
end

function updateCamera()
	orbitcam:update(1.0 / 60.0)
	renderer:setCameraTransform(orbitcam.mat)
end

function initBGFX()
	-- Basic init

	local debug = bgfx_const.BGFX_DEBUG_TEXT
	local reset = bgfx_const.BGFX_RESET_VSYNC + bgfx_const.BGFX_RESET_MSAA_X8
	--local reset = bgfx_const.BGFX_RESET_MSAA_X8

	bgfx.bgfx_init(bgfx.BGFX_RENDERER_TYPE_COUNT, 0, 0, nil, nil)
	bgfx.bgfx_reset(width, height, reset)

	-- Enable debug text.
	bgfx.bgfx_set_debug(debug)

	bgfx.bgfx_set_view_clear(0, 
	0x0001 + 0x0002, -- clear color + clear depth
	0x000011ff,
	1.0,
	0)

	trss.trss_log(0, "Initted bgfx I hope?")

	-- Init renderer
	renderer = simple_renderer.SimpleRenderer(width, height)

	-- create a line grid
	thegrid = grid.createLineGrid()
	renderer:add(thegrid)

	-- create the test line
	createLine()

	-- camera
	cammat = Matrix4():identity()
	camquat = Quaternion():identity()
	campos = {x = 0, y = 0, z = 0}
	orbitcam = OrbitCam()

end

frametime = 0.0
scripttime = 0.0

linefreq = 0.01
linespeed = 0.1
linepoints = {}
nlinepoints = 5000
theline = nil

function createLine()
	for i = 1,nlinepoints do
		table.insert(linepoints, {0,i*0.1,0})
	end
	theline = Line(#linepoints, true)
	theline:setPoints({linepoints})
	theline:createDefaultMaterial({1,0,0,1}, 0.1)
	renderer:add(theline)
end

function updateLine(t)
	for idx, pt in ipairs(linepoints) do
		r = idx * 0.001 + 0.3
		pt[1] = math.cos(2.0*idx*linefreq + t*linespeed) * r
		pt[2] = math.sin(3.0*idx*linefreq + t*linespeed) * r
		pt[3] = math.sin(5.0*idx*linefreq + t*linespeed) * r
	end
	theline:setPoints({linepoints})
end

function update()
	frame = frame + 1
	time = time + 1.0 / 60.0

	local startTime = tic()

	-- Deal with input and io events
	updateEvents()

	-- Set view 0,1 default viewport.
	bgfx.bgfx_set_view_rect(0, 0, 0, width, height)
	bgfx.bgfx_set_view_rect(1, 0, 0, width, height)

	-- This dummy draw call is here to make sure that view 0 is cleared
	-- if no other draw calls are submitted to view 0.
	bgfx.bgfx_submit(0, 0)

	-- Use debug font to print information about this example.
	bgfx.bgfx_dbg_text_clear(0, false)

	bgfx.bgfx_dbg_text_printf(0, 1, 0x4f, "vgr_dev.t")
	bgfx.bgfx_dbg_text_printf(0, 2, 0x6f, "total: " .. frametime*1000.0 .. " ms, script: " .. scripttime*1000.0 .. " ms")

	updateCamera()
	updateLine(time)
	renderer:render()

	scripttime = toc(startTime)

	-- Advance to next frame. Rendering thread will be kicked to
	-- process submitted rendering primitives.
	bgfx.bgfx_frame()

	frametime = toc(startTime)
end