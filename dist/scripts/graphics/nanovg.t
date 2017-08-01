-- graphics/nanovg.t
--
-- ecs nanovg adapters

local gfx = require("gfx")
local math = require("math")
local ecs = require("ecs")
local stage = require("graphics/stage.t")
local renderer = require("graphics/renderer.t")
local nanovg = require("addons/nanovg.t")
local m = {}

local NanoVGStage = stage.Stage:extend("NanoVGStage")
m.NanoVGStage = NanoVGStage

function NanoVGStage:init(options)
  options = options or {}
  self.options = options
  self._num_views = 1
  self.filter = options.filter
  self.globals = options or {}
  self._render_ops = {self} -- the stage itself acts as a renderop

  if options.draw then self.nvg_draw = options.draw end
  if options.setup then self.nvg_setup = options.setup end

  self.view = self:_create_view(options.view, options)
end

function NanoVGStage:bind_view_ids(view_ids)
  NanoVGStage.super.bind_view_ids(self, view_ids)
  if self._ctx then -- reuse existing context for fonts etc.
    self._ctx:set_view(self.view)
  else
    self._ctx = nanovg.NVGContext(self.view, self.options.edge_aa)
  end
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

function NanoVGStage:render(component)
  component:nvg_draw(self, self._ctx)
end

function NanoVGStage:to_function(context)
  return function(component)
    self:render(component)
  end
end
-----------------------------------------------

local NVGRenderComponent = renderer.RenderComponent:extend("NVGRenderComponent")
m.NVGRenderComponent = NVGRenderComponent

function NVGRenderComponent:init(draw_func)
  self.nvg_draw = draw_func
  self._render_ops = {}
end

function m.NanoVGEntity(name, draw_func)
  local ret = entity.Entity3d(name)
  ret:add_component(NVGRenderComponent(draw_func))
  return ret
end

return m
