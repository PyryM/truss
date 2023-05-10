-- cube.t
-- 
-- a totally from-scratch example of how to draw a cube with
-- just raw bgfx and (almost no) helper libraries

local bgfx = require("gfx/bgfx.t")
local sdl = require("addon/sdl.t")
local math = require("math")
local timing = require("osnative/timing.t")

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

terra fill_cube(cube : &CubeData)
  cube.vertices[0] = [Vertex]{-1.0f,  1.0f,  1.0f, 0xff000000 }
  cube.vertices[1] = [Vertex]{ 1.0f,  1.0f,  1.0f, 0xff0000ff }
  cube.vertices[2] = [Vertex]{-1.0f, -1.0f,  1.0f, 0xff00ff00 }
  cube.vertices[3] = [Vertex]{ 1.0f, -1.0f,  1.0f, 0xff00ffff }
  cube.vertices[4] = [Vertex]{-1.0f,  1.0f, -1.0f, 0xffff0000 }
  cube.vertices[5] = [Vertex]{ 1.0f,  1.0f, -1.0f, 0xffff00ff }
  cube.vertices[6] = [Vertex]{-1.0f, -1.0f, -1.0f, 0xffffff00 }
  cube.vertices[7] = [Vertex]{ 1.0f, -1.0f, -1.0f, 0xffffffff }

  cube.indices = arrayof(uint16,
    0, 2, 1,
    1, 2, 3,
    4, 5, 6, 
    5, 7, 6,
    0, 4, 2, 
    4, 6, 2,
    1, 3, 5, 
    5, 3, 7,
    0, 1, 4, 
    4, 1, 5,
    2, 6, 3, 
    6, 7, 3 
  )
end

function create_vertex_spec()
  local vertex_decl = terralib.new(bgfx.vertex_decl_t)
  bgfx.vertex_decl_begin(vertex_decl, bgfx.get_renderer_type())
  bgfx.vertex_decl_add(vertex_decl, bgfx.ATTRIB_POSITION, 3, bgfx.ATTRIB_TYPE_FLOAT, false, false)
  -- COLOR0 is normalized (the 'true' flag) which indicates that uint8 values [0,255] should be scaled to [0.0,1.0]
  bgfx.vertex_decl_add(vertex_decl, bgfx.ATTRIB_COLOR0, 4, bgfx.ATTRIB_TYPE_UINT8, true, false)
  bgfx.vertex_decl_end(vertex_decl)
  return vertex_decl
end

function create_cube_data()
  local cube = terralib.new(CubeData)
  fill_cube(cube)
  return cube
end

function init()
  log.info("cube.t init")
  sdl.create_window(width, height, 'raw cube example', false)
  init_bgfx()
  local backend = bgfx.get_renderer_type()
  local backend_name = ffi.string(bgfx.get_renderer_name(backend))
  log.info("Renderer type: " .. backend_name)
end

width = 800
height = 600
frame = 0
time = 0.0


function load_program(vshadername, fshadername)
  -- we use a library function for this because handling renderer specific
  -- paths, loading from archives, etc. is just a bunch of boilerplate
  return require("gfx").load_program(vshadername, fshadername)
end

viewmat = math.Matrix4():identity()
projmat = math.Matrix4():perspective_projection(45.0, width/height, 0.01, 100.0)

function set_matrices()
  bgfx.set_view_transform(0, viewmat.data, projmat.data)
end

function initBGFX()
  -- Basic init

  local debug = bgfx.DEBUG_TEXT
  local reset = bgfx.RESET_VSYNC + bgfx.RESET_MSAA_X8

  bgfx.init(bgfx.RENDERER_TYPE_COUNT, 0, 0, nil, nil)
  bgfx.reset(width, height, reset)

  -- Enable debug text.
  bgfx.set_debug(debug)

  bgfx.set_view_clear(0, 
  0x0001 + 0x0002, -- clear color + clear depth
  0x303030ff,
  1.0,
  0)

  log.info("Initted bgfx I hope?")

  -- Init the cube

  log.info("Loading vertex def.")
  vertexdef = create_vertex_spec()
  log.info("Creating cube data.")
  cubedata = create_cube_data()

  local flags = 0

  -- Create static vertex buffer.
  log.info("Creating vertex buffer")
  vbh = bgfx.create_vertex_buffer(
      bgfx.make_ref(cubedata.vertices, sizeof(Vertex[8]) ),
      vertexdef, flags )

  -- Create static index buffer.
  log.info("Creating index buffer")
  ibh = bgfx.create_index_buffer(
      bgfx.make_ref(cubedata.indices, sizeof(uint16[36])), 0)

  -- load shader program
  log.info("Loading program")
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
  modelmat[14] = -10.0 -- put it in front of the camera (which faces z?)

  bgfx.bgfx_set_transform(modelmat, 1) -- only one matrix in array
  bgfx.bgfx_set_vertex_buffer(vbh, 0, bgfx.UINT32_MAX)
  bgfx.bgfx_set_index_buffer(ibh, 0, bgfx.UINT32_MAX)

  bgfx.bgfx_set_state(bgfx_const.BGFX_STATE_DEFAULT, 0)
  bgfx.bgfx_submit(0, program, 0)
end

frametime = 0.0

function update()
  frame = frame + 1
  time = time + 1.0 / 60.0

  local start = timing.tic()

  -- Deal with input events
  sdl.handle_minimal_events()

  -- Set view 0 default viewport.
  bgfx.set_view_rect(0, 0, 0, width, height)

  -- This dummy draw call is here to make sure that view 0 is cleared
  -- if no other draw calls are submitted to view 0.
  --bgfx.bgfx_submit(0, 0)

  -- Use debug font to print information about this example.
  bgfx.dbg_text_clear(0, false)

  bgfx.dbg_text_printf(0, 1, 0x4f, "scripts/examples/cube.t")
  bgfx.dbg_text_printf(0, 2, 0x6f, "frame time: " .. frametime*1000.0 .. " ms")

  draw_cube()

  -- Advance to next frame. Rendering thread will be kicked to
  -- process submitted rendering primitives.
  bgfx.bgfx_frame()

  frametime = timing.toc(start)
end