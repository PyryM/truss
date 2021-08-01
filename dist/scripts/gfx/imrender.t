-- yet another immediate mode attempt

local class = require("class")
local async = require("async")
local gfx = require("gfx")
local gfx_common = require("gfx/common.t")
local gfx_compiled = require("gfx/compiled.t")
local math = require("math")
local bgfx = require("gfx/bgfx.t")

local m = {}

local ImmediateContext = class("ImmediateContext")
m.ImmediateContext = ImmediateContext

function ImmediateContext:init()
  self._next_view_id = 1
  self._views = {}
  self._identity_matrix = math.Matrix4():identity()
  self._phase_stack = {}
  self._phasecount = 0
  self._stats = {}
end

function ImmediateContext:await_frame()
  if self._view_promise then
    truss.error("Tried to await twice on same immediate context!")
  end
  self._view_promise = async.Promise()
  async.await_immediate(self._view_promise)
  self._view_promise = nil
  self:_update_stats()
end

function ImmediateContext:await_frames(n)
  for _ = 1, n do self:await_frame() end
end

function ImmediateContext:blit(opts)
  local dMip = opts.dest_mip or 0
  local dX, dY, dZ = opts.dest_x or 0, opts.dest_y or 0, opts.dest_z or 0
  local sMip = opts.src_mip or 0
  local sX, sY, sZ = opts.src_x or 0, opts.src_y or 0, opts.src_z or 0
  local w, h, d = assert(opts.width), assert(opts.height), opts.depth or 1
  -- TODO: check if we've done a draw operation on the current view, and
  --       if NOT (=this view only used for blits so far) then reuse current
  local blitview = self:await_view{clear=false}
  local dest = assert(opts.dest)
  local src = assert(opts.src)
  bgfx.blit(
    blitview._viewid,
    assert(dest._handle or dest.raw_tex), dMip, dX, dY, dZ,
    assert(src._handle or src.raw_tex), sMip, sX, sY, sZ,
    w, h, d
  )
  blitview:touch()
end

local function curframe()
  return require("gfx/common.t").bgfx_frame_index
end

function ImmediateContext:await_view(opts)
  self:_assert_in_frame()
  while self._next_view_id > #self._views do
    self:await_frame()
  end
  self._current_view = self._views[self._next_view_id]
  self._next_view_id = self._next_view_id + 1
  self._current_view:set(opts)
  self._current_view:apply_all() -- HACK 
  return self._current_view
end

function ImmediateContext:await(prom)
  local res = async.await(prom)
  self:_wait_until_in_frame(true)
  return res
end

function ImmediateContext:_get_dc(geo, mat)
  assert(geo)
  assert(mat)
  if self._dc then
    self._dc:set_geometry(geo)
    self._dc:set_material(mat)
  else
    self._dc = gfx.Drawcall(geo, mat)
  end
  return self._dc
end

function ImmediateContext:_assert_in_frame()
  if not self._in_frame then
    truss.error("ImmediateContext used outside of its own async! Check async usage (see ctx:await)")
  end
end

function ImmediateContext:_wait_until_in_frame()
  if not self._in_frame then
    self:await_frame()
  end
end

function ImmediateContext:_assert_view()
  if not self._current_view then
    truss.error("ImmediateContext has no view: check async usage")
  end
end

function ImmediateContext:draw_dc(dc, tf)
  self:_assert_view()
  dc:static_submit(self._current_view._viewid, {}, tf or self._identity_matrix)
end

function ImmediateContext:draw_mesh(geo, mat, tf)
  self:draw_dc(self:_get_dc(geo, mat), tf)
end

function ImmediateContext:draw_fullscreen(mat, bounds_or_depth)
  self:_assert_view()
  if not self._quad_geo then
    self._quad_geo = gfx.TransientGeometry()
  end
  gfx.set_transform(self._identity_matrix) -- not strictly necessary
  local bounds
  if type(bounds_or_depth) == 'number' then
    bounds = {0, 0, 1, 1, bounds_or_depth}
  else
    bounds = bounds_or_depth or {0, 0, 1, 1, 0}
  end
  self._quad_geo:quad(unpack(bounds)):bind()
  mat:bind()
  gfx.submit(self._current_view, mat._value.program)
end

local _compute_binders = {
  index = function(geo, stage, opts)
    geo:bind_index_compute(stage, opts.access)
  end,
  vertex = function(geo, stage, opts)
    geo:bind_vertex_compute(stage, opts.access)
  end,
  image = function(tex, stage, opts)
    tex:bind_compute(stage, opts.mip, opts.access, opts.format)
  end,
  texture = function(tex, stage, opts)
    local uhandle = gfx_compiled._define_uniform(
      assert(opts.uniform), gfx_compiled.uniform_types.tex, 1)
    local flags = (opts.flags and gfx.combine_tex_flags(opts.flags, "SAMPLER_"))
                   or bgfx.UINT32_MAX
    bgfx.set_texture(stage, uhandle, tex._handle or tex.raw_tex, flags)
  end
}
_compute_binders.sampler = _compute_binders.texture
function ImmediateContext:_bind_compute(bindings)
  local stage = 0
  for _, binding in ipairs(bindings) do
    if binding.stage then
      if binding.stage < stage then
        truss.error("Binding stages must be unique and increasing!")
      end
      stage = binding.stage
    end
    local binder = assert(_compute_binders[assert(binding[1])])
    binder(assert(binding[2]), stage, binding)
    stage = stage + 1
  end
end

