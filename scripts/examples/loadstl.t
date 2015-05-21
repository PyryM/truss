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

function init()
	trss.trss_log(TRSS_ID, "loadstl.t init")
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

	-- Create vertex defs
	vertexInfo = vertexdefs.createPosColorVertexInfo()

	-- Load the model
	modeldata = stlloader.loadSTL("models/test_small.STL", true) -- invert windings
	modelbuffers = buffers.allocateData(vertexInfo, #(modeldata.positions), #(modeldata.indices))
	buffers.setIndices(modelbuffers, modeldata.indices)
	buffers.setAttributes(modelbuffers, buffers.positionSetter, modeldata.positions)
	buffers.setAttributes(modelbuffers, buffers.randomColorSetter, modeldata.normals)
	buffers.createStaticBGFXBuffers(modelbuffers)
	-- model is now in modelbuffers.vbh and modelbuffers.ibh

	-- load shader program
	log("Loading program")
	program = loadProgram("vs_cubes", "fs_cubes")

	-- create matrices
	projmat = terralib.new(float[16])
	viewmat = terralib.new(float[16])
	modelmat = terralib.new(float[16])
end

function drawCube()
	-- Set viewprojection matrix
	setViewMatrices()

	-- Render our cube
	mtx.rotateXY(modelmat, math.cos(time*0.2) * math.pi, math.sin(time*0.2) * math.pi)
	modelmat[14] = 0.12 -- put it in front of the camera (which faces z?)
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

	-- Set view 0 default viewport.
	bgfx.bgfx_set_view_rect(0, 0, 0, width, height)

	-- This dummy draw call is here to make sure that view 0 is cleared
	-- if no other draw calls are submitted to view 0.
	--bgfx.bgfx_submit(0, 0)

	-- Use debug font to print information about this example.
	bgfx.bgfx_dbg_text_clear(0, false)

	bgfx.bgfx_dbg_text_printf(0, 1, 0x4f, "scripts/examples/stlloader.t")
	bgfx.bgfx_dbg_text_printf(0, 2, 0x6f, "frame time: " .. frametime*1000.0 .. " ms")

	drawCube()

	-- Advance to next frame. Rendering thread will be kicked to
	-- process submitted rendering primitives.
	bgfx.bgfx_frame()

	frametime = calcDeltaTime(startTime)
end