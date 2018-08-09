-- uniforms.t
--
-- class for conveniently setting up uniforms

local class = require("class")
local bgfx = require("./bgfx.t")
local vec4_ = require("math/types.t").vec4_

local m = {}

local UNI_VEC = {
  kind       = "vec",
  bgfx_type  = bgfx.UNIFORM_TYPE_VEC4,
  terra_type = vec4_
}

local UNI_MAT4 = {
  kind       = "mat4",
  bgfx_type  = bgfx.UNIFORM_TYPE_MAT4,
  terra_type = float[16]
}

local UNI_TEX = {
  kind       = "tex",
  bgfx_type  = bgfx.UNIFORM_TYPE_INT1,
  terra_type = bgfx.texture_handle_t
}

m.uniform_types = {
  mat4 = UNI_MAT4,
  vec  = UNI_VEC,
  tex  = UNI_TEX 
}

-- base class, not intended to be used directly
local Uniform = class("Uniform")
function Uniform:_create(uni_name, uni_type, num)
  if not uni_name then return end
  self._uni_type = uni_type
  self._handle = m._create_uniform(uni_name, uni_type, num)
  self._num = num
  self._val = terralib.new(uni_type.terra_type[num])
  self._uni_name = uni_name
end

function Uniform:clone()
  local ret = self.class()
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

function Uniform:bind()
  if self._val then bgfx.set_uniform(self._handle, self._val, self._num) end
  return self
end

function Uniform:bind_global(global)
  if global then global:bind() else self:bind() end
end

function Uniform:set_multiple(values)
  for i = 1, self._num do
    if not values[i] then break end
    self:set(i, values[i])
  end
  return self
end

local VecUniform = Uniform:extend("VecUniform")
function VecUniform:init(name, value)
  self:_create(name, UNI_VEC, 1)
  if value then self:set(value) end
end

function VecUniform:_set(pos, x, y, z, w)
  pos = pos - 1 -- zero indexed c data
  local dv = self._val[pos] 
  if type(x) == "number" then
    dv.x = x or 0
    dv.y = y or 0
    dv.z = z or 0
    dv.w = w or 0
  elseif x.elem then
    self._val[pos] = x.elem
  else -- assume x is a list or table
    dv.x = x[1] or x.x or 0.0
    dv.y = x[2] or x.y or 0.0
    dv.z = x[3] or x.z or 0.0
    dv.w = x[4] or x.w or 0.0
  end
  return self
end

function VecUniform:set(x, y, z, w)
  self:_set(1, x, y, z, w)
end

local VecArrayUniform = VecUniform:extend("VecArrayUniform")
function VecArrayUniform:init(name, count, values)
  self:_create(name, UNI_VEC, count)
  if values then self:set_multiple(values) end
end
VecArrayUniform.set = VecArrayUniform._set

local MatUniform = Uniform:extend("MatUniform")
function MatUniform:init(name, value)
  self:_create(name, UNI_MAT4, 1)
  if value then self:set(value) end
end

function MatUniform:_set(pos, v)
  pos = pos - 1 -- zero indexed c data
  if v.data then
    self._val[pos] = v.data
  elseif #v == 16 then
    local dv = self._val[pos]
    for i = 1, 16 do
      dv[i-1] = v[i]
    end
  else
    truss.error("MatUniform:set: value must be either a math.Matrix4 "
                .. " or a 16-element list")
  end
  return self
end

function MatUniform:set(v)
  self:_set(1, v)
end

local MatArrayUniform = MatUniform:extend("MatArrayUniform")
function MatArrayUniform:init(name, count)
  self:_create(name, UNI_MAT4, count)
end
MatArrayUniform.set = MatArrayUniform._set

local TexUniform = class("TexUniform")
function TexUniform:init(uni_name, sampler_idx, value)
  if not uni_name then return end
  self._handle = m._create_uniform(uni_name, UNI_TEX, 1)
  self._sampler_idx = sampler_idx
  self._uni_name = uni_name
  self._uni_type = UNI_TEX
  self:set(value)
end

function TexUniform:clone()
  local ret = TexUniform()
  ret._handle = self._handle
  ret._sampler_idx = self._sampler_idx
  ret._tex = self._tex
  ret._uni_name = self._uni_name
  ret._uni_type = self._uni_type
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
    if uniform_list[1] then
      for _, uniform in ipairs(uniform_list) do
        self:add(uniform)
      end
    else
      self:from_table(uniform_list)
    end
  end
end

function UniformSet:from_table(uniform_table)
  for uni_name, uni_val in pairs(uniform_table) do
    if uni_val.data then 
      -- matrix
      self:add(m.MatUniform(uni_name, uni_val))
    elseif uni_val.elem then 
      -- vector
      self:add(m.VecUniform(uni_name, uni_val))
    elseif uni_val._handle then 
      -- incorrectly passed texture
      truss.error("UniformSet(table) must specify textures as {sampler, tex}")
    elseif uni_val[2] and (uni_val[2]._handle or uni_val[2].raw_tex) then
       -- correctly passed texture
      self:add(m.TexUniform(uni_name, uni_val[1], uni_val[2]))
    else
      truss.error("Couldn't infer uniform type for [" .. uni_name .. "]")
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

function UniformSet:clone()
  local ret = UniformSet()
  for k, v in pairs(self._uniforms) do
    ret:_raw_add(k, v:clone())
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

-- in bgfx the same uniform name cannot be used with two different types/counts
-- so keep track of uniform (name, type, counts) to provide useful errors

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

-- Export classes (note that the base Uniform is not exported)
m.VecUniform = VecUniform
m.VecArrayUniform = VecArrayUniform
m.MatUniform = MatUniform
m.MatArrayUniform = MatArrayUniform
m.TexUniform = TexUniform
m.UniformSet = UniformSet

return m
