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
  local nviews = stage.num_views() or 1
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

return m
