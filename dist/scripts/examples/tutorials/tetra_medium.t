-- Tetrahedron take 2: the gfx module
-- ==================================

-- This tutorial demonstrates how to render a tetrahedron using the gfx
-- module, which is a wrapper around raw bgfx calls.

-- gfx is `require`d without an extension: doing so actually loads `gfx/init.t`,
-- which then loads the various submodules of gfx.
local gfx = require("gfx")

-- Likewise, this loads `math/init.t`, which loads various math submodules.
-- ("math" is also a builtin Lua module: the truss math module augments it with
--  additional classes and functions, without this `require` the plain Lua math
--  would still be available)
local math = require("math")

-- We will need SDL to create a window and handle events
local sdl = require("addons/sdl.t")

-- Although truss allows the main script to create globals, it's better practice
-- to avoid doing so. We'll store all our state into app_data.
local app_data = {}
local width, height = 1280, 720

-- A truss main script has to define two functions: `init` and `update`
function init()
  init_graphics()
  create_resources()
end

-- Have SDL create a window, and then init the graphics system using that
-- window.
function init_graphics()
  sdl.create_window(width, height, 'tetrahedron: medium level')

  -- Extra options, like msaa or vsync, are passed in here.
  gfx.init_gfx({msaa = true, window = sdl})
end

-- Create the resources we will need to draw a tetrahedron each frame.
function create_resources()

  -- First, we will create a geometry (mesh) for the tetrahedron.
  -- A tetrahedron has of course four vertices and four triangular faces, and
  -- we can specify those (along with vertex colors) as a normal Lua table.
  local geo_data = {
    indices = {{0,1,2}, {0,2,3}, {0,3,1}, {1,3,2}},
    attributes = {
      position = {{1,1,1}, {-1,1,-1}, {1,-1,-1}, {-1,-1,1}},
      color0 = {{255,0,0,255}, {255,150,0,255}, {32,32,255,255}, {128,128,255,255}}
    }
  }

  -- We then create a StaticGeometry from that data.
  -- The from_data function takes an optional vertex format argument:
  -- by omitting it we leave `:from_data` to pick a reasonable format based
  -- on the data's attributes.
  app_data.geo = gfx.StaticGeometry():from_data(geo_data)

  -- Create a matrix to hold the tetrahedron's pose, and a vector and
  -- quaternion to more easily manipulate it.
  app_data.model_mat = math.Matrix4():identity()
  app_data.pos_vec = math.Vector():identity()
  app_data.rot_quat = math.Quaternion():identity()

  -- Load a program, and create a draw state with back face culling disabled
  -- because we don't want to care about getting the triangle winding right.
  app_data.draw_state = gfx.create_state({cull = false})
  app_data.program = gfx.load_program("vs_cubes", "fs_cubes")

  -- We will need to draw this into a bgfx view, so create a View in slot 0 and
  -- set it to clear to a kind of brownish color.
  app_data.view = gfx.View(0)
  app_data.view:set_clear({color = 0x403030ff, depth = 1.0})

  -- The View will also need view and projection matrices.
  local view_matrix = math.Matrix4():identity()
  local proj_matrix = math.Matrix4():perspective_projection(60, width/height, 0.1, 100.0)
  app_data.view:set_matrices(view_matrix, proj_matrix)

  -- Calling `View:set` with no arguments causes it to rebind all its values,
  -- both those that have been explicitly set as well as truss defaults,
  -- into bgfx.
  app_data.view:set()
end

-- `update` is the other function that a truss main script must define. It is
-- called in a tight loop by the main thread.
local time = 0.0
function update()
  time = time + (1.0 / 60.0)

  -- Have the SDL module take care of dealing with window close
  -- events; if we didn't call this (or handle those events ourself),
  -- then the window could only be force closed, or killed from the terminal.
  sdl.handle_basic_events()

  -- Twiddle the position and rotation according to the time, and then
  -- compose them together into a 4x4 transformation matrix.
  app_data.pos_vec:set(0.0, math.cos(time*2), -5.0)
  app_data.rot_quat:euler({x = time*1.2, y = time, z = time*1.1})
  app_data.model_mat:compose(app_data.pos_vec, app_data.rot_quat)

  -- A bgfx draw call normally requires six things:
  -- * transformation matrix
  -- * vertex+index buffers (a bound geometry)
  -- * draw state
  -- * shader uniforms (this example's shader has none)
  -- * target view
  -- * program (vertex+fragment shader)
  gfx.set_transform(app_data.model_mat)
  app_data.geo:bind()
  gfx.set_state(app_data.draw_state)
  gfx.submit(app_data.view, app_data.program)

  -- Render this frame (with vsync on, this will block)
  gfx.frame()
end
