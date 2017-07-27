-- graphics/composite.t
--
-- a simple stage for compositing a bunch of things together
-- (e.g., for splitscreen)

local gfx = require("gfx")
local math = require("math")
local stage = require("graphics/stage.t")
local m = {}

local CompositeStage = stage.Stage:extend("CompositeStage")
m.CompositeStage = CompositeStage
function CompositeStage:init(options)
  options = options or {}
  self._num_views = 1
  self._render_ops = {}
  self.composite_ops = {}
  self.options = options
  self.options.proj_matrix = math.Matrix4():orthographic_projection(0, 1, 0, 1, -1, 1)
  self.options.view_matrix = math.Matrix4():identity()
  self._identity_mat = math.Matrix4():identity()
  self._quad_geo = gfx.TransientGeometry()
  self._material = options.material or self:create_default_material(options.shader)
  for k,v in pairs(options.ops or {}) do
    self:add_composite_operation(k, v)
  end
end

function CompositeStage:create_default_material(shader)
  local Material = require("graphics/material.t").Material
  return Material{
    state = gfx.create_state(),
    program = gfx.load_program("vs_fullscreen", shader or "fs_fullscreen_copy"),
    uniforms = gfx.UniformSet{gfx.TexUniform("s_srcTex", 0)}
  }
end

function CompositeStage:add_composite_operation(name, op)
  self.composite_ops[name] = op
end

function CompositeStage:composite(op)
  gfx.set_transform(self._identity_mat) -- not strictly necessary
  self._quad_geo:quad(op.x0, op.y0, op.x1, op.y1, 0.0):bind()
  local mat = op.material or self._material
  if op.source then mat.uniforms.s_srcTex:set(op.source) end
  mat:bind()
  gfx.submit(self.view, mat.program)
end

function CompositeStage:update_begin()
  for _, op in pairs(self.composite_ops) do
    self:composite(op)
  end
end

return m
