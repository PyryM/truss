local class = require("class")
local m = {}

local Stage = class("Stage")
m.Stage = Stage

function Stage:init(context)
    self.initContext = context
end

-- default is to assume the stage will use up a single view
function Stage:setup(options, startView)
    self.viewId = startView
    return startView + 1
end

-- should render, typically using the objects in context.scene
function Stage:render(context)
    -- nothing to do
end

-- called at the beginning of the frame (for example, if the stage needs to
--  find all the lights first in order to set uniforms)
function Stage:beginFrame(context)
    -- nothing to do
end

-- called when the stage is requested to render a single object
function Stage:renderObject(object, context)
    -- nothing to do
end

local Pipeline = class("Pipeline")
m.Pipeline = Pipeline

function Pipeline:init(globalContext)
    self.stages = {}
    self.globalContext = globalContext or {}
end

function Pipeline:add(stage, context)
    table.insert(self.stages, {stage = stage, context = context})
    return stage
end

function Pipeline:setup(options, startView)
    local curView = startView or 0
    self.startView = curView
    for _, stageData in ipairs(self.stages) do
        curView = stageData.stage:setup(options, curView)
    end
    return curView
end

-- renders the pipeline; each stage uses a context in this precedence order:
--  stage_context > call_context > global_context
--  in other words, if a context is given in the call it will override the
--  global context but not any stage-specific context
function Pipeline:render(context)
    for _, stageData in ipairs(self.stages) do
        stageData.stage:render(stageData.context or (context or self.globalContext))
    end
end

return m
