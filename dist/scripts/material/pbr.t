-- material/basicpbr.t
--
-- basic pbr materials

local gfx = require("gfx")
local m = {}

local PbrMaterial = gfx.define_base_material{
  name = "PbrMaterial",
  uniforms = {
    u_baseColor = 'vec',
    u_pbrParams = 'vec',
    u_lightDir = {kind = 'vec', count = 4, global = true},
    u_lightRgb = {kind = 'vec', count = 4, global = true}
  },
  state = {},
  program = {"vs_basicpbr", "fs_basicpbr_x4"}
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

local TexPbrMaterial = gfx.define_base_material{
  name = "TexPbrMaterial",
  uniforms = {
    u_baseColor = 'vec',
    u_pbrParams = 'vec',
    s_texAlbedo = {kind = 'tex', sampler = 0},
    u_lightDir = {kind = 'vec', count = 4, global = true},
    u_lightRgb = {kind = 'vec', count = 4, global = true},
  },
  state = {},
  program = {"vs_basicpbr_tex", "fs_basicpbr_x4_tex"}
}
TexPbrMaterial.roughness = PbrMaterial.roughness
TexPbrMaterial.tint = PbrMaterial.tint
TexPbrMaterial.diffuse = PbrMaterial.diffuse

function TexPbrMaterial:texture(tex)
  self.uniforms.s_texAlbedo:set(tex)
  return self
end

local function set_pbr_options(mat, opts)
  opts = opts or {}
  local uniforms = mat.uniforms
  uniforms.u_baseColor:set(opts.diffuse or {0.2, 0.02, 0.02, 1.0})
  local roughness = opts.roughness or 0.7
  local tint = opts.tint or {0.001, 0.001, 0.001}
  uniforms.u_pbrParams:set(tint[1], tint[2], tint[3], roughness)
  if opts.texture and uniforms.s_texAlbedo then
    uniforms.s_texAlbedo:set(opts.texture)
  end
end

-- TODO: handle textures
function m.PBRMaterial(options)
  local ret = (options.texture and TexPbrMaterial()) or PbrMaterial()
  set_pbr_options(ret, options)
  return ret
end

function m.FacetedPBRMaterial(options)
  local ret = (options.texture and TexPbrMaterial()) or PbrMaterial()
  local vs, fs = "vs_basicpbr", "fs_basicpbr_faceted_x4"
  if options.texture then
    vs = vs .. "_tex" 
    fs = fs .. "_tex" 
  end
  ret:set_program{vs, fs}
  set_pbr_options(ret, options)
  return ret
end


return m