-- hmm, handling uniform arrays might be a bit tricky
-- will need to create temporary contiguous C array and copy into it
local function _bind_uniform(kind, name, count, value)
  local uhandle = gfx_compiled._define_uniform(
    name, assert(gfx_compiled.uniform_types[kind]), count)
  bgfx.set_uniform(uhandle, value, count)
end

function ImmediateContext:_bind_compute_uniforms(uniforms)
  for uni_name, uni_val in pairs(uniforms or {}) do
    if uni_val.data then  -- matrix
      local uhandle = gfx_compiled._define_uniform(
        uni_name, gfx_compiled.uniform_types.mat4, 1)
      bgfx.set_uniform(uhandle, uni_val.data, 1)
    elseif uni_val.elem then -- vector
      local uhandle = gfx_compiled._define_uniform(
        uni_name, gfx_compiled.uniform_types.vec, 1)
      bgfx.set_uniform(uhandle, uni_val.elem, 1)
    elseif uni_val._handle or uni_val.raw_tex 
    or (uni_val[2] and (uni_val[2]._handle or uni_val[2].raw_tex)) then
      truss.error(uni_name .. " is a texture: these must be passed in bindings not uniforms!")
    else
      truss.error("Couldn't infer uniform type for [" .. uni_name .. "]")
    end
  end
end

function ImmediateContext:dispatch_compute(opts)
  if not opts then truss.error("No options provided") end
  if not opts.bindings then truss.error("No bindings specified") end
  if not opts.shape then truss.error("No workgroup size/shape specified") end
  if not opts.program then truss.error("No program specified") end

  self:_bind_compute(opts.bindings)
  if opts.uniforms then
    self:_bind_compute_uniforms(opts.uniforms)
  end

  local viewid = self:current_view()._viewid
  local prog = gfx.load_compute_program(assert(opts.program))
  local sX, sY, sZ = unpack(opts.shape)
  bgfx.dispatch(viewid, prog, sX, sY, sZ, opts.flags or bgfx.DISCARD_ALL)
end

function ImmediateContext:current_frame()
  return require("gfx/common.t").bgfx_frame_index
end

function ImmediateContext:current_view()
  self:_assert_view()
  return self._current_view
end

function ImmediateContext:begin_frame(views)
  self._in_frame = gfx_common.bgfx_frame_index
  self._next_view_id = 1
  self._views = views or {}
  if self._view_promise then self._view_promise:resolve() end
end

function ImmediateContext:finish_frame()
  self._current_view = nil
  self._in_frame = false
end

function ImmediateContext:clear_stats()
  self._stats = {}
end

function ImmediateContext:get_stats()
  return self._stats
end

function ImmediateContext:get_memory_usage()
  return gfx.get_stats().gpu_memory_used or 0
end

function ImmediateContext:_update_stats()
  local phase = self._phase_stack[#self._phase_stack]
  if not phase then return end
  phase.max_mem = math.max(phase.max_mem, self:get_memory_usage())
end

function ImmediateContext:register(resource)
  if #self._phase_stack == 0 then
    log.warn("Implicitly creating root phase!")
    self:begin_phase("ROOT")
  end
  local phase = self._phase_stack[#self._phase_stack]
  table.insert(phase.resources, resource)
  return resource
end

function ImmediateContext:begin_phase(phasename)
  self._phasecount = (self._phasecount or 0) + 1
  local newphase = {
    name = phasename or ("Phase" .. self._phasecount),
    resources = {},
    start_time = truss.tic(),
    max_mem = self:get_memory_usage()
  }
  table.insert(self._phase_stack, newphase)
  return newphase
end

function ImmediateContext:end_phase(phasename)
  local stack_size = #self._phase_stack
  if stack_size == 0 then
    truss.error("Cannot end_phase() without being in a phase!")
  end
  local curphase = self._phase_stack[stack_size]
  if phasename and (phasename ~= curphase.name) then
    truss.error("Mismatched end_phase: opened as " 
                .. tostring(curphase.name)
                .. " but closed with " .. phasename)
  end
  self._phase_stack[stack_size] = nil
  for _, resource in pairs(curphase.resources) do
    if resource.release then
      resource:release()
    elseif resource.destroy then
      resource:destroy()
    end
  end
  curphase.total_time = truss.toc(curphase.start_time)
  if stack_size >= 2 then
    local parent = self._phase_stack[stack_size-1]
    parent.max_mem = math.max(parent.max_mem, curphase.max_mem)
  end
  self._stats[curphase.name] = {
    time = curphase.total_time,
    mem = curphase.max_mem
  }
  return curphase
end

local ImmediateStage = class("ImmediateStage")
m.ImmediateStage = ImmediateStage

function ImmediateStage:init(options)
  self._num_views = assert(options.num_views)
  self._views = {}
  self.ctx = options.ctx or ImmediateContext()
  if options.func then
    self:run(options.func)
  end
  self.enabled = options.enabled ~= false
end

function ImmediateStage:bind(start_id, num_views)
  for idx = 1, num_views do
    if not self._views[idx] then
      self._views[idx] = gfx.View()
    end
    self._views[idx]:bind(start_id + (idx - 1))
  end
  for idx = num_views+1, #self._views do
    self._views[idx] = nil
  end
end

function ImmediateStage:run(f, next, err)
  async.run(function()
    self.ctx:await_frame()
    f(self.ctx)
  end):next(next or print, err or print)
end

function ImmediateStage:pre_render()
  if not self.enabled then return end
  self.ctx:begin_frame(self._views)
end

function ImmediateStage:match(tags, oplist)
  -- doesn't match anything
  return oplist
end

function ImmediateStage:num_views()
  return self._num_views
end

function ImmediateStage:post_render()
  self.ctx:finish_frame()
end

return m