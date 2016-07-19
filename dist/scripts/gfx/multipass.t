-- multipass.t
--
-- a renderpass that will apply one of multiple shader options to
-- each object

local class = require("class")
local math = require("math")
local m = {}

local MultiPass = class("MultiPass")
function MultiPass:init(options)
    options = options or {}
    self.globals = options.globals or require("gfx/uniforms.t").UniformSet()
    self.shaders_ = {}
    for shaderName, shader in pairs(options.shaders or {}) do
        self:addShader(shaderName, shader)
    end
    self.viewid_ = options.viewid or 0
end

function MultiPass:addShader(name, shader)
    if not shader.program then
        log.error("MultiPass.addShader : shader [" .. name ..
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

function MultiPass:render(params)
    if self.globals then self.globals:bind() end

    if params.view then
        self.viewid_ = params.view
    end

    if params.rendertarget then
        params.rendertarget:bindToView(self.viewid_)
    end

    if params.camera then
        params.camera:setViewMatrices(self.viewid_)
    end

    if params.scene then
        params.scene:map(renderObject_, self)
    end
end

m.MultiPass = MultiPass
return m
