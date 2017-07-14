-- graphics/pipeline.t
--
-- defines a pipeline

local m = {}
local class = require("class")
local gfx = require("gfx")

local Pipeline = class("Pipeline")
m.Pipeline = Pipeline

function Pipeline:init(options)
  options = options or {}
  self.stages = {}
  self._ordered_stages = {}
  self._next_view = 0
  self.verbose = options.verbose
  self.globals = options.globals or gfx.UniformSet()
end

function Pipeline:bind()
  for _, stage in ipairs(self._ordered_stages) do
    stage:bind()
  end
end

function Pipeline:match_render_ops(component, ret)
  ret = ret or {}
  for _, stage in ipairs(self._ordered_stages) do
    stage:match_render_ops(component, ret)
  end
  return ret
end

function Pipeline:pre_render()
  for _, stage in ipairs(self._ordered_stages) do
    if stage.update_begin then stage:update_begin() end
  end
end

function Pipeline:post_render()
  for _, stage in ipairs(self._ordered_stages) do
    if stage.update_end then stage:update_end() end
  end
end

function Pipeline:add_stage(stage, stage_name)
  table.insert(self._ordered_stages, stage)
  if stage_name then self.stages[stage_name] = stage end
  local nviews = stage.num_views or 1
  local views = {}
  if self.verbose then
    log.debug("Giving stage [" .. tostring(stage) .. "] views " ..
              self._next_view .. " to " .. (self._next_view + nviews - 1))
  end
  for i = 1,nviews do
    local v = gfx.View(self._next_view)
    views[i] = v
    self._next_view = self._next_view + 1
  end
  stage:set_views(views)
  return stage
end

local Stage = class("Stage")
m.Stage = Stage

-- initoptions should contain e.g. input render targets (for post-processing),
-- output render targets, uniform values.
function Stage:init(options)
  options = options or {}
  self.num_views = 1
  self._render_ops = options.render_ops or {}
  self.filter = options.filter
  self.globals = options.globals or {}
  self._exclusive = options.exclusive
  self.stage_name = options.name or "Stage"
end

function Stage:__tostring()
  return self.stage_name or "Stage"
end

-- copies a table value by value, using val:duplicate() when present
local function duplicate_copy(t, strict)
  local ret = {}
  for k,v in pairs(t) do
    if type(v) == "table" and v.duplicate then
      ret[k] = v:duplicate()
    else
      if strict then truss.error("Value did not support duplicate!") end
      ret[k] = v
    end
  end
  return ret
end

function Stage:duplicate()
  local ret = Stage(duplicate_copy(self.globals),
                    duplicate_copy(self._render_ops, true))
  ret.filter = self.filter
  ret.num_views = self.num_views
  return ret
end

function Stage:bind()
  self.view:set(self.globals)
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

function Stage:match_render_ops(component, target)
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
