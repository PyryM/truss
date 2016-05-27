-- MultiShaderStage.t
--
-- a render stage that will render each object with exactly one shader out of
-- multiple options

local class = require("class")
local math = require("math")
local m = {}

local MultiShaderStage = class("MultiShaderStage")
function MultiShaderStage:init(context)
    context = context or {}
    if context.globals == nil then
        log.warn("Provided context did not have any globals: is this what you want?")
        context.globals = require("gfx/uniforms.t").UniformSet()
    end
    self.context = context
    self.shaders_ = {}
    for shaderName, shader in pairs(context.shaders or {}) do
        self:addShader(shaderName, shader)
    end
end

function MultiShaderStage:setup(options, startView)
    self.viewid_ = startView
    return startView + 1
end

function MultiShaderStage:addShader(name, shader)
    if not shader.program then
        log.error("MultiShaderStage.addShader : shader [" .. name ..
                  "] has no .program!" )
    end
    self.shaders_[name] = shader
    if shader.globals then
        self.context.globals:merge(shader.globals)
    end
end

local function renderObject_(obj, mpass)
    local shaders = mpass.shaders_

    if not obj.active or not obj.material or not obj.geo then
        return
    end

    local objmat = obj.material
    local shader = shaders[objmat.shadername] or shaders.default
    if not shader then return end

    if shader.uniforms then shader.uniforms:tableSet(objmat):bind() end
    obj.geo:bind()
    bgfx.bgfx_set_transform(obj.matrixWorld.data, 1)
    bgfx.bgfx_set_state(shader.state or bgfx_const.BGFX_STATE_DEFAULT,
                        shader.stateRGB or 0)
    bgfx.bgfx_submit(mpass.viewid_ or shader.viewid,
                     shader.program, 0, false)
end

function MultiShaderStage:render(context)
    local ctx = context or self.context
    local globals = context.globals or self.globals
    if globals then globals:bind() end

    if context.renderTarget then
        context.renderTarget:bindToView(self.viewid_)
    end

    if context.camera then
        context.camera:setViewMatrices(self.viewid_)
    end

    if context.scene then
        context.scene:map(renderObject_, self)
    end
end

m.MultiShaderStage = MultiShaderStage
return m
