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
  if not uni_name then return end

  num = num or 1
  uni_type = uni_type or m.UNI_VEC

  self._uni_type = uni_type
  self._handle = bgfx.create_uniform(uni_name, uni_type.bgfx_type, num)
  self._num = num
  self._val = terralib.new(uni_type.terra_type[num])
  self._uni_name = uni_name
end

function Uniform:clone()
  local ret = Uniform()
  ret._uni_type = self._uni_type
  ret._handle = self._handle
  ret._num = self._num
  ret._val = terralib.new(self._uni_type.terra_type[ret._num])
  for i = 1, ret._num do
    ret._val[i-1] = self._val[i-1]
  end
  ret._uni_name = self._uni_name
  return ret
end

function Uniform:set(v, pos)
  if v.elem then
    self._val[pos or 0] = v.elem
  else
    local dv = self._val[pos or 0]
    dv.x = v[1] or 0.0
    dv.y = v[2] or 0.0
    dv.z = v[3] or 0.0
    dv.w = v[4] or 0.0
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
  if not uni_name then return end
  self._handle = bgfx.create_uniform(uni_name, bgfx.UNIFORM_TYPE_INT1, 1)
  self._sampler_idx = sampler_idx
  self._tex_handle = nil
  self._uni_name = uni_name
end

function TexUniform:clone()
  local ret = TexUniform()
  ret._handle = self._handle
  ret._sampler_idx = self._sampler_idx
  ret._tex_handle = self._tex_handle
  ret._uni_name = self._uni_name
  return ret
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

function UniformSet:add(uniform)
  local newname = uniform._uni_name
  log.debug("Adding " .. newname)
  if self[newname] then
    truss.error("UniformSet.add : uniform named [" .. newname ..
          "] already exists.")
    return
  end

  self._uniforms[newname] = uniform
  self[newname] = uniform
  return self
end

function UniformSet:clone()
  local ret = UniformSet()
  for k,v in pairs(self._uniforms) do
    local v_clone = v:clone()
    ret._uniforms[k] = v_clone
    ret[k] = v_clone
  end
  return ret
end

function UniformSet:bind()
  for _,v in pairs(self._uniforms) do
    v:bind()
  end
  return self
end

function UniformSet:merge(other_uniforms)
  for uni_name, uniform in pairs(other_uniforms._uniforms) do
    if not self[uni_name] then
      self:add(uniform:clone())
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

-- convenience versions
m.VecUniform = function(name, num)
  return m.Uniform(name, m.UNI_VEC, num or 1)
end

m.MatUniform = function(name, num)
  return m.Uniform(name, m.UNI_MAT4, num or 1)
end

return m
