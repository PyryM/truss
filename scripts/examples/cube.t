-- cube.t
-- 
-- draws a spinning cube (hopefully)

bgfx = libs.bgfx
terralib = libs.terralib
trss = libs.trss

struct BGRAColor {
	b: uint8;
	g: uint8;
	r: uint8;
	a: uint8;
}

struct Vertex {
	x: float;
	y: float;
	z: float;
    union {
    	int32_color: uint32;
    	color: BGRAColor;
	}
}

struct CubeData {
	vertices: Vertex[8];
	indices: uint16[36];
}

terra ter_makeCube(cube : &CubeData)
	cube.vertices[0] = [Vertex]{-1.0f,  1.0f,  1.0f, 0xff000000 }
	cube.vertices[1] = [Vertex]{ 1.0f,  1.0f,  1.0f, 0xff0000ff }
	cube.vertices[2] = [Vertex]{-1.0f, -1.0f,  1.0f, 0xff00ff00 }
	cube.vertices[3] = [Vertex]{ 1.0f, -1.0f,  1.0f, 0xff00ffff }
	cube.vertices[4] = [Vertex]{-1.0f,  1.0f, -1.0f, 0xffff0000 }
	cube.vertices[5] = [Vertex]{ 1.0f,  1.0f, -1.0f, 0xffff00ff }
	cube.vertices[6] = [Vertex]{-1.0f, -1.0f, -1.0f, 0xffffff00 }
	cube.vertices[7] = [Vertex]{ 1.0f, -1.0f, -1.0f, 0xffffffff }

	cube.indices = 	arrayof(uint16,
						    0, 1, 2,
							1, 3, 2,
							4, 6, 5, 
							5, 6, 7,
							0, 2, 4, 
							4, 2, 6,
							1, 5, 3, 
							5, 7, 3,
							0, 4, 1, 
							4, 5, 1,
							2, 3, 6, 
							6, 3, 7 )
end

terra ter_declareVertexSpec(vertDecl : &bgfx.bgfx_vertex_decl_t)
	bgfx.bgfx_vertex_decl_begin(vertDecl, bgfx.bgfx_get_renderer_type())
	bgfx.bgfx_vertex_decl_add(vertDecl, bgfx.BGFX_ATTRIB_POSITION, 3, bgfx.BGFX_ATTRIB_TYPE_FLOAT, false, false)
	-- COLOR0 is normalized (the 'true' flag) which indicates that uint8 values [0,255] should be scaled to [0.0,1.0]
	bgfx.bgfx_vertex_decl_add(vertDecl, bgfx.BGFX_ATTRIB_COLOR0, 4, bgfx.BGFX_ATTRIB_TYPE_UINT8, true, false)
	bgfx.bgfx_vertex_decl_end(vertDecl)
end

function createVertexSpec()
	local vspec = terralib.new(bgfx.bgfx_vertex_decl_t)
	ter_declareVertexSpec(vspec)
	return vspec
end

function createCubeData()
	local cube = terralib.new(CubeData)
	ter_makeCube(cube)
	return cube
end

function init()
	initBGFX()
end

width = 800
height = 600
frame = 0
time = 0.0

terra loadFileToBGFX(filename: &int8)
	var msg: &trss.trss_message = trss.trss_load_file(filename, 0)
	var ret: &bgfx.bgfx_memory = bgfx.bgfx_copy(message.data, message.data_length)
	trss.trss_release_message(msg)
	return ret
end

function loadProgram(vshadername, fshadername)
	local vspath = "shaders/dx11/" .. vshadername .. ".bin"
	local fspath = "shaders/dx11/" .. fshadername .. ".bin"

	local vshader = bgfx.bgfx_create_shader(loadFileToBGFX(vspath))
	local fshader = bgfx.bgfx_create_shader(loadFileToBGFX(fspath))

	return bgfx.bgfx_create_program(vshader, fshader, true)
end

