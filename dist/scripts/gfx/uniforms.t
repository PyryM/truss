-- uniforms.t
--
-- class for conveniently setting up uniforms

local class = require("class")
local vec4_ = require("math/types.t").vec4_

local m = {}

m.UNI_VEC = {
  bgfx_type  = bgfx.UNIFORM_TYPE_VEC4,
  terra_type = vec4_
}

m.UNI_MAT4 = {
  bgfx_type  = bgfx.UNIFORM_TYPE_MAT4,
  terra_type = float[16]
}

local Uniform = class("Uniform")
function Uniform:init(uni_name, uni_type, num)
  num = num or 1

  self._handle = bgfx.create_uniform(uni_name, uni_type.bgfx_type, num)
  self._num = num
  self._val = terralib.new(uni_type.terra_type[num])
  self._uni_name = uni_name

  return self
end

function Uniform:set(v, pos)
  if not v.elem then truss.error("Uniform:set:: v is not a Vector!") end

  if self._num == 1 then
    -- no need to copy to an intermediate if we only have one value
    self._val = v.elem
  else
    self._val[pos or 0] = v.elem
  end

  return self
end

function Uniform:set_multiple(values)
  for i = 1,self._num do
    if not values[i] then break end
    self:set(values[i], i-1)
  end
  return self
end

function Uniform:bind()
  if self._val then bgfx.set_uniform(self._handle, self._val, self._num) end
  return self
end

local TexUniform = class("TexUniform")
function TexUniform:init(uni_name, sampler_idx)
  self._handle = bgfx.create_uniform(uni_name, bgfx.UNIFORM_TYPE_INT1, 1)
  self._sampler_idx = sampler_idx
  self._tex_handle = nil
  self._uni_name = uni_name
end

function TexUniform:set(tex)
  self._tex_handle = tex.raw_tex or tex
  return self
end

function TexUniform:bind()
  if self._tex_handle then
    bgfx.set_texture(self._sampler_idx, self._handle,
                     self._tex_handle, bgfx.UINT32_MAX)
  end
  return self
end

local UniformSet = class("UniformSet")
function UniformSet:init()
  self._uniforms = {}
end

function UniformSet:add(uniform, alias)
  local newname = alias or uniform._uni_name
  log.debug("Adding " .. newname)
  if self[newname] then
    log.error("UniformSet.add : uniform named [" .. newname ..
          "] already exists.")
    return
  end

  self._uniforms[newname] = uniform
  self[newname] = uniform
  return self
end

function UniformSet:bind()
  for _,v in pairs(self._uniforms) do
    v:bind()
  end
  return self
end

function UniformSet:merge(other_uniforms)
  for alias, uniform in pairs(other_uniforms._uniforms) do
    if not self[alias] then
      self:add(uniform, alias)
    end
  end
  return self
end

-- sets the uniform values from the table of vals
function UniformSet:set(vals)
  if vals.vals then vals = vals.vals end -- allows materials to be classes
  for k,v in pairs(vals) do
    local target = self._uniforms[k]
    if target then target:set(v) end
  end
  return self
end

-- Export the class
m.Uniform = Uniform
m.TexUniform = TexUniform
m.UniformSet = UniformSet

return m
