-- shaders/pbr.t
--
-- defines a basic pbr shader and material

local m = {}
local class = require("class")
local math = require("math")
local gfx = require("gfx")
local Material = require("graphics").Material

function m.create_pbr_uniforms()
  if m._pbr_uniforms then return m._pbr_uniforms end
  m._pbr_uniforms = gfx.UniformSet{
    u_baseColor = math.Vector(0.2,0.02,0.02,1.0),
    u_pbrParams = math.Vector(0.001, 0.001, 0.001, 0.7)
  }
  return m._pbr_uniforms
end

function m.create_pbr_tex_uniforms()
  if m._pbr_tex_uniforms then return m._pbr_tex_uniforms end
  m._pbr_tex_uniforms = m.create_pbr_uniforms():clone()
  m._pbr_tex_uniforms:add(gfx.TexUniform("s_texAlbedo", 0))
  return m._pbr_tex_uniforms
end

function m.create_pbr_globals()
  if m._pbr_globals then return m._pbr_globals end
  m._pbr_globals = gfx.UniformSet{
    gfx.VecArrayUniform("u_lightDir", 4), 
    gfx.VecArrayUniform("u_lightRgb", 4)
  }
  m._pbr_globals.u_lightDir:set_multiple({
          math.Vector( 1.0,  1.0,  0.0),
          math.Vector(-1.0,  1.0,  0.0),
          math.Vector( 0.0, -1.0,  1.0),
          math.Vector( 0.0, -1.0, -1.0)})
  m._pbr_globals.u_lightRgb:set_multiple({
          math.Vector(0.8, 0.8, 0.8),
          math.Vector(1.0, 1.0, 1.0),
          math.Vector(0.1, 0.1, 0.1),
          math.Vector(0.1, 0.1, 0.1)})
  return m._pbr_globals
end

local function _set_pbr_params(uniforms, opts)
  uniforms.u_baseColor:set(opts.diffuse or {0.2, 0.02, 0.02, 1.0})
  local roughness = opts.roughness or 0.7
  local tint = opts.tint or {0.001, 0.001, 0.001}
  uniforms.u_pbrParams:set(tint[1], tint[2], tint[3], roughness)

  if opts.texture and uniforms.s_texAlbedo then
    uniforms.s_texAlbedo:set(opts.texture)
  end
end

function m.TexPBRMaterial(opts)
  local mat = {
    state = gfx.create_state(),
    program = gfx.load_program("vs_basicpbr_tex", 
                opts.fshader or "fs_basicpbr_x4_tex"),
    uniforms = m.create_pbr_tex_uniforms():clone(),
    global_uniforms = m.create_pbr_globals(),
    tags = opts.tags
  }
  _set_pbr_params(mat.uniforms, opts or {})
  return Material(mat)
end

function m.PBRMaterial(opts)
  local mat = {
    state = gfx.create_state(),
    program = gfx.load_program("vs_basicpbr", 
                opts.fshader or "fs_basicpbr_x4"),
    uniforms = m.create_pbr_uniforms():clone(),
    global_uniforms = m.create_pbr_globals()
  }
  _set_pbr_params(mat.uniforms, opts or {})
  return Material(mat)
end

function m.FacetedPBRMaterial(opts)
  opts.fshader = "fs_basicpbr_faceted_x4"
  return m.PBRMaterial(opts)
end

function m.FacetedTexPBRMaterial(opts)
  opts.fshader = "fs_basicpbr_faceted_x4_tex"
  return m.TexPBRMaterial(opts)
end

return m
