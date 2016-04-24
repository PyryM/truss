-- pipeline.t
--
-- defines a pipeline class for stringing together render passes

local class = require("class")
local m = {}

local Pipeline = class("Pipeline")
function Pipeline:init()
    -- todo
    self.passes_ = {}
end

function Pipeline:addPass(pass)
    table.insert(self.passes_, pass)
end

-- assigns each pass sequential view ids
-- in the order that they were added
function Pipeline:configure(startviewid)
    local viewid = startviewid or 0
    for _, pass in ipairs(self.passes_) do
        viewid = pass:configure(viewid)
    end
    return viewid
end

m.Pipeline = Pipeline
return m