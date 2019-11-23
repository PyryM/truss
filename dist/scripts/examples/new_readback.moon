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
objloader = require "formats/obj.t"

TEX_SIZE = 512

export app

class NoiseTextureApp extends ms.wrap_lua_class(App)
  init_pipeline: (options) =>
    super options
    @worldtarget = gfx.ColorDepthTarget {
      width: TEX_SIZE
      height: TEX_SIZE
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

deepprint = (t) ->
  if (type t) == 'table'
    '{' .. (table.concat [deepprint v for v in *t], ', ') .. '}'
  else
    tostring t

simplex_iter = (scales, offsets) ->
  offsets = offsets or [{math.random(), math.random(), math.random()} for scale in *scales]
  print "Offsets: #{deepprint offsets}"
  (x, y, z) ->
    for idx, s in ipairs scales
      o1, o2, o3 = unpack offsets[idx]
      nx = simplex.simplex_3d x*s+o1, y*s+o1, z*s+o1
      ny = simplex.simplex_3d x*s+o2, y*s+o2, z*s+o2
      nz = simplex.simplex_3d x*s+o3, y*s+o3, z*s+o3
      x, y, z = nx, ny, nz
    x, y, z

functex = (src_data, f) ->
  ret = gfx.Texture2d {
    width: TEX_SIZE
    height: TEX_SIZE
    format: gfx.TEX_BGRA8
    sampler_flags: {min: 'point', mag: 'point', mip: 'point'}
  }
  data_pos = 0
  for y = 0, TEX_SIZE-1
    for x = 0, TEX_SIZE-1
      dx, dy, dz = src_data[data_pos+0], src_data[data_pos+1], src_data[data_pos+2]
      fval = f(dx, dy, dz)
      fval = fval*fval
      fval = math.max(0.0, math.min(1.0, fval))
      ret.cdata[data_pos+0] = 255 * fval
      ret.cdata[data_pos+1] = 255 * fval
      ret.cdata[data_pos+2] = 255 * fval
      ret.cdata[data_pos+3] = 255
      data_pos += 4
  print ret.cdatalen
  print data_pos
  ret\commit!
  print "Done?"
  ret

export init = ->
  app = NoiseTextureApp {
    width: 160*4, 
    height: 128*4,
    title: "readback example",
    msaa: 4,
    lowlatency: true
  }
  print(app)
  app.camera\add_component orbitcam.OrbitControl {min_rad:1, max_rad: 6}

  worldspace_material = gfx.anonymous_material {
    uniforms: {}
    program: {"vs_unwrap", "fs_unwrap_worldpos"}
    state: {cull: false, conservative_raster: true}
    tags: {worldspace: true}
  }

  geo = geometry.uvsphere_geo {lat_divs: 100, lon_divs: 100}
  --nef_data = objloader.load_obj "models/nefertiti.obj"
  --geo = (gfx.StaticGeometry "nefertiti")\from_data nef_data
  mat = pbr.PBRMaterial{
  --mat = flat.FlatMaterial {
    diffuse: {0.3, 0.3, 0.3, 1.0}
    tint: {0.0001, 0.0001, 0.0001}
    roughness: 0.9
    texture: gfx.Texture "textures/test_pattern.png"
  }

  thingy = app.scene\create_child graphics.Mesh, "mesh", geo, worldspace_material
  (async.run ->
    async.await_frames 2
    async.await app.worldreadback\async_read_rt!
    math.randomseed os.time!
    params = [math.random()*2+0.1 for i = 1, 5]
    -- params = {0.61785367958337, 1.468127624769, 1.0674999336985, 0.3239912787326, 0.2920686542582}
    -- offsets = {
    --   {0.2432165380997, 0.13982819347398, 0.52681274830541}, 
    --   {0.135840326757, 0.58978198115652, 0.22391026296928}, 
    --   {0.32250554193491, 0.69189412381901, 0.30062938423033}, 
    --   {0.97589247542295, 0.70570132942719, 0.55416672796644}, 
    --   {0.71519881287114, 0.020820594290811, 0.090423313346118}
    -- }
    print "params: #{table.concat params, ' '}" 
    mat.uniforms.s_texAlbedo\set functex app.worldreadback.cdata, (simplex_iter params, offsets)
    thingy.mesh\set_material mat
  )\next print, print

export update = ->
  app\update!
