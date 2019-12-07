-- examples/newperf.t
--
-- performance experiments

local gfx = require("gfx")
local sdl = require("addon/sdl.t")
local math = require("math")
local geometry = require("geometry")
local pbr = require("shaders/pbr.t")
local compiled = require("gfx/compiled.t")
local bgfx = require("gfx/bgfx.t")

local width, height
local view
local view_mat, proj_mat

local pbr_globals
local box_geometry
local box_material

local mc_box_material
local mc_drawcall

local c_lights, c_drawcall
local mc_lights

local PbrMaterial = compiled.define_base_material{
  name = "PbrMaterial",
  uniforms = {
    u_baseColor = 'vec',
    u_pbrParams = 'vec',
    u_lightDir = {kind = 'vec', count = 4, global = true},
    u_lightRgb = {kind = 'vec', count = 4, global = true}
  },
  state = {},
  program = {"vs_basicpbr", "fs_basicpbr_faceted_x4"}
}

function PbrMaterial:roughness(r)
  self._value.u_pbrParams[0].w = r or 0.7
  return self
end

function PbrMaterial:tint(r, g, b)
  self._value.u_pbrParams[0].x = r or 1.0
  self._value.u_pbrParams[0].y = g or 1.0
  self._value.u_pbrParams[0].z = b or 1.0
  return self
end

function PbrMaterial:diffuse(r, g, b)
  self._value.u_baseColor[0].x = r or 1.0
  self._value.u_baseColor[0].y = g or 1.0
  self._value.u_baseColor[0].z = b or 1.0
  return self
end

function init()
  sdl.create_window(1280, 720, 'perftest')
  width, height = sdl.get_window_size()
  gfx.init_gfx{debugtext = true, window = sdl}

  proj_mat = math.Matrix4():perspective_projection(60, width/height, 0.01, 30.0)
  view_mat = math.Matrix4():identity()
  view = gfx.View{
    view_matrix = view_mat,
    proj_matrix = proj_mat,
    clear = {color = 0x808080ff, depth = 1.0}
  }

  pbr_globals = gfx.UniformSet()
  pbr_globals:merge(pbr.create_pbr_globals())
  pbr_globals.u_lightDir:set_multiple({
    math.Vector( 1.0,  1.0,  0.0),
    math.Vector(-1.0,  1.0,  0.0),
    math.Vector( 0.0, -1.0,  1.0),
    math.Vector( 0.0, -1.0, -1.0)}
  )
  pbr_globals.u_lightRgb:set_multiple({
    math.Vector(0.8, 0.8, 0.8),
    math.Vector(1.0, 1.0, 1.0),
    math.Vector(0.1, 0.1, 0.1),
    math.Vector(0.1, 0.1, 0.1)}
  )

  box_geometry = geometry.cube_geo{}
  box_material = pbr.FacetedPBRMaterial{
    diffuse = {0.2, 0.03, 0.01, 1.0}, 
    tint = {0.001, 0.001, 0.001}, 
    roughness = 0.7
  }

  --mc_box_material = compiled.CompiledMaterial(box_material)
  mc_box_material = PbrMaterial()
  --mc_box_material:set_state(box_material.state)
  --mc_box_material:set_program(box_material.program)
  mc_box_material:diffuse(0.2, 0.03, 0.01)
  mc_box_material:tint(0.001, 0.001, 0.001)
  mc_box_material:roughness(0.7)
  --mc_box_material._value.state = box_material.state

  c_lights = terralib.new(light_info_t)
  c_drawcall = terralib.new(draw_info_t)
  mc_lights = compiled.CompiledGlobals()
  mc_lights.u_lightDir:set_multiple({
    math.Vector( 1.0,  1.0,  0.0),
    math.Vector(-1.0,  1.0,  0.0),
    math.Vector( 0.0, -1.0,  1.0),
    math.Vector( 0.0, -1.0, -1.0)
  })
  mc_lights.u_lightRgb:set_multiple({
    math.Vector(0.8, 0.8, 0.8),
    math.Vector(1.0, 1.0, 1.0),
    math.Vector(0.1, 0.1, 0.1),
    math.Vector(0.1, 0.1, 0.1)
  })

  mc_drawcall = compiled.Drawcall(box_geometry, mc_box_material)

  stage_lights(pbr_globals, c_lights)
  stage_draw(box_geometry, box_material, view_mat, c_drawcall)
end

