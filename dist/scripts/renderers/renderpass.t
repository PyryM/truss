-- renderpass.t
--
-- defines some basic render passes

local class = require("class")
local m = {}

local RenderPass = class("RenderPass")
function RenderPass:init(options)
    self.options = options
end

-- 
function RenderPass:configure(startviewid)
    self.viewid = startviewid
    return startviewid+1
end

function RenderPass:render()
    -- todo
end

-- DummyPass just 'reserves' view ids in a pipeline
-- after configuring the pipeline you can get the reserved ids as .viewids
local DummyPass = class("DummyPass")
function DummyPass:init(nviews)
    self.nviews = nviews
    self.viewids = {}
end

function DummyPass:configure(startviewid)
    for i = 1,self.nviews do
        self.viewids[i] = startviewid + (i - 1)
    end
    return startviewid+self.nviews
end

function DummyPass:render()
    -- this pass doesn't actually render anything
end

return m