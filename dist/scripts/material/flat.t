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
  uniforms = {
    u_baseColor = 'vec',
    u_uvParams = 'vec', 
    s_texAlbedo = {kind = 'tex', sampler = 0}},
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
    if options.texture:is_cubemap() then
      vs_name, fs_name = "vs_flatcubemap", "fs_flatcubemap"
    elseif options.texture.depth > 1 then
      vs_name, fs_name = "vs_flat", "fs_flat_3dtex"
      local vparams = {0, 0, 0, 1}
      if options.origin then 
        vparams[1], vparams[2], vparams[3] = unpack(options.origin)
      end
      if options.scale then
        vparams[4] = options.scale
      end
      mat.uniforms.u_uvParams:set(vparams)
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

return m
