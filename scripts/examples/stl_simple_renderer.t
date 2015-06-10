-- stl_simple_renderer.t
--
-- example of using renderers/simple_renderer.t
-- to render a bunch of stl models

bgfx = libs.bgfx
bgfx_const = libs.bgfx_const
terralib = libs.terralib
trss = libs.trss
sdl = libs.sdl
sdlPointer = libs.sdlPointer
nvgAddonPointer = libs.nvgAddonPointer
nvgUtils = libs.nvgUtils
TRSS_ID = libs.TRSS_ID
nanovg = libs.nanovg

function init()
	trss.trss_log(TRSS_ID, "stl_simple_renderer.t init")
	sdl.trss_sdl_create_window(sdlPointer, width, height, 'TRUSS TEST')
	initBGFX()
	local rendererType = bgfx.bgfx_get_renderer_type()
	local rendererName = ffi.string(bgfx.bgfx_get_renderer_name(rendererType))
	trss.trss_log(TRSS_ID, "Renderer type: " .. rendererName)
end

width = 800
height = 600
frame = 0
time = 0.0
mousex, mousey = 0, 0

frametime = 0.0

stlloader = truss_import("loaders/stlloader.t")
objloader = truss_import("loaders/objloader.t")
meshutils = truss_import("mesh/mesh.t")
textureutils = truss_import("utils/textureutils.t")
simple_renderer = truss_import("renderers/simple_renderer.t")

screenshotid = 0

function updateEvents()
	local nevents = sdl.trss_sdl_num_events(sdlPointer)
	for i = 1,nevents do
		local evt = sdl.trss_sdl_get_event(sdlPointer, i-1)
		if evt.event_type == sdl.TRSS_SDL_EVENT_MOUSEMOVE then
			mousex = evt.x
			mousey = evt.y
		elseif evt.event_type == sdl.TRSS_SDL_EVENT_KEYDOWN or evt.event_type == sdl.TRSS_SDL_EVENT_KEYUP then
			local sname = "up"
			if evt.event_type == sdl.TRSS_SDL_EVENT_KEYDOWN then
				bgfx.bgfx_save_screen_shot("screenshot_" .. screenshotid .. ".png")
				screenshotid = screenshotid + 1
				sname = "down" 
			end
			trss.trss_log(0, "Key event: " .. sname .. " " .. ffi.string(evt.keycode))
			trss.trss_log(0, "x: " .. evt.x .. ", y: " .. evt.y .. ", flags: " .. evt.flags)
		elseif evt.event_type == sdl.TRSS_SDL_EVENT_WINDOW and evt.flags == 14 then
			trss.trss_log(TRSS_ID, "Received window close, stopping interpreter...")
			trss.trss_stop_interpreter(TRSS_ID)
		end
	end
end

function log(msg)
	trss.trss_log(0, msg)
end

function initBGFX()
	-- Basic init

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

	trss.trss_log(0, "Initted bgfx I hope?")

	-- Init renderer
	renderer = simple_renderer.SimpleRenderer(width, height)

	-- Load in depth program
	renderer:setProgram("vs_depth", "fs_depth")
	renderer:setTexProgram("vs_depth", "fs_depth")

	-- Load the model
	objloader.verbose = true
	stlloader.verbose = true

	modeldata = objloader.loadOBJ("temp/meshes/segway_wheel_right.obj", false) -- don't invert windings
	--modeldata = stlloader.loadSTL("models/arm_fixed.stl", false) -- don't invert windings
	--modeldata = objloader.loadOBJ("models/arm_fixed.obj", false)

	modeltex = textureutils.loadTexture("temp/test.jpg")
	trss.trss_log(0, "Texture handle idx: " .. modeltex.idx)

	wheelgeo = meshutils.Geometry():fromData(renderer.vertexInfo, modeldata)
	wheelmat = {texture = modeltex} -- nothing in materials at the moment
	--wheelmat = {}

	-- make some wheels
	wheels = {}
	for i = 1,10 do
		local wheel = meshutils.Mesh(wheelgeo, wheelmat)
		wheel.position.z = math.random()*2 - 2
		wheel.position.y = math.random()*2 - 1
		wheel.position.x = math.random()*2 - 1
		--wheel.scale.x = 100
		--wheel.scale.y = 100
		--wheel.scale.z = 100
		wheel.dx = math.random() -- we're just storing our own values
		wheel.dy = math.random() -- on the object, because why not
		wheel.dz = math.random()
		renderer:add(wheel)
		wheels[i] = wheel
	end
end

frametime = 0.0

function update()
	frame = frame + 1
	time = time + 1.0 / 60.0

	local startTime = tic()

	-- Deal with input events
	updateEvents()

	-- Set view 0,1 default viewport.
	bgfx.bgfx_set_view_rect(0, 0, 0, width, height)
	bgfx.bgfx_set_view_rect(1, 0, 0, width, height)

	-- This dummy draw call is here to make sure that view 0 is cleared
	-- if no other draw calls are submitted to view 0.
	bgfx.bgfx_submit(0, 0)

	-- Use debug font to print information about this example.
	bgfx.bgfx_dbg_text_clear(0, false)

	bgfx.bgfx_dbg_text_printf(0, 1, 0x4f, "scripts/examples/stl_simple_renderer.t")
	bgfx.bgfx_dbg_text_printf(0, 2, 0x6f, "frame time: " .. frametime*1000.0 .. " ms")

	-- make the wheels rotate
	for i, wheel in ipairs(wheels) do
		local rot = {x = wheel.dx * time,
					 y = wheel.dy * time,
					 z = wheel.dz * time}
		wheel.quaternion:fromEuler(rot, 'ZYX')
	end

	renderer:render()

	-- Advance to next frame. Rendering thread will be kicked to
	-- process submitted rendering primitives.
	bgfx.bgfx_frame()

	frametime = toc(startTime)
end