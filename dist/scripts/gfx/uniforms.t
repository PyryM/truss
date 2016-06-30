-- uniforms.t
--
-- class for conveniently setting up uniforms

local class = require("class")
local vec4_ = require("math/matrix.t").vec4_

local m = {}

m.VECTOR = {
    bgfxType  = bgfx.BGFX_UNIFORM_TYPE_VEC4,
    terraType = vec4_
}

m.MAT4 = {
    bgfxType  = bgfx.BGFX_UNIFORM_TYPE_MAT4,
    terraType = float[16]
}

local Uniform = class("Uniform")
function Uniform:init(uniName, uniType, uniNum)
    uniNum = uniNum or 1

    local uType = uniType.uType
    self.bh = bgfx.bgfx_create_uniform(uniName, uniType.bgfxType,
                                        uniNum)
    self.num = uniNum
    self.val = terralib.new(uniType.terraType[uniNum])
    self.uniName = uniName

    return self
end

function Uniform:set(v, pos)
    if not v.elem then
        log.error("Uniform:set:: v is not a Vector!")
        return nil
    end

    if self.num == 1 then
        -- no need to copy to an intermediate if we only have one value
        self.val = v.elem
    else
        self.val[pos or 0] = v.elem
    end

    return self
end

function Uniform:setMultiple(vList)
    for i = 1,self.num do
        if not vList[i] then break end
        self:set(vList[i], i-1)
    end
    return self
end

function Uniform:bind()
    if self.val then
        bgfx.bgfx_set_uniform(self.bh, self.val, self.num)
    end
    return self
end

local TexUniform = class("TexUniform")
function TexUniform:init(uniName, uniSampler)
    local textype = bgfx.BGFX_UNIFORM_TYPE_INT1
    self.bh = bgfx.bgfx_create_uniform(uniName, textype, 1)
    self.samplerID = uniSampler
    self.tex = nil
    self.uniName = uniName
end

function TexUniform:set(tex)
    if tex.rawTex then
        self.tex = tex.rawTex
    else
        self.tex = tex
    end
    return self
end

function TexUniform:bind()
    if self.tex then
        bgfx.bgfx_set_texture(self.samplerID, self.bh,
                                self.tex, bgfx.UINT32_MAX)
    end
    return self
end

local UniformSet = class("UniformSet")
function UniformSet:init()
    self.uniforms_ = {}
end

function UniformSet:add(uniform, alias)
    local newname = alias or uniform.uniName
    log.debug("Adding " .. newname)
    if self[newname] then
        log.error("UniformSet.add : uniform named [" .. newname ..
                  "] already exists.")
        return
    end

    self.uniforms_[newname] = uniform
    self[newname] = uniform
    return self
end

function UniformSet:bind()
    for _,v in pairs(self.uniforms_) do
        v:bind()
    end
    return self
end

function UniformSet:merge(otherUniforms)
    for alias, uniform in pairs(otherUniforms.uniforms_) do
        if not self[alias] then
            self:add(uniform, alias)
        else
            log.debug("Skipping merge of " .. alias .. "; already present.")
        end
    end
    return self
end

-- sets the uniform values from the table of vals
function UniformSet:tableSet(vals)
    if vals.vals then vals = vals.vals end -- allows materials to be classes
    for k,v in pairs(vals) do
        local target = self.uniforms_[k]
        if target then
            target:set(v)
        end
    end
    return self
end

-- Export the class
m.Uniform = Uniform
m.TexUniform = TexUniform
m.UniformSet = UniformSet

return m
