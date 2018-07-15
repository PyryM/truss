-- gfx/compiled.t
--
-- compiled/metaprogrammed gfx bindings

local _uniforms = require("./uniforms.t")
local mathtypes = require("math/types.t")
local m = {}

local MAX_GLOBALS = 64

struct GlobalUniforms_t {
  matrices: mathtypes.mat4_[MAX_GLOBALS];
  vectors: mathtypes.vec4_[MAX_GLOBALS];
  textures: bgfx.texture_handle_t[MAX_GLOBALS];
}

local function convert_uniform(u)
  local ret = {
    name = u._uni_name,
    handle_name = "h_" .. u._uni_name,
    value_name = u._uni_name,
    handle = u._handle,
    kind = u._uni_type.kind,
    value_type = u._uni_type.terra_type
  }
  if u._sampler_idx then
    ret.sampler = u._sampler_idx
    ret.texture_flags = u._flags
  elseif u._num then
    ret.count = u._num
  else
    truss.error("Not sure what this uniform is: " .. tostring(u))
  end
  return ret
end

local function convert_uniforms(uset)
  local uinfo = {}
  for k, u in pairs(uset._uniforms) do
    table.insert(uinfo, convert_uniform(u))
  end
  return uinfo
end

local GlobalRegistry = class("GlobalRegistry")
function GlobalRegistry:init()
  self._indices = {
    mat4 = {},
    vec = {},
    tex = {}
  }
end

function GlobalRegistry:find_global_index(uname, ukind)
end

local registry = GlobalRegistry()
m.registry = registry

local CompiledGlobals = class("CompiledGlobals")
m.CompiledGlobals = CompiledGlobals

function CompiledGlobals:init(uniforms)
  local uset = convert_uniforms(uniforms)
  self._value = terralib.new(GlobalUniforms_t)
  for _, u in ipairs(uset) do
    local idx, arr = registry:find_global_index(u.name, u.kind)
    if u.kind == 'vec' then
      self._value[arr][idx] = 
    elseif u.kind == 'mat4' then
    else
    end
  end
end

function CompiledGlobals:set(uname, val)
  local idx, arr, kind = registry:find_global(uname)
  if kind == 'vec' then
    self._value[arr][idx] = val.elem
  elseif kind == 'mat4' then
    self._value[arr][idx] = val.data
  elseif kind == 'tex' then
    self._value[arr][idx] = (val.raw_tex or val._handle)
  end
end

local CompiledMaterial = class("CompiledMaterial")
m.CompiledMaterial = CompiledMaterial

function CompiledMaterial:init(options)
  if not options then return end
  self:_from_uniform_set(options.uniforms, options.globals, options.state) 
end

function CompiledMaterial:clone()
  local ret = CompiledMaterial()
  ret._ttype = self._ttype
  ret._value = terralib.new(ret._ttype)
  self._copy_value(self._value, ret._value)
  ret._copy_value = self._copy_value
  ret._binder = self._binder
  ret._proxies = {}
  for k, v in pairs(self._proxies) do
    local p = v:clone(ret)
    ret[k] = p
    ret._proxies[k] = p
  end
end

function CompiledMaterial:_from_uniform_sets(uset, gset)
  local u = convert_uniforms(uset or {})
  local g = convert_uniforms(gset or {})
  self:_make_type(u, g)
  self:_make_proxies(u, g)
end

function CompiledMaterial:_make_type(uniform_info, global_info, dname)
  local t = terralib.types.newstruct(dname)
  t:insert({field = state, type = uint64})
  local function add_uni(u)
    t:insert({field = u.handle_name, type = bgfx.uniform_handle_t})
    if u.kind == "tex" then
      t:insert({field = u.value_name, type = bgfx.texture_handle_t})
    else
      t:insert({field = u.value_name, type = u.value_type[u.count]})
    end
  end
  for _, uniform in ipairs(uniform_info) do
    add_uni(uniform)
  end
  for _, uniform in ipairs(global_info or {}) do
    add_uni(uniform)
  end
  t:complete()
  self._ttype = t
  self._value = terralib.new(self._ttype)
  for uniform in uniform_info do
    self._value[uniform.handle_name] = uniform.handle
  end
  self._copy_value = terra(src: &t, dest: &t)
    @dest = @src
  end

  local function make_binds(bindables, src)
    local statements = terralib.newlist()
    for uniform in bindables do
      if uniform.kind == "mat4" or uniform.kind == "vec" then
        statements:insert(quote
          bgfx.set_uniform( src.[uniform.handle_name], 
                           &src.[uniform.value_name], 
                           [uniform.count or 1])
        end)
      elseif uniform.kind == "tex" then
        statements:insert(quote
          bgfx.set_texture( [uniform.sampler],
                            src.[uniform.handle_name],
                            src.[uniform.value_name],
                            [uniform.texture_flags or bgfx.UINT32_MAX] )
        end)
      else
        truss.error("Unknown uniform kind " .. uniform.kind)
      end
    end
    return statements
  end

  local function make_global_binds(bindables, src, globals)
    local statements = terralib.newlist()
    for uniform in bindables do
      local uindex = registry:find_global_index(uniform.name, uniform.kind)
      if uniform.kind == "mat4" then
        statements:insert(quote
          bgfx.set_uniform( src.[uniform.handle_name], 
                           &globals.matrices[ [uindex] ], 
                           [uniform.count or 1])
        end)
      elseif uniform.kind == "vec" then
        statements:insert(quote
          bgfx.set_uniform( src.[uniform.handle_name], 
                           &globals.vectors[ [uindex] ], 
                           [uniform.count or 1])
        end)
      elseif uniform.kind == "tex" then
        statements:insert(quote
          bgfx.set_texture( [uniform.sampler],
                            src.[uniform.handle_name],
                            globals.textures[ [uindex] ],
                            [uniform.texture_flags or bgfx.UINT32_MAX] )
        end)
      else
        truss.error("Unknown uniform kind " .. uniform.kind)
      end
    end
    return statements
  end

  self._binder = terra(src: &t, globals: &GlobalUniforms_t)
    bgfx.set_state(src.state, 0)
    [ make_bind_calls(uniform_info, src) ]
    if globals == nil then
      [ make_bind_calls(global_info, src) ] 
    else
      [ make_global_binds(global_info, src, globals) ]
    end
  end
end

return m