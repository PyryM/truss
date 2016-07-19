-- MultiShaderStage.t
--
-- a render stage that will render each object with exactly one shader out of
-- multiple options

local class = require("class")
local math = require("math")
local m = {}

local MultiShaderStage = class("MultiShaderStage")
function MultiShaderStage:init(options)
    options = options or {}
    if options.globals == nil then
        log.warn("Provided options did not have any globals: is this what you want?")
        options.globals = require("gfx/uniforms.t").UniformSet()
    end
    self.options_ = options
    self.globals = options.globals
    self.shaders_ = {}
    self.target = options.renderTarget
    for shaderName, shader in pairs(options.shaders or {}) do
        self:addShader(shaderName, shader)
    end
end

-- this creates a duplicate of the stage that shares the same shaders but
-- can have a different viewid and target (e.g., for a stereo pipeline)
function MultiShaderStage:duplicate(target)
    local ret = MultiShaderStage({globals = true})
    ret.globals = self.globals
    ret.shaders_ = self.shaders_
    ret.options_ = self.options_
    ret.target = target
    return ret
end

function MultiShaderStage:setupViews(startView)
    self.viewid_ = startView
    if self.options_.clear ~= false and self.target then
        self.target:setViewClear(self.viewid_, self.options_.clear or {})
    end
    return startView + 1
end

function MultiShaderStage:addShader(name, shader)
    if not shader.program then
        log.error("MultiShaderStage.addShader : shader [" .. name ..
                  "] has no .program!" )
    end
    self.shaders_[name] = shader
    if shader.globals then
        self.globals:merge(shader.globals)
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
    local globals = context.globals or self.globals
    if globals then globals:bind() end

    if self.target then
        self.target:bindToView(self.viewid_)
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
