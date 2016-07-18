-- gfx/blitstage.t
--
-- a stage to perform a blit operation
local class = require("class")
local Queue = require("utils/queue.t").Queue
local m = {}

local BlitStage = class("BlitStage")
function BlitStage:init(options)
    local gfx = require("gfx")
    options = options or {}
    self.options_ = options
end

function BlitStage:setupViews(startView)
    self.viewid_ = startView
    return startView + 1
end

function BlitStage:render(context)
    self.context_.scene = context.scene
    self.context_.camera = self.shadowcamera
    self.stage_:render(self.context_)
end

m.BlitStage = BlitStage
return m
