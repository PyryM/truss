-- gfx/compiled.t
--
-- compiled/metaprogrammed gfx bindings

local class = require("class")
local _uniforms = require("./uniforms.t")
local _shaders = require("./shaders.t")
local _common = require("./common.t")
local _texture = require("./texture.t")
local _tagset = require("./tagset.t")
local mathtypes = require("math/types.t")
local bgfx = require("./bgfx.t")
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
    bgfx_type  = bgfx.UNIFORM_TYPE_SAMPLER,
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

function MatProxy:set(v)
  self:_set(1, v)
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
  self._ref = tex -- prevent GC-related segfaults
end

function TexProxy:refresh()
  self:set(self._ref)
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
  if uprime.kind == "tex" then
    if not uprime.sampler then
      truss.error("Tex uniform " .. uname .. " does not specify a sampler.")
    end
    if uprime.flags and type(uprime.flags) == 'table' then
      uprime.flags = _texture.combine_tex_flags(uprime.flags, "SAMPLER_")
    end
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
  if self._indices[uname] then
    return unpack(self._indices[uname])
  elseif ukind and count then
    return unpack(self:_create_global(uname, ukind, count))
  else
    return nil
  end
end

m._global_registry = registry

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
  local ulist = {}
  for _, u in pairs(utable) do
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
  for _, u in ipairs(ordered_uniforms) do
    mtype.entries:insert({field = u.handle_name, 
                          type = bgfx.uniform_handle_t})
    mtype.entries:insert({field = u.value_name, 
                          type = u.typeinfo.terra_type[u.count or 1]})
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
                            [uniform.flags or bgfx.UINT32_MAX] )
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
                            [uniform.flags or bgfx.UINT32_MAX] )
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
  local ret = self.class()
  ret:_copy(self)
  return ret
end

function BaseMaterial:set_state(s)
  if s == nil or type(s) == "table" then
    s = _common.create_state(s)
  end
  self._value.state = s
  return self
end

function BaseMaterial:set_program(p)
  if type(p) == 'table' then
    local vshader = p.vertex or p.vshader or p[1]
    local fshader = p.fragment or p.fshader or p[2]
    p = _shaders.load_program(vshader, fshader)
  end
  self._value.program = p
  return self
end

function BaseMaterial:set_uniforms(uniforms)
  for uni_name, uni_val in pairs(uniforms) do
    if not self.uniforms[uni_name] then
      truss.error(("Material [%s] does not have uniform [%s]"):format(self.name, uni_name))
    end
    self.uniforms[uni_name]:set(uni_val)
  end
end

function BaseMaterial:refresh()
  for _, uni in pairs(self.uniforms) do
    if uni.refresh then uni:refresh() end
  end
end

function BaseMaterial:bind(globals)
  self._binder(self._value, globals)
  bgfx.set_state(self._value.state, 0)
  return self
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
  local canonical_name = options.name .. "__" .. _material_count
  log.info("Defining base material " .. options.name .. " -> " .. canonical_name)

  local uniforms = resolve_uniforms(options.uniforms)
  _material_count = _material_count + 1
  local material_t, material_bind, material_copy = compile_uniforms(canonical_name, uniforms)

  local Material = BaseMaterial:extend(options.name)
  function Material:_init(uniform_values)
    self._value = terralib.new(material_t)
    self._ttype = material_t
    self._binder = material_bind
    self._copy_value = material_copy

    stage_handles(self._value, uniforms)
    self.uniforms = {}
    for uname, uniform in pairs(uniforms) do
      local pcon = proxy_constructors[uniform.kind]
      self.uniforms[uname] = pcon(self._value, uname, uniform.kind, 
                                  0, uniform.count or 1)
      if uniform.default then
        self.uniforms[uname]:set(uniform.default)
      end
    end
    self:set_state(options.state or {})
    if options.program then
      self:set_program(options.program)
    else
      self:set_program(_shaders.error_program())
    end
    if options.tags then
      self.tags = _tagset.tagset(options.tags)
    end
    if uniform_values then
      self:set_uniforms(uniform_values)
    end
  end
  Material.init = Material._init

  function Material:_copy(other)
    if not other._value then truss.error("Tried to copy invalid material") end
    self._copy_value(other._value, self._value)
    if other.tags then self.tags = other.tags:clone() end
  end

  return Material
end

