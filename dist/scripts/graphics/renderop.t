-- graphics/renderop.t
--
-- an individual rendering operation

local class = require("class")
local m = {}

local RenderOperation = class("RenderOperation")
m.RenderOperation = RenderOperation

function RenderOperation:init()
  -- nothing in particular to do
end

function RenderOperation:bind_stage(stage)
  self.stage = stage
  self.opfunc = self:bind_to(stage)
end

function RenderOperation:bind_to(stage)
  return function(component, tf)
    self:apply(component, tf)
  end
end

local DrawOp = RenderOperation:extend("DrawOp")
m.DrawOp = DrawOp

function DrawOp:init(options)
  options = options or {}
  self._filter = options.filter
end

function DrawOp:bind_to(stage)
  return function(renderable, tf)
    renderable.drawcall:submit(stage.view._viewid, stage.globals, tf)
  end
end

function DrawOp:bind_stage(stage)
  if self._func then truss.error("Render op already bound!") end
  self._func = self:bind_to(stage)
end

function DrawOp:matches(tags)
  if not tags.compiled then return nil end
  if self._filter and not self._filter(tags) then return nil end
  return self._func
end

local MultiDrawOp = DrawOp:extend("MultiDrawOp")
m.MultiDrawOp = MultiDrawOp

function MultiDrawOp:bind_to(stage)
  return function(renderable, tf)
    renderable.drawcall:multi_submit(stage._start_view_id, stage._num_views,
                                     stage.globals, tf)
  end
end

return m