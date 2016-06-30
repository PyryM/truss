-- postprocessingstage.t
--
-- a stage for applying fullscreen shaders/postprocessing effects to
-- render targets

local class = require("class")
local m = {}

local PostProcessingStage = class("PostProcessingStage")
function PostProcessingStage:init(options)
    local math = require("math")
    local gfx = require("gfx")
    self.identitymat_ = math.Matrix4():identity()
    self.quadgeo_ = gfx.TransientGeometry()
    self.options_ = options
    self.inputs = options.inputs or {}
    self.target = options.target or options.renderTarget
    self.uniforms_ = options.uniforms
    self.program_ = options.program
    if (not self.program_) and options.fshader then
        local vshader = options.vshader or "vs_fullscreen"
        local fshader = options.fshader
        local shaderutils = require("utils/shaderutils.t")
        self.program_ = shaderutils.loadProgram(vshader, fshader)
    end
    if not self.uniforms_ then
        self.uniforms_ = gfx.UniformSet()
        self.uniforms_:add(gfx.TexUniform("s_texInput", 0), "tex")
    end
end

function PostProcessingStage:setupViews(startView)
    self.viewid_ = startView
    return startView+1
end

function PostProcessingStage:bindUniforms()
    if self.uniforms_ then
        self.uniforms_:tableSet(self.inputs):bind()
    end
end

function PostProcessingStage:submitFullscreenQuad()
    bgfx.bgfx_set_state(self.state_ or bgfx_const.BGFX_STATE_DEFAULT, 0)
    bgfx.bgfx_set_transform(self.identitymat_.data, 1)
    self.quadgeo_:quad(0.0, 0.0, 1.0, 1.0, 0.0):bind()
    self:bindUniforms()
    bgfx.bgfx_submit(self.viewid_, self.program_, 0, false)
end

function PostProcessingStage:render(context)
    if self.target then
        self.target:bindToView(self.viewid_)
    end
    self:submitFullscreenQuad()
end

m.PostProcessingStage = PostProcessingStage
return m
