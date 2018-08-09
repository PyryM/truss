-- gfx/compiled.t
--
-- compiled/metaprogrammed gfx bindings

local class = require("class")
local _uniforms = require("./uniforms.t")
local _shaders = require("./shaders.t")
local _common = require("./common.t")
local mathtypes = require("math/types.t")
local m = {}

local MAX_GLOBALS = 64

m.uniform_types = {
  mat4 = {
    kind       = "mat4",
    bgfx_type  = bgfx.UNIFORM_TYPE_MAT4,
    terra_type = mathtypes.mat4_
  },
  vec  = {
    kind       = "vec",
    bgfx_type  = bgfx.UNIFORM_TYPE_VEC4,
    terra_type = mathtypes.vec4_
  },
  tex  = {
    kind       = "tex",
    bgfx_type  = bgfx.UNIFORM_TYPE_INT1,
    terra_type = bgfx.texture_handle_t
  } 
}

-- in bgfx the same uniform name cannot be used with two different types/counts
-- so keep track of uniform (name, type, counts) to provide useful errors
m._uniform_cache = {}
function m._define_uniform(uni_name, uni_type, count)
  local v = m._uniform_cache[uni_name]
  if v then
    if v.uni_type ~= uni_type or v.count ~= count then
      truss.error("Tried to recreate uniform " .. uni_name
             .. " with different type or count!")
      return nil
    end
    return v.handle
  else
    v = {uni_type = uni_type, count = count}
    v.handle = bgfx.create_uniform(uni_name, uni_type.bgfx_type, count)
    m._uniform_cache[uni_name] = v
    return v.handle
  end
end

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
function TexProxy:_set(pos, v)
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

local function _resolve_uniform(uname, u)
  local uprime = {
    name = uname,
    handle_name = "h_" .. uname,
    value_name = uname,
    count = 1,
    global = false
  }
  if type(u) == 'string' then
    uprime.kind = u
    uprime.count = 1
    uprime.global = false
  elseif u and u.kind then -- assume table
    truss.extend_table(uprime, u)
  else
    truss.error("Unknown uniform specification: " .. tostring(u))
  end
  uprime.typeinfo = m.uniform_types[uprime.kind]
  if not uprime.typeinfo then
    truss.error("Unknown uniform kind: " .. uprime.kind)
  end
  if uprime.kind == "tex" and (not uprime.sampler) then
    truss.error("Tex uniform " .. uname .. " does not specify a sampler.")
  end
  return uprime
end

local function resolve_uniforms(utable)
  local ret = {}
  for uname, u in pairs(utable or {}) do
    ret[uname] = _resolve_uniform(uname, u)
  end
  return ret
end

local registry = {
  _indices = {},
  _counts = {
    mat4 = 0, vec = 0, tex = 0
  }
}

function registry:_create_global(uname, kind, count)
  if not self._counts[kind] then truss.error("Unknown kind " .. kind) end
  local nextcount = self._counts[kind] + count
  if nextcount > MAX_GLOBALS then
    truss.error("Exceeded maximum number of globals: " 
                .. uname .. " " .. kind)
  end
  self._indices[uname] = {self._counts[kind], kind, count}
  log.debug("Registering compiled global " .. uname 
            .. " " .. kind .. " " .. count
            .. " -> " .. self._counts[kind])
  self._counts[kind] = nextcount
  return self._indices[uname]
end

function registry:find_global(uname, ukind, count)
  log.debug("Finding global " .. uname)
  if self._indices[uname] then
    return unpack(self._indices[uname])
  elseif ukind and count then
    return unpack(self:_create_global(uname, ukind, count))
  else
    return nil
  end
end

m.global_registry = registry

local CompiledGlobals = class("CompiledGlobals")
m.CompiledGlobals = CompiledGlobals

function CompiledGlobals:init()
  self._value = terralib.new(GlobalUniforms_t)
  self:update_globals_list()
end

function CompiledGlobals:update_globals_list()
  for uname, udata in pairs(registry._indices) do
    if not self[uname] then
      local idx, kind, count = unpack(udata)
      local proxy = proxy_constructors[kind](self._value, kind, kind, 
                                             idx, count or 1)
      self[uname] = proxy
    end
  end
end

local function order_uniforms(utable)
  print("ordering!")
  local ulist = {}
  for _, u in pairs(utable) do
    print("yay")
    table.insert(ulist, u)
  end
  return ulist
end

local function select_globals(ulist, isglobal)
  local ret = {}
  for _, u in ipairs(ulist) do
    if u.global == isglobal then
      table.insert(ret, u)
    end
  end
  return ret
end

local function compile_uniforms(material_name, uniforms)
  local mtype = terralib.types.newstruct(material_name)
  mtype.entries:insert({field = 'state', type = uint64})
  mtype.entries:insert({field = 'program', type = bgfx.program_handle_t})
  -- Uniform order might matter for cache/performance reasons, so go ahead
  -- and sort them
  local ordered_uniforms = order_uniforms(uniforms)
  print("stufff??????????????????????")
  for _, u in ipairs(ordered_uniforms) do
    print(".................................")
    mtype.entries:insert({field = u.handle_name, 
                          type = bgfx.uniform_handle_t})
    mtype.entries:insert({field = u.value_name, 
                          type = u.typeinfo.terra_type[u.count or 1]})
    print(u.value_name)
  end
  mtype:complete()

  local terra material_copy(src: &mtype, dest: &mtype)
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

  local local_uniforms = select_globals(ordered_uniforms, false)
  local global_uniforms = select_globals(ordered_uniforms, true)

  local terra material_binder(src: &mtype, globals: &GlobalUniforms_t)
    bgfx.set_state(src.state, 0)
    [ make_binds(local_uniforms, src) ]
    -- if a null pointer is provided to the global uniforms, then
    -- bind against our local values
    if globals == nil then
      [ make_binds(global_uniforms, src) ] 
    else
      [ make_global_binds(global_uniforms, src, globals) ]
    end
  end

  return mtype, material_binder, material_copy