-- used to directly instantiate a single 'anonymous' material rather than
-- creating a class/factory
function m.anonymous_material(options)
  local uniforms = {}
  local uvals = {}
  for uni_name, uni_val in pairs(options.uniforms) do
    if uni_val.data then  -- matrix
      uniforms[uni_name] = 'mat4'
      uvals[uni_name] = uni_val
    elseif uni_val.elem then -- vector
      uniforms[uni_name] = 'vec'
      uvals[uni_name] = uni_val
    elseif uni_val._handle then 
      truss.error("anonymous_material{} must specify textures as {sampler, tex}")
    elseif uni_val[2] and (uni_val[2]._handle or uni_val[2].raw_tex) then
      -- correctly passed texture
      uniforms[uni_name] = {kind = 'tex', sampler = uni_val[1], 
                            flags = uni_val.flags or uni_val[3]}
      uvals[uni_name] = uni_val[2]
    else
      truss.error("Couldn't infer uniform type for [" .. uni_name .. "]")
    end
  end

  local instance = m.define_base_material{
    name = "AnonymousMaterial",
    uniforms = uniforms,
    state = options.state or {},
    program = options.program,
    tags = options.tags
  }()

  for uname, val in pairs(uvals) do
    instance.uniforms[uname]:set(val)
  end

  return instance
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
    bgfx.submit(view, mat.program, 0.0, bgfx.DISCARD_ALL)
  end

  local terra multi_draw(start_view: uint8, n_views: uint8, geo: &geo_t, 
                          mat: &material_t, globals: &GlobalUniforms_t)
    -- this assumes all state can be shared
    bgfx.set_transform(&geo.tf, 1)
    set_vert(0, geo.vbh, geo.vtx_start, geo.vtx_count)
    set_index(geo.ibh, geo.idx_start, geo.idx_count)
    bind_material(mat, globals)
    bgfx.set_state(mat.state, 0)
    for i = 0, n_views do
      var viewid: uint8 = start_view + i
      var flags = bgfx.DISCARD_ALL
      if ((i + 1) < n_views) then
        flags = bgfx.DISCARD_NONE
      end
      bgfx.submit(viewid, mat.program, 0.0, flags)
    end
  end
  m._draw_call_cache[call_name] = {geo_t, draw, multi_draw}
  return geo_t, draw, multi_draw
end

local Drawcall = class("Drawcall")
m.Drawcall = Drawcall

function Drawcall:init(geo, mat)
  self.geo = geo
  self.mat = mat
  self._cmat = mat._value
  self:_recompile()
end

local function stage_geo(geo, target)
  target.vbh = geo._vbh
  target.ibh = geo._ibh
  target.vtx_start = geo._vtx_start or 0
  target.vtx_count = geo._vtx_count or bgfx.UINT32_MAX
  target.idx_start = geo._idx_start or 0
  target.idx_count = geo._idx_count or bgfx.UINT32_MAX
end

function Drawcall:_recompile()
  local geo_type = "static"
  if self.geo.is_dynamic then 
    geo_type = "dynamic" 
    self.submit, self.multi_submit = self.dynamic_submit, self.dynamic_multi_submit
  else
    self.submit, self.multi_submit = self.static_submit, self.static_multi_submit
  end
  local geo_t, draw, multi_draw = compile_draw_call{
    geo_type = geo_type,
    material = self.mat
  }
  if self._geo_t ~= geo_t then
    self._geo_t = geo_t
    self._cgeo = terralib.new(geo_t)
  end
  if not (self.geo._vbh and self.geo._ibh) then
    truss.error("Geometry has no buffers!")
  end
  stage_geo(self.geo, self._cgeo)
  self._draw = draw
  self._multi_draw = multi_draw
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

function Drawcall:dynamic_submit(viewid, view_globals, tf)
  stage_geo(self.geo, self._cgeo)
  self._cgeo.tf = tf.data
  self._draw(viewid, self._cgeo, self._cmat, view_globals._value)
end

function Drawcall:static_submit(viewid, view_globals, tf)
  self._cgeo.tf = tf.data
  self._draw(viewid, self._cgeo, self._cmat, view_globals._value)
end

function Drawcall:dynamic_multi_submit(start_viewid, n_views, view_globals, tf)
  stage_geo(self.geo, self._cgeo)
  self._cgeo.tf = tf.data
  self._multi_draw(start_viewid, n_views, 
                   self._cgeo, self._cmat, view_globals._value)
end

function Drawcall:static_multi_submit(start_viewid, n_views, view_globals, tf)
  self._cgeo.tf = tf.data
  self._multi_draw(start_viewid, n_views, 
                   self._cgeo, self._cmat, view_globals._value)
end

local PartialDrawcall = class("PartialDrawcall")
m.PartialDrawcall = PartialDrawcall

function PartialDrawcall:init(material)
  self._calls = {}
  for _, geo_type in ipairs({"static", "dynamic"}) do
    local geo_t, draw = compile_draw_call{
      geo_type = geo_type,
      material = material
    }
    local cgeo = terralib.new(geo_t)
    self._calls[geo_type] = {cgeo, draw}
  end
  self.mat = material
  self._cmat = material._value
end

function PartialDrawcall:submit(geo, viewid, globals, tf)
  local geo_type = (geo.is_dynamic and "dynamic") or "static"
  local cgeo, draw = unpack(self._calls[geo_type])
  stage_geo(geo, cgeo)
  cgeo.tf = tf.data
  draw(viewid, cgeo, self._cmat, globals)
end

return m