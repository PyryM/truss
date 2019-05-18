-- new_readback.moon
--
-- example of reading back a texture

App = require("app/app.t").App
geometry = require "geometry"
graphics = require "graphics"
gfx = require "gfx"
pbr = require "material/pbr.t"
flat = require "material/flat.t"
ecs = require "ecs"
math = require "math"
ms = require "moonscript"
async = require "async"
orbitcam = require "graphics/orbitcam.t"
simplex = require "procgen/simplex.t"

tex_size = 1024

class NoiseTextureApp extends ms.wrap_lua_class(App)
  init_pipeline: (options) =>
    super options
    @worldtarget = gfx.ColorDepthTarget {
      width: tex_size
      height: tex_size
      color_format: gfx.TEX_RGBA32F
    }
    @worldreadback = gfx.ReadbackTexture @worldtarget
    @worldspacestage = @pipeline\add_stage graphics.Stage {
      name: "worldspace"
      clear: {color: 0x000000ff, depth: 1.0}
      globals: @pipeline.globals
      render_ops: {graphics.DrawOp!, graphics.CameraControlOp!}
      filter: (tags) -> tags.is_camera or tags.worldspace
      render_target: @worldtarget
    }

export app

simplex_iter = (scales, offsets) ->
  offsets = offsets or [{math.random(), math.random(), math.random()} for scale in *scales]
  (x, y, z) ->
    for idx, s in ipairs scales
      o1, o2, o3 = unpack offsets[idx]
      nx = simplex.simplex_3d x*s+o1, y*s+o1, z*s+o1
      ny = simplex.simplex_3d x*s+o2, y*s+o2, z*s+o2
      nz = simplex.simplex_3d x*s+o3, y*s+o3, z*s+o3
      x, y, z = nx, ny, nz
    x, y, z

functex = (src_data, f) ->
  ret = gfx.Texture2d {width: tex_size, height: tex_size, format: gfx.TEX_BGRA8}
  data_pos = 0
  for y = 0, tex_size-1
    for x = 0, tex_size-1
      x, y, z = src_data[data_pos+0], src_data[data_pos+1], src_data[data_pos+2]
      fval = f(x, y, z)*0.5 + 0.5
      fval = math.max(0.0, math.min(1.0, fval))
      ret.cdata[data_pos+0] = 255 * fval
      ret.cdata[data_pos+1] = 255 * fval
      ret.cdata[data_pos+2] = 255 * fval
      ret.cdata[data_pos+3] = 255
      data_pos += 4
  ret\commit!

export init = ->
  app = NoiseTextureApp {
    width: 1280, 
    height: 720,
    title: "readback example",
    msaa: true
  }
  print(app)
  app.camera\add_component orbitcam.OrbitControl {min_rad:1, max_rad: 4}

  worldspace_material = gfx.anonymous_material {
    uniforms: {}
    program: {"vs_unwrap", "fs_unwrap_worldpos"}
    state: {cull: false}
    tags: {worldspace: true}
  }

  geo = geometry.uvsphere_geo {lat_divs: 30, lon_divs: 30}
  mat = flat.FlatMaterial{
    diffuse: {0.2, 0.2, 0.2, 1.0}
    tint: {0.001, 0.001, 0.001}
    roughness: 0.7
    texture: gfx.Texture "textures/test_pattern.png"
  }

  thingy = app.scene\create_child graphics.Mesh, "mesh", geo, worldspace_material
  (async.run ->
    async.await_frames 2
    async.await app.worldreadback\async_read_rt!
    print(app.worldreadback.cdatalen)
    mat.uniforms.s_texAlbedo\set functex app.worldreadback.cdata, (simplex_iter {1, 0.4, 2.2})
    thingy.mesh\set_material mat
  )\next print, print

export update = ->
  app\update!
