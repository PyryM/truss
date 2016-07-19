-- gfx/nanovgstage.t
--
-- stage for simplifying use of nanovg

local class = require("class")
local math = require("math")
local nanovg = core.nanovg
local m = {}

local NanoVGStage = class("NanoVGStage")
function NanoVGStage:init(options)
    options = options or {}
    self.options_ = options
    self.target = options.renderTarget
    self.draw = options.draw
end

function NanoVGStage:setupViews(startView)
    self.viewid_ = startView
    if self.options_.clear ~= false and self.target then
        self.target:setViewClear(self.viewid_, self.options_.clear or {})
    end
    local useAA = (self.options_.antiAliasing ~= false)
    if self.nvgContext == nil then
        self.nvgContext = nanovg.nvgCreate(useAA, self.viewid_)
        if self.extraNvgSetup then self:extraNvgSetup() end
    else
        nanovg.nvgViewId(self.nvgContext, self.viewid_)
    end
    bgfx.bgfx_set_view_seq(self.viewid_, true)
    return startView + 1
end

-- override this function if you want to use it to do extra one-time nanovg
-- setup like loading fonts
function NanoVGStage:extraNvgSetup()
    -- don't do anything by default
end

-- the nanovg render stage doesn't use the normal rendering context at all
-- (scenegraph, camera, etc.), but instead defers all the drawing functions to
-- the user-provided draw function
function NanoVGStage:render(context)
    if not self.target then return end
    self.target:bindToView(self.viewid_)
    if self.draw and self.nvgContext then
        nanovg.nvgBeginFrame(self.nvgContext,
                             self.target.width, self.target.height, 1.0)
        self:draw(self.nvgContext, self.target.width, self.target.height)
        nanovg.nvgEndFrame(self.nvgContext)
    end
end

m.NanoVGStage = NanoVGStage
return m