end

local BaseMaterial = class("BaseMaterial")

function BaseMaterial:clone()
  return self.class(self)
end

function BaseMaterial:set_state(s)
  if s == nil or type(s) == "table" then
    s = _common.create_state(s)
  end
  self._value.state = s
end

function BaseMaterial:set_program(p)
  self._value.program = p
end

local function stage_handles(target, uniforms)
  for _, uinfo in pairs(uniforms) do
    local handle = m._define_uniform(uinfo.name, uinfo.typeinfo, uinfo.count)
    target[uinfo.handle_name] = handle
  end
end

local _material_count = 0

function m.define_base_material(options)
  if not options.name then
    truss.error("No .name provided")
  end
  if not options.uniforms then
    truss.error("No .uniforms provided")
  end

  local uniforms = resolve_uniforms(options.uniforms)
  local canonical_name = options.name .. "__" .. _material_count
  _material_count = _material_count + 1

  print("options? " .. tostring(uniforms))
  for k, v in pairs(options.uniforms) do print(k) end
  local material_t, material_bind, material_copy = compile_uniforms(canonical_name, uniforms)

  local Material = BaseMaterial:extend(options.name)
  function Material:init(_options)
    _options = _options or {}
    self._value = terralib.new(material_t)
    self._ttype = material_t
    self._binder = material_bind
    self._copy_value = material_copy
    if _options._value then
      self._copy_value(src._value, self._value)
    end
    stage_handles(self._value, uniforms)
    self.uniforms = {}
    for uname, uniform in pairs(uniforms) do
      local pcon = proxy_constructors[uniform.kind]
      self.uniforms[uname] = pcon(self._value, uname, uniform.kind, 
                                  0, uniform.count or 1)
    end
    if options.state then self:set_state(options.state) end
    if options.program then
      self:set_program(_shaders.load_program(unpack(options.program)))
    end
  end

  return Material
end

local function geo_funcs(vname, iname)
  local vert_t = bgfx[vname ..'_handle_t']
  local index_t = bgfx[iname .. '_handle_t']
  local set_vert = bgfx['set_' .. vname]
  local set_index = bgfx['set_' .. iname]
  local struct geo_t {
    tf: float[16];
    vtx_start: uint32;
    vtx_count: uint32;
    idx_start: uint32;
    idx_count: uint32;
    vbh: vert_t;
    ibh: index_t; 
  }
  return {geo_t, set_vert, set_index}
end

local _geo_type_structs = nil
local function get_geo_functions(geo_type)
  if not _geo_type_structs then
    _geo_type_structs = {
      static = geo_funcs("vertex_buffer", "index_buffer"),
      dynamic = geo_funcs("dynamic_vertex_buffer", "dynamic_index_buffer")
    }
  end
  if not _geo_type_structs[geo_type] then
    truss.error("Unsupported geometry type: " .. tostring(geo_type))
  end
  return unpack(_geo_type_structs[geo_type])
end

local function name_drawcall(opts)
  return opts.geo_type .. "|" .. opts.material._ttype.name
end

m._draw_call_cache = {}
local function compile_draw_call(opts)
  local call_name = name_drawcall(opts)
  local cache_val = m._draw_call_cache[call_name]
  if cache_val then
    return unpack(cache_val)
  end

  local material = opts.material
  local material_t, bind_material = material._ttype, material._binder
  local geo_t, set_vert, set_index = get_geo_functions(opts.geo_type)

  local terra draw(view: uint8, geo: &geo_t, mat: &material_t, globals: &GlobalUniforms_t)
    bgfx.set_transform(&geo.tf, 1)
    set_vert(0, geo.vbh, geo.vtx_start, geo.vtx_count)
    set_index(geo.ibh, geo.idx_start, geo.idx_count)
    bind_material(mat, globals)
    bgfx.set_state(mat.state, 0)
    bgfx.submit(view, mat.program, 0.0, false)
  end
  m._draw_call_cache[call_name] = {geo_t, draw}
  return geo_t, draw
end

local Drawcall = class("Drawcall")
m.Drawcall = Drawcall

function Drawcall:init(geo, mat)
  self.geo = geo
  self.mat = mat
  self._cmat = mat._value
  self:_recompile()
end

function Drawcall:_recompile()
  local geo_type = "static"
  if self.geo.is_dynamic then geo_type = "dynamic" end
  local geo_t, draw = compile_draw_call{
    geo_type = geo_type,
    material = self.mat
  }
  print(draw:disas())
  self._cgeo = terralib.new(geo_t)
  self._cgeo.vbh = self.geo._vbh
  self._cgeo.ibh = self.geo._ibh
  self._cgeo.vtx_start = 0
  self._cgeo.vtx_count = bgfx.UINT32_MAX
  self._cgeo.idx_start = 0
  self._cgeo.idx_count = bgfx.UINT32_MAX
  self._draw = draw

  print(self._cgeo.vbh.idx)
  print(self._cgeo.ibh.idx)
  print(self._cmat.program.idx)
  print(self._cmat.state)
end

function Drawcall:set_geometry(geo)
  self.geo = geo
  self:_recompile()
end

function Drawcall:set_material(mat)
  self.mat = mat
  self._cmat = mat._value
  self:_recompile()
end

function Drawcall:clone()
  return Drawcall(self.geo, self.mat)
end

function Drawcall:submit(viewid, view_globals, tf)
  self._cgeo.tf = tf.data
  self._draw(viewid, self._cgeo, self._cmat, view_globals._value)
end

return m