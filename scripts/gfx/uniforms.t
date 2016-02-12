-- uniforms.t
--
-- class for conveniently setting up uniforms

local class = require("class")
local m = {}

local RAW_UNIFORM   = 0
local CLASS_UNIFORM = 1
local TEX_UNIFORM   = 2 

struct m.TTypeRGBA {
    r: float;
    g: float;
    b: float;
    a: float;
}

struct m.TTypeXYZW {
    x: float;
    y: float;
    z: float;
    w: float;   
}

m.types = {}
m.types.XYZW = {
    bgfxType  = bgfx.BGFX_UNIFORM_TYPE_VEC4,
    terraType = m.TTypeXYZW,
    uType     = m.RAW_UNIFORM
}

m.types.RGBA = {
    bgfxType  = bgfx.BGFX_UNIFORM_TYPE_VEC4,
    terraType = m.TTypeRGBA,
    uType     = m.RAW_UNIFORM
}

m.types.VECTOR = {
    bgfxType  = bgfx.BGFX_UNIFORM_TYPE_VEC4,
    terraType = nil,
    uType     = m.CLASS_UNIFORM
}

m.types.TEXTURE = {
    bgfx.BGFX_UNIFORM_TYPE_INT1,
    uType     = TEX_UNIFORM
}

local Uniforms = class("Uniforms")

function Uniforms:init()
    self.uniforms = {}
    self.nextTexSampler_ = 0
end

function Uniforms:addUniform(uniformName, uniformType, uniformNum)
    if self.uniforms[uniformName] then
        log.error("Cannot add: uniform [" .. uniformName .. "] exists!")
        return
    end

    uniformNum = uniformNum or 1

    local uType = uniformType.uType
    if uType ~= RAW_UNIFORM and uniformNum > 1 then
        log.error("Only raw uniforms support arrays!")
        return
    end

    local bgfxHandle = bgfx.bgfx_create_uniform(uniformName, 
                                                uniformType.bgfxType,
                                                uniformNum)
    local uData = { n = uniformNum,
                    bh = bgfxHandle,
                    ut = uType }

    if uType == RAW_UNIFORM then
        uData.val = terralib.new(uniformType.terraType[uniformNum]) 
    elseif uType == TEX_UNIFORM then
        uData.ts = self.nextTexSampler_
        self.nextTexSampler_ = self.nextTexSampler_ + 1
    elseif uType == CLASS_UNIFORM then
        -- nothing to do
    end
    self.uniforms[uniformName] = uData
    return uData
end

function Uniforms:bind()
    for k,v in pairs(self.uniforms) do
        local uniformType = v.ut
        if uniformType == RAW_UNIFORM then
            bgfx.bgfx_set_uniform(v.bh, v.val, v.n)
        elseif uniformType == TEX_UNIFORM then
            if v.val then
                bgfx.bgfx_set_texture(v.ts, v.bh, v.val, bgfx.UINT32_MAX)
            end
        elseif uniformType == CLASS_UNIFORM then
            if v.val and v.val.elem then
                bgfx.bgfx_set_uniform(v.bh, v.val.elem, 1)
            end
        end
    end
end

return m