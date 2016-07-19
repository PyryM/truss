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
    self.isSetup = false
end

function Pipeline:add(stageName, stage, context)
    table.insert(self.orderedStages, {stage = stage, context = context,
                                      stageName = stageName})
    self.stages[stageName] = stage
    return stage
end

function Pipeline:setupViews(startView)
    local curView = startView or 0
    self.startView = curView
    for _, stageData in ipairs(self.orderedStages) do
        curView = stageData.stage:setupViews(curView)
    end
    self.nextAvailableView = curView
    self.isSetup = true
    return curView
end

-- renders the pipeline; each stage uses the context it was added with in
-- preference to the provided context
function Pipeline:render(context)
    if not self.isSetup then
        log.warn("Pipeline has not been setup; setting up assuming starting at view 0.")
        self:setupViews(0)
    end
    for _, stageData in ipairs(self.orderedStages) do
        if stageData.stage.enabled ~= false then
            stageData.stage:render(stageData.context or context)
        end
    end
end

return m
