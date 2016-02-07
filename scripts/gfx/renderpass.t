-- renderpass.t
--
-- an (optional) base class for renderpasses

local class = require("class")
local m = {}

function m.iterate(target)
    if target.iteritems then
        return target:iteritems()
    else
        return ipairs(target)
    end
end

local RenderPass = class("RenderPass")
function RenderPass:init()
    -- nothing to do
end

function RenderPass:render(elements)
    -- default render pass doesn't do anything
end

m.RenderPass = RenderPass

return m