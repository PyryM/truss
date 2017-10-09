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

return m
