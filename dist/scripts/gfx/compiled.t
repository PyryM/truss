-- gfx/compiled.t
--
-- compiled/metaprogrammed gfx bindings

local class = require("class")
local _uniforms = require("./uniforms.t")
local mathtypes = require("math/types.t")
local m = {}

local MAX_GLOBALS = 64

local struct GlobalUniforms_t {
  mat4: mathtypes.mat4_[MAX_GLOBALS];
  vec: mathtypes.vec4_[MAX_GLOBALS];
  tex: bgfx.texture_handle_t[MAX_GLOBALS];
}

local UniformProxy = class("UniformProxy")
function UniformProxy:init(target, field, kind, index, count)
  self._target = target
  self._field = field
  self._start_index = index or 0
  self._kind = kind
  self._count = count or 1
end

function UniformProxy:clone(newtarget)
  return self.class(newtarget, self._field, self._kind, 
                    self._start_index, self._count)
end

function UniformProxy:set_multiple(values)
  for i, v in ipairs(values) do
    self:_set(i, v)
  end
end

local VecProxy = UniformProxy:extend("VecProxy")
function VecProxy:_set(pos, x, y, z, w)
  pos = self._start_index + pos - 1 -- zero indexed c data
  local dv = self._target[self._field][pos] 
  if type(x) == "number" then
    -- x, y, z, w are directly numbers
    dv.x = x or 0
    dv.y = y or 0
    dv.z = z or 0
    dv.w = w or 0
  elseif x.elem then
    -- x is a math.Vector
    self._target[self._field][pos] = x.elem
  else 
    -- hope that x is a list or table
    dv.x = x[1] or x.x or 0.0
    dv.y = x[2] or x.y or 0.0
    dv.z = x[3] or x.z or 0.0
    dv.w = x[4] or x.w or 0.0
  end
  return self
end

function VecProxy:set(x, y, z, w)
  self:_set(1, x, y, z, w)
end

local MatProxy = UniformProxy:extend("MatProxy")
function MatProxy:_set(pos, v)
  pos = self._start_index + pos - 1 -- zero indexed c data
  if v.data then
    self._target[self._field][pos] = v.data
  elseif #v == 16 then
    local dv = self._target[self._field][pos]
    for i = 1, 16 do
      dv[i-1] = v[i]
    end
  else
    truss.error("MatProxy:set: value must be either a math.Matrix4 "
                .. " or a 16-element list")
  end
  return self
end

local TexProxy = UniformProxy:extend("TexProxy")
function TexProxy:_set(pox, v)
  truss.error("TexProxy: tex arrays not supported.")
end

function TexProxy:set(tex)
  if not tex then truss.error("Cannot set tex to nil") end
  local texhandle = nil
  if type(tex) == "cdata" then
    texhandle = tex
  else
    texhandle = tex._handle or tex.raw_tex
  end
  if not texhandle then truss.error("No texture handle?") end
  self._target[self._field][self._start_index] = texhandle
end

local proxy_constructors = {
  vec = VecProxy,
  mat4 = MatProxy,
  tex = TexProxy
}

