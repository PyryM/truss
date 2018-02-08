-- shaders/flat.t
--
-- unlit shaders/materials

local m = {}
local class = require("class")
local math = require("math")
local gfx = require("gfx")
local Material = require("graphics/material.t").Material

local flat_uniforms = {}
function m.create_flat_uniforms(has_texture)
  has_texture = not not has_texture -- coerce to boolean
  if flat_uniforms[has_texture] then return flat_uniforms[has_texture] end

  local uniforms = gfx.UniformSet()

  uniforms:add(gfx.VecUniform("u_baseColor"))
  if has_texture then
    uniforms:add(gfx.TexUniform("s_texAlbedo", 0))
  end

  flat_uniforms[has_texture] = uniforms
  return uniforms
end

local flat_3d_uniforms = nil
function m.create_flat_3d_uniforms()
  if not flat_3d_uniforms then 
    flat_3d_uniforms = gfx.UniformSet{
      u_baseColor = math.Vector(1.0, 1.0, 1.0, 1.0),
      u_volTexParams = math.Vector(0.0, 0.0, 0.0, 1.0)
    }
    flat_3d_uniforms:add(gfx.TexUniform("s_texVolume", 0))
  end
  return flat_3d_uniforms
end

function m.FlatMaterial(options)
  local vs_name = "vs_flat"
  local fs_name = "fs_flatsolid"
  if options.skybox then
    vs_name = "vs_flat_skybox"
  end
  if options.texture then
    if options.cubemap then
      vs_name = "vs_flatcubemap"
      fs_name = "fs_flatcubemap"
    else
      fs_name = "fs_flattextured"
    end
  end

  local mat = {
    state = options.state or gfx.create_state(),
    program = gfx.load_program(vs_name, fs_name),
    uniforms = m.create_flat_uniforms(options.texture):clone(),
    tags = options.tags
  }

  mat.uniforms.u_baseColor:set(options.color or {1.0,1.0,1.0,1.0})
  if options.texture and type(options.texture) == "table" then
    mat.uniforms.s_texAlbedo:set(options.texture)
  end

  return Material(mat)
end

function m.Flat3dTextured(options)
  local mat = {
    state = options.state or gfx.create_state(),
    program = gfx.load_program("vs_flat", "fs_flat_3dtex"),
    uniforms = m.create_flat_3d_uniforms():clone(),
    tags = options.tags
  }

  mat.uniforms.u_baseColor:set(options.color or {1.0,1.0,1.0,1.0})
  local volume_params = math.Vector(0.0, 0.0, 0.0, 1.0)
  if options.origin then
    volume_params:copy(options.origin)
    volume_params.elem.w = 1.0
  end
  if options.scale then
    volume_params.elem.w = options.scale
  end
  mat.uniforms.u_volTexParams:set(volume_params)
  if options.texture and type(options.texture) == "table" then
    mat.uniforms.s_texVolume:set(options.texture)
  end

  return Material(mat)
end

return m
