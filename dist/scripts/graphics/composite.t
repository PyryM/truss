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
  for k,v in pairs(options.composite_ops or options.ops or {}) do
    self:set_op(k, v)
  end
  -- TODO: factor this out/into Stage
  if options.view and options.view.bind then -- an actual gfx.View
    self.view = options.view
  else -- options.view is a table, or use options as the view options
    self.view = gfx.View(options.view or options)
  end
end

m.BasicCompositeMaterial = gfx.define_base_material{
  name = "BasicCompositeMaterial",
  uniforms = {s_srcTex = {kind = 'tex', sampler = 0}},
  state = {}
}

function CompositeStage:create_default_material(shader)
  local program = gfx.load_program("vs_fullscreen", shader or "fs_fullscreen_copy")
  return m.BasicCompositeMaterial():set_program(program)
end

function CompositeStage:set_op_visibility(name, visible)
  local dest = self.composite_ops[name]
  if not dest then
    truss.error("No composite operation with name" .. name .. " to move.")
  end
  dest.visible = visible  
end

function CompositeStage:set_op(name, op)
  self.composite_ops[name] = op
end

function CompositeStage:move_op(name, op)
  local dest = self.composite_ops[name]
  if not dest then
    truss.error("No composite operation with name" .. name .. " to move.")
  end
  dest.x0 = op.x0
  dest.y0 = op.y0
  dest.x1 = op.x1
  dest.y1 = op.y1
  dest.w = op.w
  dest.h = op.h
  dest.mode = op.mode
end

function CompositeStage:_op_to_floats(op)
  local x0, y0, x1, y1 = op.x0, op.y0, op.x1, op.y1
  local w, h = op.w, op.h
  local dst_w, dst_h = self.view:get_active_dimensions()
  if op.mode == "pixel" then
    x0 = x0 / dst_w
    y0 = y0 / dst_h
    if w then w = w / dst_w end
    if h then h = h / dst_h end
    if x1 then x1 = x1 / dst_w end
    if y1 then y1 = y1 / dst_h end
  end
  if (not x1) or (not y1) then
    if (not w) or (not h) then
      local src_w, src_h = op.source.width, op.source.height
      w = src_w / dst_w
      h = src_h / dst_h
    end
    x1 = x0 + w
    y1 = y0 + h
  end
  return x0, y0, x1, y1, op.depth or 0.0
end

function CompositeStage:composite(op)
  gfx.set_transform(self._identity_mat) -- not strictly necessary
  self._quad_geo:quad(self:_op_to_floats(op)):bind()
  local mat = op.material or self._material
  if op.source then mat.uniforms.s_srcTex:set(op.source) end
  mat:bind()
  gfx.submit(self.view, mat._value.program)
end

function CompositeStage:pre_render()
  for _, op in pairs(self.composite_ops) do
    if op.visible ~= false then
      self:composite(op)
    end
  end
end

-- convenience function to create a stage that composites the entire screen
-- e.g., for postprocessing effects
function m.FullscreenStage(options)
  options = options or {}
  options.ops = {fullscreen = {x0 = 0, y0 = 0, x1 = 1, y1 = 1,
                               source = options.input}}
  return CompositeStage(options)
end

return m
