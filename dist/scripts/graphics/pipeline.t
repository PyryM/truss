-- graphics/pipeline.t
--
-- defines a pipeline

local m = {}
local class = require("class")

local Pipeline = class("Pipeline")
m.Pipeline = Pipeline

function Pipeline:init()
  -- TODO
end

function Pipeline:get_render_ops(component, ret)
  ret = ret or {}
  for _,stage in ipairs(self._ordered_stages) do
    stage:get_render_ops(component, ret)
  end
  return ret
end

return m
