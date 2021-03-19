-- graphics/nanovg.t
--
-- ecs/graphics nanovg adapters

local gfx = require("gfx")
local math = require("math")
local ecs = require("ecs")
local stage = require("graphics/stage.t")
local renderer = require("graphics/renderer.t")
local nanovg = require("addon/nanovg.t")
local m = {}

local NanoVGStage = stage.Stage:extend("NanoVGStage")
m.NanoVGStage = NanoVGStage

function NanoVGStage:init(options)
  options = options or {}
  NanoVGStage.super.init(self, options)
  self.stage_name = options.name or options.stage_name or "nanovg"
  self._opfunc = function(component, tf)
    self:_add_draw_item(component)
  end
  if options.draw then self.nvg_draw = options.draw end
  if options.setup then self.nvg_setup = options.setup end
  if options.render then truss.error("render was renamed to draw") end
end

function NanoVGStage:set_nanovg_functions(nvg_setup, nvg_draw)
  self.nvg_setup = nvg_setup
  self.nvg_draw = nvg_draw
  self._context_changed = true
end

function NanoVGStage:bind(start_id, num_views)
  NanoVGStage.super.bind(self, start_id, num_views)
  if self._ctx then -- reuse existing context for fonts etc.
    self._ctx:set_view(self.view)
  else
    self._ctx = nanovg.NVGContext(self.view, self.options.edge_aa)
    self._context_changed = true
  end
end

function NanoVGStage:pre_render()
  self._items = {}
  if not self._ctx then return end
  self._ctx:begin_frame(self.view)
end

function NanoVGStage:_add_draw_item(item)
  table.insert(self._items, {item.z_order or 0.0, item})
end

function NanoVGStage:post_render()
  if not self._ctx then return end
  table.sort(self._items, function(item1, item2)
    -- sort in decreasing order of depth, so that smaller depth items
    -- are drawn later (on top)
    return item1[1] > item2[1]
  end)
  local ctx = self._ctx
  if self._context_changed then
    for _, item in ipairs(self._items) do
      if item[2].nvg_setup then item[2]:nvg_setup(ctx) end
    end
    if self.nvg_setup then self:nvg_setup(ctx) end
    self._context_changed = false
  end
  for _, item in ipairs(self._items) do
    item[2]:nvg_draw(ctx)
  end
  if self.nvg_draw then self:nvg_draw(ctx) end
  ctx:end_frame()
end

function NanoVGStage:match(tags, target)
  target = target or {}
  if not self.enabled then return target end
  if self.filter and not (self.filter(tags)) then return target end
  if tags.nanovg_drawable then
    table.insert(target, self._opfunc)
  end
  return target
end

local NanoVGComponent = renderer.RenderComponent:extend("NanoVGComponent")
m.NanoVGComponent = NanoVGComponent

function NanoVGComponent:init(options)
  options = options or {}
  self._setup = options.setup
  self._draw = options.draw
  self.z_order = options.z_order or 0.0
  self.tags = gfx.tagset{nanovg_drawable = true}
end

function NanoVGComponent:nvg_setup(ctx)
  if self._setup then self._setup(ctx) end
end

function NanoVGComponent:nvg_draw(ctx)
  if self._draw then self._draw(ctx) end
end

m.NanoVGEntity = ecs.promote("NanoVGEntity", NanoVGComponent)

return m
