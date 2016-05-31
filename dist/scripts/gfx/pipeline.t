local class = require("class")
local m = {}

local Stage = class("Stage")
m.Stage = Stage

-- initoptions should contain e.g. input render targets (for post-processing),
-- output render targets, uniform values.
function Stage:init(initoptions)
    -- nothing to do
end

-- should return the next available view
-- default implementation assumes a single view
function Stage:setupViews(startView)
    self.viewId = startView
    return startView + 1
end

-- should render, typically using the objects in context.scene and the camera
-- in context.camera
function Stage:render(context)
    -- nothing to do
end

local Pipeline = class("Pipeline")
m.Pipeline = Pipeline

function Pipeline:init(initoptions)
    self.orderedStages = {}
    self.stages = {}
end

function Pipeline:add(stageName, stage, context)
    table.insert(self.orderedStages, {stage = stage, context = context,
                                      stageName = stageName})
    self.stages[stagename] = stage
    return stage
end

function Pipeline:setupViews(startView)
    local curView = startView or 0
    self.startView = curView
    for _, stageData in ipairs(self.orderedStages) do
        curView = stageData.stage:setupViews(curView)
    end
    return curView
end

-- renders the pipeline; each stage uses the context it was added with in
-- preference to the provided context
function Pipeline:render(context)
    for _, stageData in ipairs(self.orderedStages) do
        stageData.stage:render(stageData.context or context)
    end
end

return m
