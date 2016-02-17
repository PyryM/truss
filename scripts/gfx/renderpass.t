-- renderpass.t
--
-- an (optional) base class for renderpasses

local class = require("class")
local m = {}

local RenderPass = class("RenderPass")
function RenderPass:init()
    -- nothing to do
end

function RenderPass:render(elements)
    -- default render pass doesn't do anything
end

m.RenderPass = RenderPass

return m