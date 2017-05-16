-- shaders/pbr.t
--
-- defines a basic pbr shader and material

local m = {}
local class = require("class")
local math = require("math")
local gfx = require("gfx")
local Material = require("graphics/material.t").Material

function m.create_pbr_uniforms()
  if m._pbr_uniforms then return m._pbr_uniforms end

  local uniforms = gfx.UniformSet()
  uniforms:add(gfx.VecUniform("u_baseColor"))
  uniforms:add(gfx.VecUniform("u_pbrParams"))
  uniforms:add(gfx.VecUniform("u_lightDir", 4))
  uniforms:add(gfx.VecUniform("u_lightRgb", 4))

  uniforms.u_lightDir:set_multiple({
          math.Vector( 1.0,  1.0,  0.0),
          math.Vector(-1.0,  1.0,  0.0),
          math.Vector( 0.0, -1.0,  1.0),
          math.Vector( 0.0, -1.0, -1.0)})

  uniforms.u_lightRgb:set_multiple({
          math.Vector(0.8, 0.8, 0.8),
          math.Vector(1.0, 1.0, 1.0),
          math.Vector(0.1, 0.1, 0.1),
          math.Vector(0.1, 0.1, 0.1)})

  uniforms.u_baseColor:set(math.Vector(0.2,0.02,0.02,1.0))
  uniforms.u_pbrParams:set(math.Vector(0.001, 0.001, 0.001, 0.7))
  m._pbr_uniforms = uniforms
  return m._pbr_uniforms
end

function m.PBRMaterial(diffuse, tint, roughness, fshader)
  local mat = {
    state = gfx.create_state(),
    program = gfx.load_program("vs_basicpbr", fhsader or "fs_basicpbr_x4"),
    uniforms = m.create_pbr_uniforms():clone()
  }
  mat.uniforms.u_baseColor:set(diffuse or {0.2,0.02,0.02,1.0})
  tint = tint or {0.001, 0.001, 0.001}
  mat.uniforms.u_pbrParams:set({tint[1], tint[2], tint[3], roughness or 0.7})
  return Material(mat)
end

function m.FacetedPBRMaterial(diffuse, tint, roughness)
  return m.PBRMaterial(diffuse, tint, roughness, "fs_basicpbr_faceted_x4")
end

return m
