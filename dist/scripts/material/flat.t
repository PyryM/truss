-- material/flat.t
--
-- unlit materials

local m = {}
local class = require("class")
local math = require("math")
local gfx = require("gfx")

local FlatMaterial = gfx.define_base_material{
  name = "FlatMaterial",
  uniforms = {u_baseColor = 'vec'},
  state = {},
  program = {"vs_flat", "fs_flatsolid"}
}

local TexturedFlatMaterial = gfx.define_base_material{
  name = "TexturedFlatMaterial",
  uniforms = {u_baseColor = 'vec', s_texAlbedo = {kind = 'tex', sampler = 0}},
  state = {},
  program = {"vs_flat", "fs_flattextured"}
}

function m.FlatMaterial(options)
  local mat
  if options.texture then
    mat = TexturedFlatMaterial()
    mat.uniforms.s_texAlbedo:set(options.texture)
    local vs_name = "vs_flat"
    local fs_name = "fs_flattextured"
    if options.skybox then vs_name = "vs_flat_skybox" end
    if options.cubemap then
      vs_name, fs_name = "vs_flatcubemap", "fs_flatcubemap"
    end
    mat:set_program{vs_name, fs_name}
  else
    mat = FlatMaterial()
  end
  if options.state then
    mat:set_state(options.state)
  end
  mat.uniforms.u_baseColor:set(options.color or {1.0,1.0,1.0,1.0})
  return mat
end

-- TODO: port this?
--[[
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
]]

return m
