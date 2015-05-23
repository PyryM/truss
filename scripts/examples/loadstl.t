-- loadstl.t
--
-- example of loading and displaying an stl model

-- cube.t
-- 
-- draws a spinning cube (hopefully)

bgfx = libs.bgfx
bgfx_const = libs.bgfx_const
terralib = libs.terralib
trss = libs.trss
sdl = libs.sdl
sdlPointer = libs.sdlPointer
TRSS_ID = libs.TRSS_ID
nanovg = libs.nanovg

function init()
	trss.trss_log(TRSS_ID, "loadstl.t init")
	sdl.trss_sdl_create_window(sdlPointer, width, height, 'TRUSS TEST')
	initBGFX()
	initNVG()
	local rendererType = bgfx.bgfx_get_renderer_type()
	local rendererName = ffi.string(bgfx.bgfx_get_renderer_name(rendererType))
	trss.trss_log(TRSS_ID, "Renderer type: " .. rendererName)
end

width = 800
height = 600
frame = 0
time = 0.0
mousex, mousey = 0, 0

terra loadFileToBGFX(filename: &int8)
	var msg: &trss.trss_message = trss.trss_load_file(filename, 0)
	var ret: &bgfx.bgfx_memory = bgfx.bgfx_copy(msg.data, msg.data_length)
	trss.trss_release_message(msg)
	return ret
end

function loadProgram(vshadername, fshadername)
	trss.trss_log(0, "Warning: loadProgram in cube.t only works with dx11 at the moment!")

	local vspath = "shaders/dx11/" .. vshadername .. ".bin"
	local fspath = "shaders/dx11/" .. fshadername .. ".bin"

	local vshader = bgfx.bgfx_create_shader(loadFileToBGFX(vspath))
	local fshader = bgfx.bgfx_create_shader(loadFileToBGFX(fspath))
	log("vidx: " .. vshader.idx)
	log("fidx: " .. fshader.idx)

	return bgfx.bgfx_create_program(vshader, fshader, true)
end

function initNVG()
	-- create context, indicate to bgfx that drawcalls to view
	-- 1 should happen in the order that they were submitted
	nvg = nanovg.nvgCreate(0, 1) -- create into view 1
	bgfx.bgfx_set_view_seq(1, true)

	-- load font
	--nvgfont = nanovg.nvgCreateFont(nvg, "sans", "font/roboto-regular.ttf")
	nvgfont = nanovg.nvgCreateFont(nvg, "sans", "font/VeraMono.ttf")
end

frametime = 0.0

lines = {"this is a set of text lines",
		 "here is the next one",
		 "woo yay",
		 "/* Begin some code to see how it aligns */",
		 "#define TRSS_LOG_CRITICAL 0",
		 "#define TRSS_LOG_ERROR    1",
		 "#define TRSS_LOG_WARNING  2",
		 "#define TRSS_LOG_INFO     3",
		 "#define TRSS_LOG_DEBUG    4",
		 "All random numbers changing every frame:"}

function makeRandomLines(startpos, endpos)
	for i = startpos,endpos do
		lines[i] = "[" .. math.random() .. "]"
	end
end

function drawNVG()
		makeRandomLines(11, 30)

		nanovg.nvgBeginFrame(nvg, width, height, 1.0)

		nanovg.nvgSave(nvg)
		nanovg.nvgFontSize(nvg, 14)
		nanovg.nvgFontFace(nvg, "sans")
		lines[1] = "example of a line that is changing: " .. time
		local lineheight = 14
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

