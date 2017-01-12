-- 00_buffercube.t
--
-- manually create a cube mesh and use it to draw multiple cubes spinning

local sdl = require("addons/sdl.t")
local math = require("math")
local gfx = require("gfx")

width = 1280
height = 720
time = 0.0

function make_cube_geo()
  local gray = {20, 20, 20, 255}
  local grey = {40, 40, 40, 255}
  local data = {
    attributes = {
      position = {{-1.0,  1.0,  1.0},
                  { 1.0,  1.0,  1.0},
                  {-1.0, -1.0,  1.0},
                  { 1.0, -1.0,  1.0},
                  {-1.0,  1.0, -1.0},
                  { 1.0,  1.0, -1.0},
                  {-1.0, -1.0, -1.0},
                  { 1.0, -1.0, -1.0}
                 },
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

  return gfx.StaticGeometry("cube"):from_data(data)
end

function update_events()
  for evt in sdl.events() do
    if evt.event_type == sdl.EVENT_WINDOW and evt.flags == 14 then
      truss.quit()
    end
  end
end

function init()
  -- basic init
  sdl.create_window(width, height, '00 buffercube')
  gfx.init_gfx({msaa = true, debugtext = true, window = sdl})

  -- set up our one view (rendering directly to backbuffer)
  view = gfx.View(0)
  view:set_clear({color = 0x403030ff, depth = 1.0})
  view:set_viewport(false)

  -- init the cube
  cubegeo = make_cube_geo()
  cubegeo:release_backing() -- don't keep backing memory around

  -- load shader program
  program = gfx.load_program("vs_cubes", "fs_cubes")

  -- create matrices
  projmat = math.Matrix4():perspective_projection(70, width/height, 0.1, 100.0)
  viewmat = math.Matrix4():identity()
  modelmat = math.Matrix4():identity()
  posvec = math.Vector(0.0, 0.0, -10.0)
  rotquat = math.Quaternion():identity()

  cubestate = gfx.create_state({cull = false})
end

function draw_cube(xpos, ypos, phase, partial)
  -- Compute the cube's transformation
  rotquat:euler({x = time + phase, y = time + phase, z = 0.0})
  posvec:set(xpos, ypos, -10.0)
  modelmat:compose(posvec, rotquat)
  gfx.set_transform(modelmat)

  -- Bind the cube buffers
  if partial then cubegeo:bind_partial(0, 8, 0, 18) else cubegeo:bind() end

  -- Setting default state is not strictly necessary, but good practice
  gfx.set_state(cubestate)
  gfx.submit(view, program)
end

frametime = 0.0

function update()
  time = time + 1.0 / 60.0
  local start_time = truss.tic()

  -- Deal with input events
  update_events()

  -- Use debug font to print information about this example.
  bgfx.dbg_text_clear(0, false)

  bgfx.dbg_text_printf(0, 1, 0x4f, "scripts/examples/cube.t")
  bgfx.dbg_text_printf(0, 2, 0x6f, "frame time: " .. frametime*1000.0 .. " ms")

  -- Set viewprojection matrix
  view:set_matrices(viewmat, projmat)

  -- draw four cubes
  draw_cube( 3,  3, 0.0, true)
  draw_cube(-3,  3, 1.0, false)
  draw_cube(-3, -3, 2.0, true)
  draw_cube( 3, -3, 3.0, false)

  -- Advance to next frame.
  gfx.frame()

  frametime = truss.toc(start_time)
end
