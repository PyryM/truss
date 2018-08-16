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
  self.globals = options.globals or gfx.CompiledGlobals()
end

function Pipeline:bind()
  for _, stage in ipairs(self._ordered_stages) do
    stage:bind()
  end
end

function Pipeline:match(tags)
  local ret = {}
  for _, stage in ipairs(self._ordered_stages) do
    stage:match(tags, ret)
  end
  return ret
end

function Pipeline:pre_render()
  for _, stage in ipairs(self._ordered_stages) do
    if stage.pre_render then stage:pre_render() end
  end
end

function Pipeline:post_render()
  for _, stage in ipairs(self._ordered_stages) do
    if stage.post_render then stage:post_render() end
  end
end

function Pipeline:add_stage(stage, stage_name)
  table.insert(self._ordered_stages, stage)
  stage_name = stage_name or stage.stage_name
  if stage_name then self.stages[stage_name] = stage end
  local nviews = stage:num_views() or 1
  if self.verbose then
    log.debug("Giving stage [" .. tostring(stage) .. "] views " ..
              self._next_view .. " to " .. (self._next_view + nviews - 1))
  end
  stage:bind_view_ids(self._next_view, nviews)
  self._next_view = self._next_view + nviews
  return stage
end

return m