local tf = math.Matrix4():identity()
local pos = math.Vector()
local rot = math.Quaternion()
local scale = math.Vector(0.1, 0.1, 0.1)
function draw_box_old(x, y, theta)
  pos:set(x, y, -4.0)
  rot:euler({x = 0, y = theta, z = 0}, 'ZYX')
  tf:compose(pos, rot, scale)
  gfx.set_transform(tf)
  box_material:bind(pbr_globals)
  box_geometry:bind()
  gfx.submit(view, box_material.program)
end

function draw_box_compiled(x, y, theta)
  pos:set(x, y, -4.0)
  rot:euler({x = 0, y = theta, z = 0}, 'ZYX')
  tf:compose(pos, rot, scale)
  mc_drawcall:submit(view._viewid, mc_lights, tf)
  --gfx.set_transform(tf)
  --mc_box_material:bind(mc_lights)
  --box_geometry:bind()
  --gfx.submit(view, box_material.program)
end

struct light_info_t {
  light_dir_handle: bgfx.uniform_handle_t;
  light_dir_data: float[16];
  light_rgb_handle: bgfx.uniform_handle_t;
  light_rgb_data: float[16];
}

struct draw_info_t {
  vbh: bgfx.vertex_buffer_handle_t;
  ibh: bgfx.index_buffer_handle_t;
  u_color_handle: bgfx.uniform_handle_t;
  u_color_data: float[4];
  u_pbr_handle: bgfx.uniform_handle_t;
  u_pbr_data: float[4];
  tf: float[16];
  state: uint64;
  program: bgfx.program_handle_t;
}

terra fast_submit(lights: &light_info_t, draw: &draw_info_t)
  bgfx.set_transform(&draw.tf, 1)
  bgfx.set_vertex_buffer(0, draw.vbh, 0, bgfx.UINT32_MAX)
  bgfx.set_index_buffer(draw.ibh, 0, bgfx.UINT32_MAX)
  bgfx.set_uniform(draw.u_color_handle, &draw.u_color_data, 1)
  bgfx.set_uniform(draw.u_pbr_handle, &draw.u_pbr_data, 1)
  bgfx.set_uniform(lights.light_dir_handle, &lights.light_dir_data, 4)
  bgfx.set_uniform(lights.light_rgb_handle, &lights.light_rgb_data, 4)
  bgfx.set_state(draw.state, 0)
  bgfx.submit(0, draw.program, 0.0, false)
end

function draw_box_hand_compiled(x, y, theta)
  pos:set(x, y, -4.0)
  rot:euler({x = 0, y = theta, z = 0}, 'ZYX')
  tf:compose(pos, rot, scale)
  c_drawcall.tf = tf.data
  fast_submit(c_lights, c_drawcall)
end

function vec_to_floats(v, f, offset)
  offset = offset or 0
  f[0 + offset], f[1 + offset], f[2 + offset], f[3 + offset] = v.x, v.y, v.z, v.w
end

function stage_lights(globals, lights)
  lights.light_dir_handle = globals.u_lightDir._handle
  lights.light_rgb_handle = globals.u_lightRgb._handle
  for i = 0, 3 do
    vec_to_floats(globals.u_lightDir._val[i], lights.light_dir_data, i*4)
    vec_to_floats(globals.u_lightRgb._val[i], lights.light_rgb_data, i*4)
  end
end

function stage_draw(geo, mat, tf, draw)
  draw.vbh = geo._vbh
  draw.ibh = geo._ibh
  draw.u_color_handle = mat.uniforms.u_baseColor._handle
  draw.u_pbr_handle = mat.uniforms.u_pbrParams._handle
  vec_to_floats(mat.uniforms.u_baseColor._val[0], draw.u_color_data)
  vec_to_floats(mat.uniforms.u_pbrParams._val[0], draw.u_pbr_data)
  draw.tf = tf.data
  draw.state = mat.state
  draw.program = mat.program
end

function handle_events()
  for evt in sdl.events() do
    if evt.event_type == sdl.EVENT_WINDOW and evt.flags == 14 then
      truss.quit()
    end
  end
end

local t = 0.0

function update()
  t = t + 1.0 / 60.0

  handle_events()
  view:bind(0)
  view:touch()

  --local drawfunc = draw_box_old
  --local drawfunc = draw_box_hand_compiled
  local drawfunc = draw_box_compiled

  local t0 = truss.tic()
  for row = 1, 50 do
    for col = 1, 50 do
      local x, y = (col - 25)/10, (row - 25)/10
      local theta = t + row/5 + col/5
      drawfunc(x, y, theta)
    end
  end
  local dt = truss.toc(t0)

  bgfx.dbg_text_clear(0, false)
  bgfx.dbg_text_printf(2, 1, 0x6f, "dt: " .. dt * 1000.0)

  gfx.frame()
end