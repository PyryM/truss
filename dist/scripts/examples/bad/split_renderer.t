-- stl_simple_renderer.t
--
-- example of using renderers/simple_renderer.t
-- to render a bunch of stl models

bgfx = libs.bgfx
bgfx_const = libs.bgfx_const
terralib = libs.terralib
truss = libs.truss
sdl = libs.sdl
sdlPointer = libs.sdlPointer
nvgAddonPointer = libs.nvgAddonPointer
nvgUtils = libs.nvgUtils
TRUSS_ID = libs.TRUSS_ID
nanovg = libs.nanovg

function init()
	truss.truss_log(TRUSS_ID, "split_renderer.t init")
	sdl.truss_sdl_create_window(sdlPointer, width, height, 'TRUSS TEST')
	initBGFX()
	local rendererType = bgfx.bgfx_get_renderer_type()
	local rendererName = ffi.string(bgfx.bgfx_get_renderer_name(rendererType))
	truss.truss_log(TRUSS_ID, "Renderer type: " .. rendererName)
end

width = 1024
height = 512
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
	local nevents = sdl.truss_sdl_num_events(sdlPointer)
	for i = 1,nevents do
		local evt = sdl.truss_sdl_get_event(sdlPointer, i-1)
		if evt.event_type == sdl.TRUSS_SDL_EVENT_MOUSEMOVE then
			mousex = evt.x
			mousey = evt.y
		elseif evt.event_type == sdl.TRUSS_SDL_EVENT_KEYDOWN or evt.event_type == sdl.TRUSS_SDL_EVENT_KEYUP then
			local sname = "up"
			if evt.event_type == sdl.TRUSS_SDL_EVENT_KEYDOWN then
				bgfx.bgfx_save_screen_shot("screenshot_" .. screenshotid .. ".png")
				screenshotid = screenshotid + 1
				sname = "down" 
			end
			truss.truss_log(0, "Key event: " .. sname .. " " .. ffi.string(evt.keycode))
			truss.truss_log(0, "x: " .. evt.x .. ", y: " .. evt.y .. ", flags: " .. evt.flags)
		elseif evt.event_type == sdl.TRUSS_SDL_EVENT_WINDOW and evt.flags == 14 then
			truss.truss_log(TRUSS_ID, "Received window close, stopping interpreter...")
			truss.truss_stop_interpreter(TRUSS_ID)
		end
	end
end

function log(msg)
	truss.truss_log(0, msg)
end

function initBGFX()
	-- Basic init

	local debug = bgfx_const.BGFX_DEBUG_TEXT
	local reset = bgfx_const.BGFX_RESET_VSYNC -- antialiasing will distort depth encoding
	--local reset = bgfx_const.BGFX_RESET_VSYNC + bgfx_const.BGFX_RESET_MSAA_X8
	--local reset = bgfx_const.BGFX_RESET_MSAA_X8

	local cbInterfacePtr = sdl.truss_sdl_get_bgfx_cb(sdlPointer)

	bgfx.bgfx_init(bgfx.BGFX_RENDERER_TYPE_COUNT, 0, 0, cbInterfacePtr, nil)
	bgfx.bgfx_reset(width, height, reset)

	-- Enable debug text.
	bgfx.bgfx_set_debug(debug)

	bgfx.bgfx_set_view_clear(0, 
	0x0001 + 0x0002, -- clear color + clear depth
	0x303030ff,
	1.0,
	0)

	bgfx.bgfx_set_view_clear(1, 
	0x0001 + 0x0002, -- clear depth
	0x000000ff,
	1.0,
	0)

	truss.truss_log(0, "Initted bgfx I hope?")

	-- Init renderers
	leftrenderer = simple_renderer.SimpleRenderer(width/2, height)
	rightrenderer = simple_renderer.SimpleRenderer(width/2, height)
	leftrenderer.viewid = 0

	-- Tweak right renderer: depth program,
	--                       no matrix updates (left renderer will do that)
	--                       viewid = 1
	rightrenderer:setProgram("vs_depth", "fs_depth_mono")
	rightrenderer:setTexProgram("vs_depth", "fs_depth_mono")
	rightrenderer.viewid = 1
	--rightrenderer.autoUpdateMatrices = false

	-- Load the model
	objloader.verbose = true
	stlloader.verbose = true

	modeldata = objloader.loadOBJ("temp/meshes/herb_base.obj", false) -- don't invert windings
	--modeldata = stlloader.loadSTL("models/arm_fixed.stl", false) -- don't invert windings
	--modeldata = objloader.loadOBJ("models/arm_fixed.obj", false)

	modeltex = textureutils.loadTexture("temp/herb_base.jpg")
	truss.truss_log(0, "Texture handle idx: " .. modeltex.idx)

	wheelgeo = meshutils.Geometry():fromData(leftrenderer.vertexInfo, modeldata)
	wheelmat = {texture = modeltex} -- nothing in materials at the moment
	--wheelmat = {}

	-- make some wheels
	wheels = {}
	for i = 1,10 do
		local wheel = meshutils.Mesh(wheelgeo, wheelmat)
		wheel.position.z = -math.random()*2
		wheel.position.y = (math.random()*2 - 1) * 0.5
		wheel.position.x = (math.random()*2 - 1) * 0.5
		wheel.scale.x = 50
		wheel.scale.y = 50
		wheel.scale.z = 50
		wheel.dx = math.random() -- we're just storing our own values
		wheel.dy = math.random() -- on the object, because why not
		wheel.dz = math.random()
		-- simplerenderer just stores references, so we can safely do this
		leftrenderer:add(wheel)
		rightrenderer:add(wheel)
		wheels[i] = wheel
	end
end

frametime = 0.0

function render()
	-- set up splitscreen viewports
	local w2 = width / 2

	bgfx.bgfx_set_view_rect(0,  0, 0, w2, height)
	bgfx.bgfx_set_view_rect(1, w2, 0, w2, height)

	-- Use debug font to print information about this example.
	bgfx.bgfx_dbg_text_clear(0, false)

	bgfx.bgfx_dbg_text_printf(0, 1, 0x4f, "scripts/examples/split_renderer.t")
	bgfx.bgfx_dbg_text_printf(0, 2, 0x6f, "frame time: " .. frametime*1000.0 .. " ms")

	-- do actual rendering
	leftrenderer:render()
	rightrenderer:render()
end

function update()
	frame = frame + 1
	time = time + 1.0 / 60.0

	local startTime = tic()

	-- Deal with input events
	updateEvents()

	-- make the wheels rotate
	for i, wheel in ipairs(wheels) do
		local rot = {x = wheel.dx * time,
					 y = wheel.dy * time,
					 z = wheel.dz * time}
		wheel.quaternion:fromEuler(rot, 'ZYX')
	end

	render()

	-- Advance to next frame. Rendering thread will be kicked to
	-- process submitted rendering primitives.
	bgfx.bgfx_frame()

	frametime = toc(startTime)
end