CMath = terralib.includec("math.h")
mtx = truss_import("math/matrix.t")
stlloader = truss_import("loaders/stlloader.t")
buffers = truss_import("mesh/buffers.t")
vertexdefs = truss_import("mesh/vertexdefs.t")

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
	trss.trss_log(TRSS_ID, msg)
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

	bgfx.bgfx_set_view_clear(1, 
	bgfx_const.BGFX_CLEAR_DEPTH, -- clear depth so gui will draw
	0,
	1.0,
	0)

	trss.trss_log(0, "Initted bgfx I hope?")

	-- Create vertex defs
	vertexInfo = vertexdefs.createPosNormalVertexInfo()

	-- Load the model
	modeldata = stlloader.loadSTL("models/segway_wheel_left.STL", true) -- invert windings
	modelbuffers = buffers.allocateData(vertexInfo, #(modeldata.positions), #(modeldata.indices))
	buffers.setIndices(modelbuffers, modeldata.indices)
	buffers.setAttributes(modelbuffers, buffers.positionSetter, modeldata.positions)
	buffers.setAttributes(modelbuffers, buffers.normalSetter, modeldata.normals)
	--buffers.setAttributes(modelbuffers, buffers.randomColorSetter, modeldata.normals)
	buffers.createStaticBGFXBuffers(modelbuffers)
	-- model is now in modelbuffers.vbh and modelbuffers.ibh

	-- create uniforms
	numLights = 4;
	u_lightDir = bgfx.bgfx_create_uniform("u_lightDir", bgfx.BGFX_UNIFORM_TYPE_UNIFORM3FV, numLights)
	u_lightRgb = bgfx.bgfx_create_uniform("u_lightRgb", bgfx.BGFX_UNIFORM_TYPE_UNIFORM3FV, numLights)
	u_baseColor = bgfx.bgfx_create_uniform("u_baseColor", bgfx.BGFX_UNIFORM_TYPE_UNIFORM3FV, 1)

	-- load shader program
	log("Loading program")
	program = loadProgram("vs_untextured", "fs_untextured")

	-- create matrices
	projmat = terralib.new(float[16])
	viewmat = terralib.new(float[16])
	modelmat = terralib.new(float[16])
end

struct LightDir {
	x: float;
	y: float;
	z: float;
	w: float;
}

struct LightColor {
	r: float;
	g: float;
	b: float;
	a: float;
}

lightDirs = nil
lightColors = nil
modelColor = nil

function setLightDirections(dirs)
	if lightDirs == nil then
		lightDirs = terralib.new(LightDir[numLights])
	end
	for i = 1,numLights do
		lightDirs[i-1].x = dirs[i][1]
		lightDirs[i-1].y = dirs[i][2]
		lightDirs[i-1].z = dirs[i][3]
	end
	bgfx.bgfx_set_uniform(u_lightDir, lightDirs, numLights)
end

function setLightColors(colors)
	if lightColors == nil then
		lightColors = terralib.new(LightColor[numLights])
	end
	for i = 1,numLights do
		lightColors[i-1].r = colors[i][1]
		lightColors[i-1].g = colors[i][2]
		lightColors[i-1].b = colors[i][3]
	end
	bgfx.bgfx_set_uniform(u_lightRgb, lightColors, numLights)
end

function setModelColor(r, g, b)
	if modelColor == nil then
		modelColor = terralib.new(float[4])
	end
	modelColor[0] = r
	modelColor[1] = g
	modelColor[2] = b
	bgfx.bgfx_set_uniform(u_baseColor, modelColor, 1)
end

function normalizeDir(d)
	local m = 1.0 / math.sqrt(d[1]*d[1] + d[2]*d[2] + d[3]*d[3])
	return {m*d[1], m*d[2], m*d[3]}
end

function drawCube()
	-- Set viewprojection matrix
	setViewMatrices()

	-- set lights ( {0,0,0} disables the light )
	setLightDirections({
			normalizeDir({1, 1, 1}),
			normalizeDir({0,-1, 1}),
			normalizeDir{0.0, -1.0, 0.5},
			{  0.0,   1.0,   0.0}
		})

	local off = {0.0, 0.0, 0.0}
	setLightColors({
			off, --{0.4, 0.4, 0.4},
			{0.6, 0.6, 0.6},
			{0.2, 0.1, 0.0},
			{0.1, 0.1, 0.2}
		})

	-- set model color
	setModelColor(1.0,1.0,1.0)

	-- Render our cube
	mtx.rotateXY(modelmat, math.cos(time*0.2) * math.pi, math.sin(time*0.2) * math.pi)
	modelmat[14] = 0.5 -- put it in front of the camera (which faces z?)
						-- the stl is really small so put it really close

	bgfx.bgfx_set_transform(modelmat, 1) -- only one matrix in array
	bgfx.bgfx_set_program(program)
	bgfx.bgfx_set_vertex_buffer(modelbuffers.vbh, 0, bgfx.UINT32_MAX)
	bgfx.bgfx_set_index_buffer(modelbuffers.ibh, 0, bgfx.UINT32_MAX)

	bgfx.bgfx_set_state(bgfx_const.BGFX_STATE_DEFAULT, 0)
	bgfx.bgfx_submit(0, 0)
end

terra calcDeltaTime(startTime: uint64)
	var curtime = trss.trss_get_hp_time()
	var freq = trss.trss_get_hp_freq()
	var deltaF : float = curtime - startTime
	return deltaF / [float](freq)
end

frametime = 0.0

function update()
	frame = frame + 1
	time = time + 1.0 / 60.0

	local startTime = trss.trss_get_hp_time()

	-- Deal with input events
	updateEvents()

	-- Set view 0,1 default viewport.
	bgfx.bgfx_set_view_rect(0, 0, 0, width, height)
	bgfx.bgfx_set_view_rect(1, 0, 0, width, height)

	-- This dummy draw call is here to make sure that view 0 is cleared
	-- if no other draw calls are submitted to view 0.
	--bgfx.bgfx_submit(0, 0)

	-- Use debug font to print information about this example.
	bgfx.bgfx_dbg_text_clear(0, false)

	bgfx.bgfx_dbg_text_printf(0, 1, 0x4f, "scripts/examples/stlloader.t")
	bgfx.bgfx_dbg_text_printf(0, 2, 0x6f, "frame time: " .. frametime*1000.0 .. " ms")

	drawCube()
	drawNVG()

	-- Advance to next frame. Rendering thread will be kicked to
	-- process submitted rendering primitives.
	bgfx.bgfx_frame()

	frametime = calcDeltaTime(startTime)
end