-- 00_buffercube.t
--
-- manually create a cube mesh and use it to draw multiple cubes spinning

local sdl = require("addons/sdl.t")

local math = require("math")
local gfx = require("gfx")
local StaticGeometry = gfx.StaticGeometry
local vinfo = gfx.create_pos_color_vertex_info()
local shaderutils = require('utils/shaderutils.t')

width = 800
height = 600
time = 0.0

function make_cube_geo()
  local data = {
    attributes = {
      position = {{-1.0,  1.0,  1.0},
            { 1.0,  1.0,  1.0},
            {-1.0, -1.0,  1.0},
            { 1.0, -1.0,  1.0},
            {-1.0,  1.0, -1.0},
            { 1.0,  1.0, -1.0},
            {-1.0, -1.0, -1.0},
            { 1.0, -1.0, -1.0}},
      color0   = {{ 0.0, 0.0, 0.0, 255},
            { 255, 0.0, 0.0, 255},
            { 0.0, 255, 0.0, 255},
            { 255, 255, 0.0, 255},
            { 0.0, 0.0, 255, 255},
            { 255, 0.0, 255, 255},
            { 0.0, 255, 255, 255},
            { 255, 255, 255, 255}}
    },
    indices   = { 0, 2, 1,
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
            6, 7, 3 }
  }

  log.info("trying to make cube...")
  return StaticGeometry("cube"):from_data(data, vinfo)
end

function init()
  log.info("cube.t init")
  sdl.create_window(width, height, '00 buffercube')
  log.info("created window")
  init_bgfx()
end

function update_events()
  for evt in sdl.events() do
    if evt.event_type == sdl.EVENT_WINDOW and evt.flags == 14 then
      log.info("Received window close, stopping interpreter...")
      truss.quit()
    end
  end
end

function init_bgfx()
  -- basic init
  gfx.init_gfx({msaa = true, debugtext = true})

  bgfx.set_view_clear(0, -- viewid 0
    bgfx.CLEAR_COLOR + bgfx.CLEAR_DEPTH,
    0x303030ff, -- clearcolor (gray)
    1.0, -- cleardepth (in normalized space: 1.0 = max depth)
    0)

  -- init the cube
  cubegeo = make_cube_geo()

  -- load shader program
  log.info("Loading program")
  program = shaderutils.loadProgram("vs_cubes", "fs_cubes")

  -- create matrices
  projmat = math.Matrix4():makeProjection(70, 800/600, 0.1, 100.0)
  viewmat = math.Matrix4():identity()
  modelmat = math.Matrix4():identity()
  posvec = math.Vector(0.0, 0.0, -10.0)
  scalevec = math.Vector(1.0, 1.0, 1.0)
  rotquat = math.Quaternion():identity()
end

function draw_cube(xpos, ypos, phase)
  -- Compute the cube's transformation
  rotquat:fromEuler({x = time + phase, y = time + phase, z = 0.0})
  posvec:set(xpos, ypos, -10.0)
  modelmat:composeRigid(posvec, rotquat)
  bgfx.set_transform(modelmat.data, 1) -- only one matrix in array

  -- Bind the cube buffers
  cubegeo:bind()

  -- Setting default state is not strictly necessary, but good practice
  bgfx.set_state(bgfx.STATE_DEFAULT, 0)
  bgfx.submit(0, program, 0, false)
end

frametime = 0.0

function update()
  time = time + 1.0 / 60.0

  local startTime = truss.tic()

  -- Deal with input events
  update_events()

  -- Set view 0 default viewport.
  bgfx.set_view_rect(0, 0, 0, width, height)

  -- Use debug font to print information about this example.
  bgfx.dbg_text_clear(0, false)

  bgfx.dbg_text_printf(0, 1, 0x4f, "scripts/examples/cube.t")
  bgfx.dbg_text_printf(0, 2, 0x6f, "frame time: " .. frametime*1000.0 .. " ms")

  bgfx.touch(0)

  -- Set viewprojection matrix
  bgfx.set_view_transform(0, viewmat.data, projmat.data)

  -- -- draw four cubes
  draw_cube( 3,  3, 0.0)
  draw_cube(-3,  3, 1.0)
  draw_cube(-3, -3, 2.0)
  draw_cube( 3, -3, 3.0)

  -- Advance to next frame. Rendering thread will be kicked to
  -- process submitted rendering primitives.
  gfx.frame()

  frametime = truss.toc(startTime)
end
