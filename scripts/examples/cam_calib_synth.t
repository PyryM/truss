-- cam_calib_synth.t
--
-- example of using renderers/simple_renderer.t
-- to render synthetic data for camera calibration

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
	trss.trss_log(TRSS_ID, "cam_calib_synth.t init")
	sdl.trss_sdl_create_window(sdlPointer, width, totalheight, 'TRUSS TEST')
	initBGFX()
	initNVG()
	local rendererType = bgfx.bgfx_get_renderer_type()
	local rendererName = ffi.string(bgfx.bgfx_get_renderer_name(rendererType))
	trss.trss_log(TRSS_ID, "Renderer type: " .. rendererName)
end

width = 1024
viewheight = 512
totalheight = 550
frame = 0
time = 0.0
mousex, mousey = 0, 0

frametime = 0.0

stlloader = truss_import("loaders/stlloader.t")
objloader = truss_import("loaders/objloader.t")
meshutils = truss_import("mesh/mesh.t")
textureutils = truss_import("utils/textureutils.t")
simple_renderer = truss_import("renderers/simple_renderer.t")
colorcoder = truss_import("utils/colorcoder.t")

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

function initNVG()
	nvg = nanovg.nvgCreate(0, 2) -- antialiasing, viewid
	bgfx.bgfx_set_view_seq(1, true)
	nvgfont = nanovg.nvgCreateFont(nvg, "sans", "font/VeraMono.ttf")
end

function renderNVG()
	nanovg.nvgBeginFrame(nvg, width, totalheight, 1.0)

	-- because NVG hijacks the view rect, we have to manually clear just the
	-- part NVG will be 'allowed' to draw into
	nanovg.nvgBeginPath(nvg)
	nanovg.nvgRect(nvg, 0, viewheight, width, totalheight-viewheight)
	nanovg.nvgFillColor(nvg, nanovg.nvgRGBA(0,0,0,255))
	nanovg.nvgFill(nvg)

	nanovg.nvgFontSize(nvg, 14)
	nanovg.nvgFillColor(nvg, nanovg.nvgRGBA(255,255,255,255))
	nanovg.nvgText(nvg, 0, totalheight, "Time: " .. time, nil)

	local flist = {math.cos(time), math.sin(time), time}
	colorcoder.encodeFloats(nvg, flist, 0, viewheight, 4, 4)

	nanovg.nvgEndFrame(nvg)
end

function initBGFX()
	-- Basic init

	local debug = bgfx_const.BGFX_DEBUG_TEXT
	local reset = bgfx_const.BGFX_RESET_VSYNC -- antialiasing will distort depth encoding
	--local reset = bgfx_const.BGFX_RESET_VSYNC + bgfx_const.BGFX_RESET_MSAA_X8
	--local reset = bgfx_const.BGFX_RESET_MSAA_X8

	local cbInterfacePtr = sdl.trss_sdl_get_bgfx_cb(sdlPointer)

	bgfx.bgfx_init(bgfx.BGFX_RENDERER_TYPE_COUNT, 0, 0, cbInterfacePtr, nil)
	bgfx.bgfx_reset(width, totalheight, reset)

	-- Enable debug text.
	bgfx.bgfx_set_debug(debug)

	bgfx.bgfx_set_view_clear(0, 
	bgfx_const.BGFX_CLEAR_COLOR + bgfx_const.BGFX_CLEAR_DEPTH,
	0x303030ff, -- clear color
	1.0, -- clear depth (in clip space?)
	0) -- flags??

	bgfx.bgfx_set_view_clear(1, 
	bgfx_const.BGFX_CLEAR_COLOR + bgfx_const.BGFX_CLEAR_DEPTH,
	0x000000ff,
	1.0,
	0)

	-- draw UI overlays last, don't clear color
	bgfx.bgfx_set_view_clear(2, 
	bgfx_const.BGFX_CLEAR_DEPTH,
	0x000000ff,
	1.0,
	0)

	trss.trss_log(0, "Initted bgfx I hope?")

	-- Init renderers
	leftrenderer = simple_renderer.SimpleRenderer(width/2, viewheight)
	rightrenderer = simple_renderer.SimpleRenderer(width/2, viewheight)
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
	trss.trss_log(0, "Texture handle idx: " .. modeltex.idx)

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

	bgfx.bgfx_set_view_rect(0,  0, 0, w2, viewheight)
	bgfx.bgfx_set_view_rect(1, w2, 0, w2, viewheight)
	--bgfx.bgfx_set_view_rect(2,  0, viewheight, width, totalheight - viewheight)

	-- do actual rendering
	leftrenderer:render()
	rightrenderer:render()

	-- text
	renderNVG()
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