local function convert_uniform(u)
  local ret = {
    name = u._uni_name,
    handle_name = "h_" .. u._uni_name,
    value_name = u._uni_name,
    handle = u._handle,
    kind = u._uni_type.kind,
    value_type = u._uni_type.terra_type,
    value = u.value
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
  self._indices = {}
  self._counts = {
    mat4 = 0, vec = 0, tex = 0
  }
end

function GlobalRegistry:_create_global(uname, kind, count)
  if not self._counts[kind] then truss.error("Unknown kind " .. kind) end
  log.debug("Registering compiled global " .. uname .. " " .. kind .. " " .. count)
  local nextcount = self._counts[kind] + count
  if nextcount > MAX_GLOBALS then
    truss.error("Exceeded maximum number of globals: " 
                .. uname .. " " .. kind)
  end
  self._indices[uname] = {self._counts[kind], kind, kind}
  self._counts[kind] = nextcount
  return self._indices[uname]
end

function GlobalRegistry:find_global(uname, ukind, count)
  log.debug("Finding global " .. uname)
  if self._indices[uname] then
    return unpack(self._indices[uname])
  elseif ukind and count then
    return unpack(self:_create_global(uname, ukind, count))
  else
    return nil
  end
end

local registry = GlobalRegistry()
m.registry = registry

local CompiledGlobals = class("CompiledGlobals")
m.CompiledGlobals = CompiledGlobals

function CompiledGlobals:init(uniforms)
  local uset = convert_uniforms(uniforms)
  self._value = terralib.new(GlobalUniforms_t)
  for _, u in ipairs(uset) do
    local idx, kind = registry:find_global(u.name, u.kind, u.count)
    local proxy = proxy_constructors[kind](self._value, kind, kind, 
                                           idx, u.count or 1)
    self[u.name] = proxy
  end
end

local CompiledMaterial = class("CompiledMaterial")
m.CompiledMaterial = CompiledMaterial

function CompiledMaterial:init(options)
  if not options then return end
  self:_from_uniform_sets(options.uniforms, 
                          options.globals or options.global_uniforms, 
                          options.state) 
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
    local p = v:clone(ret._value)
    ret[k] = p
    ret._proxies[k] = p
  end
end

function CompiledMaterial:_from_uniform_sets(uset, gset)
  local u = convert_uniforms(uset or {})
  local g = convert_uniforms(gset or {})
  self:_make_type(u, g)
end

function CompiledMaterial:bind(globals)
  self._binder(self._value, (globals or {})._value)
end

function CompiledMaterial:_make_type(uniform_info, global_info, dname)
  local t = terralib.types.newstruct(dname)
  t.entries:insert({field = 'state', type = uint64})
  local proxy_info = {}
  local function add_uni(u)
    t.entries:insert({field = u.handle_name, type = bgfx.uniform_handle_t})
    t.entries:insert({field = u.value_name, type = u.value_type[u.count or 1]})
    table.insert(proxy_info, {u.name, u.kind, u.count or 1})
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
  for _, uniform in ipairs(uniform_info) do
    self._value[uniform.handle_name] = uniform.handle
  end
  for _, uniform in ipairs(global_info) do
    self._value[uniform.handle_name] = uniform.handle
  end
  self._copy_value = terra(src: &t, dest: &t)
    @dest = @src
  end

  local function make_binds(bindables, src)
    local statements = terralib.newlist()
    for _, uniform in ipairs(bindables) do
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
                            src.[uniform.value_name][0],
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
    for _, uniform in ipairs(bindables) do
      log.debug("Making global bind: " .. uniform.name)
      log.debug(registry)
      print(registry)
      local uindex, gkind = registry:find_global(uniform.name, 
                                                 uniform.kind,
                                                 uniform.count or 1)
      log.debug("Done?")
      if uniform.kind ~= gkind then
        truss.error("Global uniform type mismatch: " 
                    .. uniform.kind .. " vs " .. gkind)
      end
      if uniform.kind == "mat4" then
        statements:insert(quote
          bgfx.set_uniform( src.[uniform.handle_name], 
                           &globals.mat4[ [uindex] ], 
                           [uniform.count or 1])
        end)
      elseif uniform.kind == "vec" then
        statements:insert(quote
          bgfx.set_uniform( src.[uniform.handle_name], 
                           &globals.vec[ [uindex] ], 
                           [uniform.count or 1])
        end)
      elseif uniform.kind == "tex" then
        statements:insert(quote
          bgfx.set_texture( [uniform.sampler],
                            src.[uniform.handle_name],
                            globals.tex[ [uindex] ],
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
    [ make_binds(uniform_info, src) ]
    if globals == nil then
      [ make_binds(global_info, src) ] 
    else
      [ make_global_binds(global_info, src, globals) ]
    end
  end

  -- populate proxies
  self._proxies = {}
  for _, pinfo in ipairs(proxy_info) do
    local name, kind, count = unpack(pinfo)
    local proxy = proxy_constructors[kind](self._value, kind, kind, 
                                           0, count or 1)
    self._proxies[name] = proxy
    self[name] = proxy
  end
end

return m