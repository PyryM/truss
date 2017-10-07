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

-- should not be used directly! create a TexUniform!
m.UNI_TEX = {
  bgfx_type = bgfx.UNIFORM_TYPE_INT1,
  terra_type = nil -- no terra type!
}

local Uniform = class("Uniform")
function Uniform:init(uni_name, uni_type, num, value)
  if not uni_name then return end

  num = num or 1
  uni_type = uni_type or m.UNI_VEC

  self._uni_type = uni_type
  self._handle = m._create_uniform(uni_name, uni_type, num)
  self._num = num
  self._val = terralib.new(uni_type.terra_type[num])
  self._uni_name = uni_name
  if num == 1 and value then self:set(value) end
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

function Uniform:bind_global(global)
  if global then global:bind() else self:bind() end
end

local TexUniform = class("TexUniform")
function TexUniform:init(uni_name, sampler_idx, value)
  if not uni_name then return end
  self._handle = m._create_uniform(uni_name, m.UNI_TEX, 1)
  self._sampler_idx = sampler_idx
  self._uni_name = uni_name
  self:set(value)
end

function TexUniform:clone()
  local ret = TexUniform()
  ret._handle = self._handle
  ret._sampler_idx = self._sampler_idx
  ret._tex = self._tex
  ret._uni_name = self._uni_name
  return ret
end

function TexUniform:set(tex)
  self._tex = tex
  return self
end

function TexUniform:_bind(tex, sampler)
  if not tex then return self end
  local texhandle
  if type(tex) == "cdata" then
    texhandle = tex
  else
    texhandle = tex._handle or tex.raw_tex
  end
  if texhandle then
    bgfx.set_texture(sampler, self._handle, texhandle, bgfx.UINT32_MAX)
  end
  return self
end

function TexUniform:bind()
  self:_bind(self._tex, self._sampler_idx)
end

function TexUniform:bind_global(global)
  -- use the global's *value* but our *sampler index*
  if not global then return self:bind() end
  self:_bind(global._tex, self._sampler_idx)
end

local UniformSet = class("UniformSet")
function UniformSet:init(uniform_list)
  self._uniforms = {}
  if uniform_list then
    for _, uniform in ipairs(uniform_list) do
      self:add(uniform)
    end
  end
end

function UniformSet:add(uniform)
  local newname = uniform._uni_name
  if self[newname] then
    truss.error("UniformSet.add : uniform named [" .. newname ..
          "] already exists.")
    return
  end
  self:_raw_add(newname, uniform)
  return uniform
end

function UniformSet:_raw_add(uni_name, uniform)
  self._uniforms[uni_name] = uniform
  self[uni_name] = uniform
end

function UniformSet:clone(force_clone_shared)
  local ret = UniformSet()
  for k, v in pairs(self._uniforms) do
    local v_clone
    if v.is_shared and not force_clone_shared then
      v_clone = v
    else
      v_clone = v:clone()
    end
    ret:_raw_add(k, v_clone)
  end
  return ret
end

function UniformSet:create_view(selection)
  local ret = UniformSet()
  for _, uni_name in ipairs(selection) do
    ret:_raw_add(uni_name, self._uniforms[uni_name])
  end
  return ret
end

function UniformSet:bind()
  for _, v in pairs(self._uniforms) do
    v:bind()
  end
  return self
end

function UniformSet:bind_as_fallbacks(globals)
  if not globals then return self:bind() end
  -- preferentially bind uniforms in globals, but fall back to ones in this set
  for uni_name, uni in pairs(self._uniforms) do
    uni:bind_global(globals[uni_name])
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

-- in bgfx, uniforms are in some sense global, so keep a cache of uniforms and
-- their types so we can give a useful error if a user tries to define the same
-- uniform with two different types

m._uniform_cache = {}
function m._create_uniform(uni_name, uni_type, num)
  local v = m._uniform_cache[uni_name]
  if v then
    if v.uni_type ~= uni_type or v.num ~= num then
      truss.error("Tried to recreate uniform " .. uni_name
             .. " with different type or count!")
      return nil
    end
    return v.handle
  else -- not registered
    v = {uni_type = uni_type, num = num}
    v.handle = bgfx.create_uniform(uni_name, uni_type.bgfx_type, num)
    m._uniform_cache[uni_name] = v
    return v.handle
  end
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
