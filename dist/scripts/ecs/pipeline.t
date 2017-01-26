local class = require("class")
local gfx = require("gfx")
local m = {}

local Pipeline = class("Pipeline")
m.Pipeline = Pipeline

function Pipeline:init(initoptions)
  self._ordered_stages = {}
  self._next_view = 0
  self.stages = {}
end

function Pipeline:add_stage(stage, stage_name)
  table.insert(self._ordered_stages, stage)
  if stage_name then self.stages[stage_name] = stage end
  local nviews = stage.num_views or 1
  local views = {}
  for i = 1,nviews do
    local v = gfx.View(self._next_view)
    views[i] = v
    self._next_view = self._next_view + 1
  end
  stage:set_views(views)
  return stage
end

function Pipeline:bind()
  for _,stage in ipairs(self._ordered_stages) do
    stage:bind()
  end
end

function Pipeline:get_render_ops(component, target_list)
  target_list = target_list or {}
  for _,stage in ipairs(self._ordered_stages) do
    stage:get_render_ops(component, target_list)
  end
  return target_list
end

function Pipeline:update()
  for _,stage in ipairs(self._ordered_stages) do
    if stage.update then stage:update() end
  end
end

local Stage = class("Stage")
m.Stage = Stage

-- initoptions should contain e.g. input render targets (for post-processing),
-- output render targets, uniform values.
function Stage:init(options)
  self.num_views = 1
  self._options = options or {}
  self._render_ops = self._options.render_ops or {}
  self.filter = self._options.filter
  self.globals = self._options.globals or {}
end

function Stage:bind()
  self.view:set(self._options)
  for _,op in ipairs(self._render_ops) do
    op:set_stage(self)
  end
end

function Stage:set_views(views)
  self.view = views[1]
  self:bind()
end

function Stage:add_render_op(op)
  table.insert(self._render_ops, op)
  op:set_stage(self)
end

function Stage:get_render_ops(component, target)
  target = target or {}

  if self.filter and not (self.filter(component)) then return target end

  for _, op in ipairs(self._render_ops) do
    if op:matches(component) then
      table.insert(target, op)
      if self._exclusive then return target end
    end
  end
  return target
end

return m
