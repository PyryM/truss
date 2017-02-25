-- graphics/nanovg.t
--
-- ecs nanovg adapters

local gfx = require("gfx")
local math = require("math")
local pipeline = require("graphics/pipeline.t")
local entity = require("ecs/entity.t")
local nanovg = require("addons/nanovg.t")
local m = {}

local NanoVGStage = pipeline.Stage:extend("NanoVGStage")
m.NanoVGStage = NanoVGStage

function NanoVGStage:init(options, ops)
  options = options or {}
  self.options = options
  self.num_views = 1
  self.enabled = true
  self.filter = options.filter
  self.globals = options or {}
  self._render_ops = {self} -- the stage itself acts as a renderop
  for _, op in ipairs(ops or {}) do self:add_render_op(op) end

  if options.draw then self.nvg_draw = options.draw end
  if options.setup then self.nvg_setup = options.setup end
end

function NanoVGStage:set_views(views)
  NanoVGStage.super.set_views(self, views)
  self._ctx = nanovg.NVGContext(self.view._viewid, self.options.edge_aa)
  bgfx.set_view_seq(self.view._viewid, true)
  if self.nvg_setup then self:nvg_setup(self._ctx) end
end

function NanoVGStage:update_begin()
  if not self._ctx then return end
  self._ctx:begin_frame(self.view)
  if self.nvg_draw then self:nvg_draw(self._ctx) end
end

function NanoVGStage:update_end()
  if not self._ctx then return end
  self._ctx:end_frame()
end

-----------------------------------------------
--- NanoVGStage acting as a RenderOperation ---
function NanoVGStage:matches(component)
  return component.nvg_draw ~= nil
end

function NanoVGStage:draw(component)
  component:nvg_draw(self, self._ctx)
end

function NanoVGStage:set_stage(stage)
  -- just need this for compatibility
end
-----------------------------------------------

function NanoVGStage:duplicate()
  truss.error("NanoVGStage does not implement duplicate.")
end

local NanoVGDrawable = pipeline.DrawableComponent:extend("NanoVGDrawable")
m.NanoVGDrawable = NanoVGDrawable

function NanoVGDrawable:init(draw_func)
  self.nvg_draw = draw_func
end
NanoVGDrawable.on_update = pipeline.DrawableComponent.draw

function m.NanoVGEntity(name, draw_func)
  local ret = entity.Entity3d(name)
  ret:add_component(NanoVGDrawable(draw_func))
  return ret
end

return m
