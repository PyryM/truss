-- gfx/shadowstage.t
--
-- shadow map rendering stages

local class = require("class")
local m = {}
local ShadowStage = class("ShadowStage")
function ShadowStage:init(options)
    local gfx = require("gfx")

    local shaderutils = require("utils/shaderutils.t")
    local shadowshader = {
        program = shaderutils.loadProgram("vs_shadowcast", "fs_shadowcast")
    }

    self.options_ = options or {}
    self.context_ = {}

    local shaders = {default = shadowshader}
    local noshadow = options.noshadow or {}
    for i,v in ipairs(noshadow) do
        shaders[v] = false
    end

    self.stage_ = gfx.MultiShaderStage({
        renderTarget = options.target or options.renderTarget,
        clear = {depth = 1.0},
        shaders = shaders
    })
    self.shadowcamera = gfx.Camera():makeProjection(60, 1.0, 0.01, 40.0)
end

function ShadowStage:setupViews(startView)
    return self.stage_:setupViews(startView)
end

function ShadowStage:render(context)
    self.context_.scene = context.scene
    self.context_.camera = self.shadowcamera
    self.stage_:render(self.context_)
end

m.ShadowStage = ShadowStage
return m
