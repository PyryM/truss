-- gfx/clearstage.t
--
-- a stage that just clears a render target

local class = require("class")
local m = {}

local ClearStage = class("ClearStage")
m.ClearStage = ClearStage
function ClearStage:init(options)
    self.target_ = options.renderTarget or options.target
    self.clear_ = options.clear
end

function ClearStage:setupViews(startView)
    self.viewid_ = startView
    self.target_:setViewClear(self.viewid_, self.clear_ or {})
    return startView + 1
end

function ClearStage:render(context)
    bgfx.bgfx_touch(self.viewid_)
end

return m
