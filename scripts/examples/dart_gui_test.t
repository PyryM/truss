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
	initNVG()
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

meshmanager = truss_import("dart/meshmanager.t")
simple_renderer = truss_import("renderers/simple_renderer.t")
matrixlib = truss_import("math/matrix.t")
quatlib = truss_import("math/quat.t")
local Matrix4 = matrixlib.Matrix4
local Quaternion = quatlib.Quaternion
Line = truss_import("mesh/line.t")
local OrbitCam = truss_import("gui/orbitcam.t")

guiSrc = "gui/console.t"
gui = truss_import(guiSrc)

function onTextInput(tstr)
	log("Text input: " .. tstr)
	if gui ~= nil and gui.onTextInput ~= nil then
		gui.onTextInput(tstr)
	end
end

function onKeyDown(keyname, modifiers)
	log("Keydown: " .. keyname)
	if gui ~= nil and gui.onKeyDown ~= nil then
		gui.onKeyDown(keyname, modifiers)
	end
end

function onKeyUp(keyname)
	-- nothing to do
end

downkeys = {}

function cprint(str)
	if gui then gui.printStraightText_(tostring(str)) end
end

function cerr(str)
	if gui then gui.printColored(tostring(str), {255,0,0}) end
end

websocket = truss_import("io/websocket.t")

function connect(url, callback)
	cprint("Connecting to [" .. url .. "]")
	if theSocket == nil then
		theSocket = websocket.WebSocketConnection()
	end
	theSocket:onMessage(callback)
	theSocket:connect(url)
	return theSocket
end

sframe = 0
decimate = 10
function requestData()
	sframe = sframe + 1 
	if theSocket and theSocket:isOpen() and sframe % decimate == 0 then
		theSocket:send("ping")
	end
end

function updateMeshesFromJSONString(str)
	manager:update(str)
end

function set_update_decimation(v)
	if v > 0 then
		decimate = v
	else
		cerr("Cannot set decimate to <= 0!")
	end
end

function connect_dart(url)
	cprint("Connecting to [" .. url .. "]")
	if theSocket == nil then
		theSocket = websocket.WebSocketConnection()
	end
	theSocket:onMessage(updateMeshesFromJSONString)
	theSocket:connect(url)
	return theSocket
end

function load_json_scene(filename)
	cprint("Loading local json serialization file [" .. filename .. "]")
	local jsonstring = loadStringFromFile(filename)
	manager:update(jsonstring)
end

function load_herb()
	load_json_scene("temp/herb.json")
end

consoleenv = {print = cprint, 
			  err = cerr,
			  pairs = pairs,
			  ipairs = ipairs,
			  math = math,
			  connect = connect,
			  connect_dart = connect_dart,
			  set_update_decimation = set_update_decimation,
			  truss_import = truss_import,
			  load_json_scene = load_json_scene,
			  load_herb = load_herb}

function consoleExecute(str)
	local lchunk, err = loadstring(str)
	if err then
		cerr(err)
		return
	end
	setfenv(lchunk, consoleenv)
	local succeeded, retval = pcall(lchunk)
	if succeeded then
		if retval then
			cprint(retval)
		end
	else
		cerr(retval)
	end
end

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

function updateModelRotation(time)
	camquat:fromEuler({x= -math.pi / 2.0,y=time*0.1,z=0}, 'ZYX')
	--camquat:identity()
	campos.x, campos.y, campos.z = 0,-0.5,0
	local scale = {x=1, y=1, z=1}
	cammat:compose(camquat, scale, campos)
	renderer:setRootTransform(cammat)
end

function addLineCircle(dest, rad)
	-- create a circle
	local circlepoints = {}
	local npts = 60
	local dtheta = math.pi * 2.0 / (npts - 1)
	for i = 1,npts do
		local x = rad * math.cos(i * dtheta)
		local y = rad * math.sin(i * dtheta)
		local z = 0.0
		circlepoints[i] = {x, y, z}
	end
	table.insert(dest, circlepoints)
	return npts
end

function addSegmentedLine(dest, v0, v1, nsteps)
	local dx = (v1[1] - v0[1]) / (nsteps - 1)
	local dy = (v1[2] - v0[2]) / (nsteps - 1)
	local dz = (v1[3] - v0[3]) / (nsteps - 1)

	local curline = {}
	local x, y, z = v0[1], v0[2], v0[3]
	for i = 0,(nsteps-1) do
		table.insert(curline, {x, y, z})
		x, y, z = x + dx, y + dy, z + dz
	end
	table.insert(dest, curline)
	return #curline
