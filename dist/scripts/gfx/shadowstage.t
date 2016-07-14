-- gfx/shadowstage.t
--
-- shadow map rendering stages

local class = require("class")
local m = {}
local ShadowStage = class("ShadowStage")
function ShadowStage:init(options)
    local gfx = require("gfx")
    options = options or {}
    self.options_ = options

    local shaderutils = require("utils/shaderutils.t")
    local pgm
    if options.debug then
        pgm = shaderutils.loadProgram("vs_shadowcast_debug", "fs_shadowcast_debug")
    else
        pgm = shaderutils.loadProgram("vs_shadowcast", "fs_shadowcast")
    end
    local shadowshader = {
        program = pgm
    }

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
    self.shadowcamera = gfx.Camera():makeProjection(70, 1.0, 0.1, 100.0)
end

function ShadowStage:setShadowCamera(shadowcamera)
    self.shadowcamera = shadowcamera
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
