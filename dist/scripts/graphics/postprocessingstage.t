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
    local shader = options.shader or {}
    self.identitymat_ = math.Matrix4():identity()
    self.quadgeo_ = gfx.TransientGeometry()
    self.options_ = options
    self.inputs = options.inputs or {}
    self.target = options.target or options.renderTarget
    self.uniforms_ = options.uniforms or shader.uniforms
    self.program_ = options.program or shader.program
    self.camera_ = gfx.Camera():makeOrthographic(0, 1, 0, 1, -1, 1)
    self.state_ = options.state or shader.state
    self.drawQuad_ = options.drawQuad
    if not self.program_ then
        local vshader = options.vshader or "vs_fullscreen"
        local fshader = options.fshader or "fs_fullscreen_copy"
        local shaderutils = require("utils/shaderutils.t")
        self.program_ = shaderutils.loadProgram(vshader, fshader)
    end
    if not self.uniforms_ then
        self.uniforms_ = gfx.UniformSet()
        local uniName = options.uniformName or "s_srcTex"
        self.uniforms_:add(gfx.TexUniform(uniName, 0), "tex")
    end
end

function PostProcessingStage:setupViews(startView)
    self.viewid_ = startView
    if self.options_.clear ~= false and self.target then
        self.target:setViewClear(self.viewid_, self.options_.clear or {})
    end
    return startView+1
end

function PostProcessingStage:bindUniforms(ctx)
    if ctx.uniforms then
        if ctx.inputs[1] then ctx.inputs.tex = ctx.inputs[1] end
        ctx.uniforms:tableSet(ctx.inputs):bind()
    end
end

function PostProcessingStage:submitFullscreenQuad(ctx)
    bgfx.bgfx_set_state(ctx.state or bgfx_const.BGFX_STATE_DEFAULT, 0)
    bgfx.bgfx_set_transform(self.identitymat_.data, 1)
    if ctx.drawQuad then
        self.quadgeo_:quad(ctx.x0 or 0.0, ctx.y0 or 0.0,
                           ctx.x1 or 1.0, ctx.y1 or 1.0,
                           ctx.z or 0.0):bind()
    else
        self.quadgeo_:fullScreenTri(1.0, 1.0):bind()
    end
    self:bindUniforms(ctx)
    bgfx.bgfx_submit(self.viewid_, ctx.program, 0, false)
end

function PostProcessingStage:render(context)
    if not self.program_ then return end
    if self.target then
        self.target:bindToView(self.viewid_)
    end
    self.camera_:setViewMatrices(self.viewid_)
    local ctx = {drawQuad = self.drawQuad_,
                state = self.state_, program = self.program_,
                uniforms = self.uniforms_, inputs = self.inputs}
    self:submitFullscreenQuad(ctx)
end

--local CompositeStage = PostProcessingStage:extend("CompositeStage")

m.PostProcessingStage = PostProcessingStage
--m.CompositeStage = CompositeStage
return m