end

function createLineGrid()
	local x0 = -5
	local dx = 0.5
	local nx = 20
	local x1 = x0 + nx*dx
	local y0 = -5
	local dy = 0.5
	local ny = 20
	local y1 = y0 + ny*dy

	local lines = {}
	local npts = 0

	for ix = 0,nx do
		local x = x0 + ix*dx
		local v0 = {x, y0, 0}
		local v1 = {x, y1, 0}
		npts = npts + addSegmentedLine(lines, v0, v1, 30)
		--table.insert(lines, {v0, v1})
		--npts = npts + 2
	end

	for iy = 0,ny do
		local y = y0 + iy*dy
		local v0 = {x0, y, 0}
		local v1 = {x1, y, 0}
		npts = npts + addSegmentedLine(lines, v0, v1, 30)
		--table.insert(lines, {v0, v1})
		--npts = npts + 2
	end

	local r0 = 0.0
	local dr = 0.5
	local nr = 10
	for ir = 1,nr do
		npts = npts + addLineCircle(lines, r0 + ir*dr)
	end

	theline = Line(npts, false) -- static line
	theline:setPoints(lines)
	theline:createDefaultMaterial({0.7,0.7,0.7,1}, 0.005)

	renderer:add(theline)

end

function initNVG()
	-- create context, indicate to bgfx that drawcalls to view
	-- 0 should happen in the order that they were submitted
	nvg = nanovg.nvgCreate(1, 1) -- make sure to have antialiasing on
	bgfx.bgfx_set_view_seq(1, true)

	-- load font
	--nvgfont = nanovg.nvgCreateFont(nvg, "sans", "font/roboto-regular.ttf")
	nvgfont = nanovg.nvgCreateFont(nvg, "sans", "font/VeraMono.ttf")

	if gui and gui.init then
		gui.init(width, height, nvg)
		gui.execCallback = consoleExecute
	end
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
	--local jsonstring = loadStringFromFile("temp/herb.json")
	--manager:update(jsonstring)

	-- create a line grid
	createLineGrid()

	-- camera
	cammat = Matrix4():identity()
	camquat = Quaternion():identity()
	campos = {x = 0, y = 0, z = 0}
	orbitcam = OrbitCam()

	-- Set renderer root (borrow camera temp quaternions)
	camquat:fromEuler({x= -math.pi / 2.0,y=0,z=0}, 'ZYX')
	--camquat:identity()
	campos.x, campos.y, campos.z = 0,0,0
	local scale = {x=1, y=1, z=1}
	cammat:compose(camquat, scale, campos)
	renderer:setRootTransform(cammat)
end

function drawNVG()
	nanovg.nvgBeginFrame(nvg, width, height, 1.0)
	if gui then
		gui.draw(nvg, width, height)
	end
	nanovg.nvgEndFrame(nvg)
end

frametime = 0.0
scripttime = 0.0

function update()
	frame = frame + 1
	time = time + 1.0 / 60.0

	local startTime = tic()

	-- Deal with input and io events
	updateEvents()
	requestData()
	if theSocket then theSocket:update() end

	-- Set view 0,1 default viewport.
	bgfx.bgfx_set_view_rect(0, 0, 0, width, height)
	bgfx.bgfx_set_view_rect(1, 0, 0, width, height)

	-- This dummy draw call is here to make sure that view 0 is cleared
	-- if no other draw calls are submitted to view 0.
	bgfx.bgfx_submit(0, 0)

	-- Use debug font to print information about this example.
	bgfx.bgfx_dbg_text_clear(0, false)

	bgfx.bgfx_dbg_text_printf(0, 1, 0x4f, "scripts/examples/dart_simple_renderer.t")
	bgfx.bgfx_dbg_text_printf(0, 2, 0x6f, "total: " .. frametime*1000.0 .. " ms, script: " .. scripttime*1000.0 .. " ms")

	updateCamera()
	--updateModelRotation(time)
	renderer:render()
	drawNVG()

	scripttime = toc(startTime)

	-- Advance to next frame. Rendering thread will be kicked to
	-- process submitted rendering primitives.
	bgfx.bgfx_frame()

	frametime = toc(startTime)
end