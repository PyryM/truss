-- dart_simple_renderer.t
--
-- example of using renderers/simple_renderer.t
-- to render a dart json scenegraph

bgfx = libs.bgfx
bgfx_const = libs.bgfx_const
terralib = libs.terralib
trss = libs.trss
sdl = libs.sdl
sdlPointer = libs.sdlPointer
TRSS_ID = libs.TRSS_ID
nanovg = libs.nanovg

function init()
	trss.trss_log(TRSS_ID, "dart_simple_renderer.t init")
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

meshmanager = truss_import("dart/meshmanager.t")
simple_renderer = truss_import("renderers/simple_renderer.t")
matrixlib = truss_import("math/matrix.t")
quatlib = truss_import("math/quat.t")
local Matrix4 = matrixlib.Matrix4
local Quaternion = quatlib.Quaternion

function updateEvents()
	local nevents = sdl.trss_sdl_num_events(sdlPointer)
	for i = 1,nevents do
		local evt = sdl.trss_sdl_get_event(sdlPointer, i-1)
		if evt.event_type == sdl.TRSS_SDL_EVENT_MOUSEMOVE then
			mousex = evt.x
			mousey = evt.y
		elseif evt.event_type == sdl.TRSS_SDL_EVENT_KEYDOWN or evt.event_type == sdl.TRSS_SDL_EVENT_KEYUP then
			local sname = "up"
			if evt.event_type == sdl.TRSS_SDL_EVENT_KEYDOWN then sname = "down" end
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

function updateCamera(theta, phi, rad)
	local rr = rad * math.cos(phi)
	local y = rad * math.sin(phi)
	local x = rr * math.cos(theta)
	local z = rr * math.sin(theta)
	local scale = {x=1, y=1, z=1}

	campos.x, campos.y, campos.z = x, y, z
	camquat:fromEuler({x=phi,y=-theta+math.pi/2.0,z=0}, 'ZYX')
	cammat:compose(camquat, scale, campos)
	renderer:setCameraTransform(cammat)
end

function updateModelRotation(time)
	camquat:fromEuler({x= -math.pi / 2.0,y=time*0.1,z=0}, 'ZYX')
	campos.x, campos.y, campos.z = 0,-0.5,0
	local scale = {x=1, y=1, z=1}
	cammat:compose(camquat, scale, campos)
	renderer:setRootTransform(cammat)
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
	0x303030ff,
	1.0,
	0)

	trss.trss_log(0, "Initted bgfx I hope?")

	-- Init renderer
	renderer = simple_renderer.SimpleRenderer(width, height)
	renderer.autoUpdateMatrices = false

	-- init mesh manager
	manager = meshmanager.MeshManager("temp/meshes/", renderer)

	-- load in a json
	local jsonstring = loadStringFromFile("temp/wam.json")
	manager:update(jsonstring)

	-- camera
	cammat = Matrix4():identity()
	camquat = Quaternion():identity()
	campos = {x = 0, y = 0, z = 0}
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

	bgfx.bgfx_dbg_text_printf(0, 1, 0x4f, "scripts/examples/dart_simple_renderer.t")
	bgfx.bgfx_dbg_text_printf(0, 2, 0x6f, "frame time: " .. frametime*1000.0 .. " ms")

	updateCamera(math.pi / 2.0, 0.0, 1.5)
	updateModelRotation(time)
	renderer:render()

	-- Advance to next frame. Rendering thread will be kicked to
	-- process submitted rendering primitives.
	bgfx.bgfx_frame()

	frametime = toc(startTime)
end