local math = require("math")
local Vector = math.Vector
local imapp = require("app/immediateapp.t")
local pbr = require("material/pbr.t")
local geometry = require("geometry")
local gfx = require("gfx")
local imwrite = require("io/imagewrite.t")

local function make_model()
  local geo = geometry.icosphere_geo{}
  local mat = pbr.FacetedPBRMaterial{
    diffuse = {0.2, 0.03, 0.01, 1.0}, 
    tint = {0.001, 0.001, 0.001}, 
    roughness = 0.7,
  }
  mat.uniforms.u_lightDir:set_multiple({
    Vector( 1.0,  1.0,  0.0),
    Vector(-1.0,  1.0,  0.0),
    Vector( 0.0, -1.0,  1.0),
    Vector( 0.0, -1.0, -1.0)})
  mat.uniforms.u_lightRgb:set_multiple({
    Vector(0.8, 0.8, 0.8),
    Vector(1.0, 1.0, 1.0),
    Vector(0.1, 0.1, 0.1),
    Vector(0.1, 0.1, 0.1)})

  return geo, mat
end

local function render(ctx)
  local geo, mat = make_model()
  local target = gfx.ColorDepthTarget{width = 256, height = 256}
  local readback = gfx.ReadbackTexture(target)

  ctx:await_view{
    proj_matrix = math.Matrix4():orthographic_projection(
      -1, 1,
      -1, 1, 
      0.0, 10.0, false
    ),
    view_matrix = math.Matrix4():identity(),
    clear = {color = 0xffffffff, depth = 1.0},
    render_target = target
  }
  ctx:draw_mesh(geo, mat, math.Matrix4():translation(
    math.Vector(0.0, 0.0, -3.0)
  ))

  local blit_view = ctx:await_view{clear=false}
  print("Reading back?")
  ctx:await(readback:async_read_rt(blit_view))

  local data = ffi.string(readback.cdata, readback.cdatalen)
  local dest = io.open("data.raw", "wb")
  dest:write(data)
  dest:close()
  imwrite.write_tga(256, 256, readback.cdata, "headless.tga")

  print("Done!")
  truss.quit()
end

function init()
  app = imapp.ImmediateApp{
    headless = true,
    backend = "vulkan",
    width = 1280, height = 720, -- doesn't matter in headless
    num_views = 32,
    immediate_func = render,
  }
end

function update()
  app:update()
end