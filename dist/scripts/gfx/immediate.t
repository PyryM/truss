-- gfx/immediate.t
--
-- a pseudo-immediate mode

local class = require("class")
local math = require("math")
local m = {}

local MaterialCache = class("MaterialCache")
function MaterialCache:init()
  self._materials = {}
end

local function sorted_keys(v)
  local ret = {}
  for k, _ in pairs(v) do
    ret[#ret+1] = k
  end
  table.sort(ret)
  return ret
end

local function find_uniforms(options)
  local ret = {}
  for k, v in pairs(options) do
    local prefix = k:sub(1,2)
    if prefix == "u_" or prefix == "s_" then
      ret[k] = v
    end
  end
  return ret
end

local function reformat_material(options)
  return {
    state = options.state,
    program = options.program,
    tags = options.tags,
    uniforms = find_uniforms(options)
  }
end

local function reformat_view(options)
  return {
    render_target = options.render_target or options.target,
    view_matrix = options.view_matrix or options.viewmat,
    proj_matrix = options.proj_matrix or options.projmat,
    clear = options.clear,
    sequential = options.sequential,
    viewport = options.viewport
  }
end

function MaterialCache:get(options)
  -- hash by program name
  local hash = table.concat(options.program, "|")
  if not self._materials[hash] then
    self._materials[hash] = gfx.anonymous_material(reformat_material(options))
  end
  local mat = self._materials[hash]
  for k, v in pairs(options) do
    if mat.uniforms[k] then mat.uniforms[k]:set(v) end
  end
end

m._matcache = MaterialCache()

local ImmediateContext = class("ImmediateContext")
function ImmediateContext:init(options)
  options = options or {}
  self._debug = options.debug or false
  self._quad_geo = require("gfx").TransientGeometry()
  self._matcache = m._matcache
  self._views = {}
  self._proj_matrix = math.Matrix4():orthographic_projection(0, 1, 0, 1, -1, 1)
  self._view_matrix = math.Matrix4():identity()
end

function ImmediateContext:_begin_frame(start_view_id, num_views)
  self._cur_view_id = start_view_id
  self._max_view_id = start_view_id + num_views - 1
  self._viewpos = 1
end

function ImmediateContext:next_view(options, no_reformat)
  if self._cur_view_id > self._max_view_id then
    truss.error("Immediate ran out of views")
  end
  if not self._views[self._viewpos] then
    self._views[self._viewpos] = require("gfx").View{name = "imm_" .. self._viewpos}
  end
  local view = self._views[self._viewpos]
  if not no_reformat then options = reformat_view(options) end
  view:set(options)
  view:bind(self._cur_view_id)
  self._viewpos = self._viewpos + 1
  self._cur_view = view
  self._cur_view_id = self._cur_view_id + 1
  return view
end

function ImmediateContext:current_view()
  return self._cur_view
end

function ImmediateContext:begin_nanovg(options)
end

function ImmediateContext:draw_quad(options)
end

function ImmediateContext:draw_mesh(geo, mat, tf)
end

function ImmediateContext:draw(dc, tf)
end

function ImmediateContext:fullscreen(options)
  local view_opts = reformat_view(options.view or options)
  if not view_opts.proj_matrix then
    view_opts.proj_matrix = self._proj_matrix
  end
  if not view_opts.view_matrix then
    view_opts.view_matrix = self._view_matrix
  end

  local view = self:next_view(view_opts, true)
  local material = options.material or self._matcache:get(options)

  self._quad_geo:quad(0.0, 0.0, 1.0, 1.0, 0.1):bind()
  material:bind()
  gfx.submit(view, material._value.program)

  return view
end

function ImmediateContext:copy(options)
  return self:fullscreen{
    target = options.target,
    program = {"vs_fullscreen", options.shader or "fs_fullscreen_copy"},
    s_srcTex = {0, options.src}
  }
end

return m