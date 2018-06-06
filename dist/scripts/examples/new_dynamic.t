-- new_dynamic.t
--

local sdl = require("addons/sdl.t")
local math = require("math")
local gfx = require("gfx")
local geoutils = require("geometry/geoutils.t")
local simplex = require("procgen/simplex.t")

width = 800
height = 600
time = 0.0

function update_events()
  for evt in sdl.events() do
    if evt.event_type == sdl.EVENT_WINDOW and evt.flags == 14 then
      truss.quit()
    elseif evt.event_type == sdl.EVENT_KEYDOWN and ffi.string(evt.keycode) == "F12" then
      print("Saving screenshot!")
      gfx.save_screenshot("screenshot.png")
    end
  end
end

function create_uniforms()
  uniforms = gfx.UniformSet()
  uniforms:add(gfx.VecUniform("u_baseColor"))
  uniforms:add(gfx.VecUniform("u_pbrParams"))
  uniforms:add(gfx.VecUniform("u_lightDir", 4))
  uniforms:add(gfx.VecUniform("u_lightRgb", 4))

  uniforms.u_lightDir:set_multiple({
          math.Vector( 1.0,  1.0,  0.0),
          math.Vector(-1.0,  1.0,  0.0),
          math.Vector( 0.0, -1.0,  1.0),
          math.Vector( 0.0, -1.0, -1.0)})

  uniforms.u_lightRgb:set_multiple({
          math.Vector(0.8, 0.8, 0.8),
          math.Vector(1.0, 1.0, 1.0),
          math.Vector(0.1, 0.1, 0.1),
          math.Vector(0.1, 0.1, 0.1)})

  uniforms.u_baseColor:set(math.Vector(0.2,0.2,0.1,1.0))
  uniforms.u_pbrParams:set(math.Vector(1.0, 1.0, 1.0, 0.6))
end

local function chained_simplex(x, y, z, mults)
  for _, m in ipairs(mults) do
    local nx = simplex.simplex_3d(x*m, y*m, z*m)
    local ny = simplex.simplex_3d((x+0.2)*m, (y+0.2)*m, (z+0.2)*m)
    local nz = simplex.simplex_3d((x+0.3)*m, (y+0.3)*m, (z+0.3)*m)
    x, y, z = nx, ny, nz
  end
  return x, y, z
end

function update_geo(geo)
  local nverts = geo.n_verts
  local mult = 0.00001
  for i = 0,(nverts-1) do
    local pos = geo.verts[i].position
    local x, y, z = pos[0], pos[1], pos[2]
    -- local dx = simplex.simplex_3d(x*2, y*2, z*2)
    -- dx = dx * dx * mult
    -- dx = dx * simplex.simplex_3d(x*7, y*7, z*7)
    -- local dy = simplex.simplex_3d(x*2+5,y*2+5,z*2+5)
    -- dy = dy * dy * mult
    -- dy = dy * simplex.simplex_3d(x*7+10, y*7-5, z*7+9)
    -- local dz = simplex.simplex_3d(x*2-5,y*2-5,z*2-5)
    -- dz = dz * dz * mult
    -- dz = dz * simplex.simplex_3d(x*7-3, y*7+3, z*7-5)
    local dx, dy, dz = chained_simplex(x, y, z, {1,1.1})
    pos[0], pos[1], pos[2] = x+(dx*mult), y+(dy*mult), z+(dz*mult)
  end
  geo:update_vertices() -- could also do geo:update()
end

function create_geo()
  local r = 0.75
  --local data = require("geometry/cube.t").cube_data(r,r,r)
  local data = require("geometry").icosahedron_data{radius = r}
  data.attributes.texcoord0 = nil

  for i = 1,6 do
    data = geoutils.subdivide(data)
  end

  return gfx.DynamicGeometry("tri"):from_data(data)
end

function init()
  -- basic init
  sdl.create_window(width, height, '00 buffercube')
  gfx.init_gfx({msaa = true, debugtext = true, window = sdl})

  -- set up our one view (rendering directly to backbuffer)
  view = gfx.View():bind(0)
  view:set_clear({color = 0x303030ff, depth = 1.0})
  view:set_viewport(false)

  -- init the cube
  cubegeo = create_geo()

  -- load shader program
  --program = gfx.load_program("vs_cubes", "fs_cubes")
  program = gfx.load_program("vs_basicpbr", "fs_basicpbr_faceted_x4")
  create_uniforms()

  -- create matrices
  projmat = math.Matrix4():perspective_projection(70, width/height, 0.1, 100.0)
  viewmat = math.Matrix4():identity()
  modelmat = math.Matrix4():identity()
  posvec = math.Vector(0.0, 0.0, -10.0)
  rotquat = math.Quaternion():identity()

  cubestate = gfx.create_state({cull = false})
end

function draw_stuff(xpos, ypos, phase)
  -- Compute the cube's transformation
  rotquat:euler({x = 0.0, y = time*0.2 + phase, z = 0.0}, 'ZYX')
  posvec:set(xpos, ypos, -4.0)
  modelmat:compose(posvec, rotquat)
  gfx.set_transform(modelmat)

  update_geo(cubegeo)

  -- Bind the cube buffers
  cubegeo:bind()

  -- uniforms (if they exist)
  if uniforms then uniforms:bind() end

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

  bgfx.dbg_text_printf(0, 1, 0x4f, "scripts/examples/new_dynamic.t")
  bgfx.dbg_text_printf(0, 2, 0x6f, "frame time: " .. frametime*1000.0 .. " ms")

  -- Set viewprojection matrix
  view:set_matrices(viewmat, projmat)

  -- draw
  draw_stuff(0.0, 0.0, 0.0)

  -- Advance to next frame.
  gfx.frame()

  frametime = truss.toc(start_time)
end