function initBGFX()
	-- Basic init

	local debug = 0x08 --bgfx_constants.BGFX_DEBUG_TEXT
	local reset = 0x80 --bgfx_constants.BGFX_RESET_VSYNC

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

	-- Init the cube

	vertexdef = createVertexSpec()
	cubedata = createCubeData()

	local flags = 0

	-- Create static vertex buffer.
	vbh = bgfx.bgfx_create_vertex_buffer(
		  bgfx.bgfx_make_ref(cubedata.vertices, sizeof(Vertex[8]) ),
		  vertexdef, flags )

	-- Create static index buffer.
	ibh = bgfx.bgfx_create_index_buffer(
		  bgfx.bgfx_make_ref(cubedata.indices, sizeof(uint16[36])))

	-- load shader program
	program = loadProgram("vs_cubes", "fs_cubes")

	-- create matrices
	projmat = terralib.new(float[16])
	viewmat = terralib.new(float[16])
	modelmat = terralib.new(float[16])
end

CMath = terralib.includec("math.h")

terra mtxRotateXY(mat: &float, ax: float, ay: float)
	var sx = CMath.sinf(ax)
	var cx = CMath.cosf(ax)
	var sy = CMath.sinf(ay)
	var cy = CMath.cosf(ay)

	mat[ 0] = cy
	mat[ 1] = 0.0f 
	mat[ 2] = sy
	mat[ 3] = 0.0f
	mat[ 4] = sx*sy
	mat[ 5] = cx
	mat[ 6] = -sx*cy
	mat[ 7] = 0.0f
	mat[ 8] = -cx*sy
	mat[ 9] = sx
	mat[10] = cx*cy
	mat[11] = 0.0f
	mat[12] = 0.0f
	mat[13] = 0.0f
	mat[14] = 0.0f
	mat[15] = 1.0f
end

terra mtxProjXYWH(mat: &float, x: float, y: float, width: float, height: float, near: float, far: float)
	var diff = far - near
	var aa = far / diff
	var bb = -near*aa

	mat[ 0] = width;
	mat[ 5] = height;
	mat[ 8] =  x;
	mat[ 9] = -y;
	mat[10] = aa;
	mat[11] = 1.0f;
	mat[14] = bb;
end

terra setIdentity(mat: &float)
	mat[ 0], mat[ 1], mat[ 2], mat[ 3] = 1.0f, 0.0f, 0.0f, 0.0f 
	mat[ 4], mat[ 5], mat[ 6], mat[ 7] = 0.0f, 1.0f, 0.0f, 0.0f
	mat[ 8], mat[ 9], mat[10], mat[11] = 0.0f, 0.0f, 1.0f, 0.0f
	mat[12], mat[13], mat[14], mat[15] = 0.0f, 0.0f, 0.0f, 1.0f
end

function toRad(deg)
	return deg * math.pi / 180.0 
end

function makeProjMat(mat, fovy, aspect, near, far)
	local vheight = 1.0 / math.tan(toRad(fovy)*0.5)
	local vwidth  = vheight * 1.0/aspect;
	mtxProjXYWH(mat, 0.0, 0.0, vwidth, vheight, near, far)
end

function setViewMatrices()
	makeProjMat(projmat, 60.0, width / height, 0.01, 100.0)
	setIdentity(viewmat)

	bgfx.bgfx_set_view_transform(0, viewmat, projmat)
end

function update()
	frame = frame + 1
	time = time + 1.0 / 60.0

	-- Set view 0 default viewport.
	bgfx.bgfx_set_view_rect(0, 0, 0, width, height)

	-- This dummy draw call is here to make sure that view 0 is cleared
	-- if no other draw calls are submitted to view 0.
	bgfx.bgfx_submit(0, 0)

	-- Use debug font to print information about this example.
	bgfx.bgfx_dbg_text_clear(0, false)

	bgfx.bgfx_dbg_text_printf(0, 1, 0x4f, "scripts/examples/cube.t")
	bgfx.bgfx_dbg_text_printf(0, 2, 0x6f, "(frame " .. frame .. ")")

	-- Set viewprojection matrix
	setViewMatrices()

	-- Render our cube
	mtxRotateXY(modelmat, math.cos(time) * math.pi, math.sin(time) * math.pi)
	modelmat[14] = -1.0 -- put it in front of the camera (which faces -z)

	bgfx.bgfx_set_transform(modelmat)
	bgfx.bgfx_set_program(program)
	bgfx.bgfx_set_vertex_buffer(vbh)
	bgfx.bgfx_set_index_buffer(ibh)

	bgfx.set_state(bgfx.BGFX_STATE_DEFAULT)
	bgfx.bgfx_submit(0, 0)

	-- Advance to next frame. Rendering thread will be kicked to
	-- process submitted rendering primitives.
	bgfx.bgfx_frame();
end