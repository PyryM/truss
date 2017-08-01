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
  self._render_ops = {} 
  self.stage_name = options.name or options.stage_name or "nanovg"
  -- self._render_ops = {self} -- the stage itself acts as a renderop

  if options.render then self.nvg_render = options.render end
  if options.setup then self.nvg_setup = options.setup end

  self.view = self:_create_view(options.view, options)
end

function NanoVGStage:set_nanovg_functions(nvg_setup, nvg_render)
  self.nvg_setup = nvg_setup
  self.nvg_render = nvg_render
  self._need_setup = true
end

function NanoVGStage:bind_view_ids(view_ids)
  NanoVGStage.super.bind_view_ids(self, view_ids)
  if self._ctx then -- reuse existing context for fonts etc.
    self._ctx:set_view(self.view)
  else
    self._ctx = nanovg.NVGContext(self.view, self.options.edge_aa)
    self._need_setup = true
  end
end

function NanoVGStage:update_begin()
  if not self._ctx then return end
  if self._need_setup and self.nvg_setup then 
    self:nvg_setup(self._ctx)
    self._need_setup = false
  end
  self._ctx:begin_frame(self.view)
  if self.nvg_render then self:nvg_render(self._ctx) end
end

function NanoVGStage:update_end()
  if not self._ctx then return end
  self._ctx:end_frame()
end

-- Let's ignore this for the moment until I rethink how ecs entities should
-- interact with nanovg rendering.
--
-- Right now the problem with this approach is that you get no control over
-- what order the entities are drawn in, which is important in nanovg since
-- there's no z buffering.
--[[
-----------------------------------------------
--- NanoVGStage acting as a RenderOperation ---
function NanoVGStage:matches(component)
  return component.nvg_render ~= nil
end

function NanoVGStage:render(component)
  component:nvg_render(self, self._ctx)
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
  if draw_func then self.nvg_render = draw_func end
  self._render_ops = {}
end

function m.NanoVGEntity(_ecs, name, draw_func)
  local ret = entity.Entity3d(_ecs, name)
  ret:add_component(NVGRenderComponent(draw_func))
  return ret
end
--]]

return m
