-- multipass.t
--
-- a renderpass that will apply one of multiple shader options to
-- each object

local class = require("class")
local math = require("math")
local m = {}

local MultiPass = class("MultiPass")
function MultiPass:init(options)
    self.globals = options.globals or {}
    self.shaders_ = {}
    for shaderName, shader in pairs(options.shaders or {}) do
        self:addShader(shaderName, shader)
    end
    self.viewid_ = options.viewid or 0
end

function MultiPass:addShader(name, options)
    if not options.program then
        log.error("MultiPass.addShader : shader [" .. name ..
                  "] has no .program!" )
    self.shaders_[name] = options
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
    if params.camera then
        params.camera:setMatrices(self.viewid_)
    end

    if params.scene then
        params.scene:map(self.renderObject_, self)
    end
end

m.MultiPass = MultiPass
return m