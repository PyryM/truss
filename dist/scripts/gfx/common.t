-- gfx/common.t
--
-- basic gfx stuff

local bgfx = require("./bgfx.t")

local m = {}
m.frame_index = 0
m.bgfx_frame_index = 0
m._schedule_frame = 0
m._scheduled_tasks = {}
m._safe_wait_frames = 3
m._bgfx_initted = false

function m.load_file_to_bgfx(filename)
  local msg = truss.C.load_file(filename)
  if msg == nil then
    return nil
  end
  local ret = bgfx.copy(msg.data, msg.data_length)
  truss.C.release_message(msg)
  return ret
end

function m.reset_gfx(options)
  local gfx = require("gfx")
  if not m._bgfx_initted then 
    truss.error("Cannot reset before init!")
    return
  end

  if options.lowlatency and not gfx.single_threaded then
    log.warn("lowlatency requested on reset; can't be changed after init.")
  end

  local reset, debug = m._make_reset_flags(options)
  local w, h = options.width, options.height
  if options.window then
    w, h = options.window.get_window_size()
  end

  bgfx.reset(w, h, reset, m._init_struct.resolution.format)
  bgfx.set_debug(debug)
  gfx.backbuffer_width, gfx.backbuffer_height = w, h
end

function m._make_reset_flags(options)
  local debug = 0
  local reset = 0
  if options.debugtext then
    debug = debug + bgfx.DEBUG_TEXT
  end
  if options.vsync ~= false then
    reset = reset + bgfx.RESET_VSYNC
  end
  if options.msaa then
    reset = reset + bgfx.RESET_MSAA_X8
  end
  if options.lowlatency then
    -- extra flags that may help with latency
    reset = reset + bgfx.RESET_FLIP_AFTER_RENDER +
          bgfx.RESET_FLUSH_AFTER_RENDER
  end
  return reset, debug
end

local function _convert_view_stats(numviews, vs)
  local stats = {}
  for i = 0, numviews-1 do
    stats[i] = {
      view_id = vs[i].view,
      cpu_time = tonumber(vs[i].cpuTimeElapsed),
      gpu_time = tonumber(vs[i].gpuTimeElapsed)
    }
  end
  return stats
end

function m.get_stats(include_views)
  local rs = bgfx.get_stats()
  local cpu_freq = tonumber(rs.cpuTimerFreq)
  local gpu_freq = tonumber(rs.gpuTimerFreq)
  local stats = {
    cpu_time = tonumber(rs.cpuTimeFrame) / cpu_freq,
    cpu_begin = tonumber(rs.cpuTimeBegin) / cpu_freq,
    cpu_end = tonumber(rs.cpuTimeEnd) / cpu_freq,
    gpu_begin = tonumber(rs.gpuTimeBegin) / gpu_freq,
    gpu_end = tonumber(rs.gpuTimeEnd) / gpu_freq,
    wait_render = tonumber(rs.waitRender),
    wait_submit = tonumber(rs.waitSubmit),
    num_draw = tonumber(rs.numDraw),
    num_compute = tonumber(rs.numCompute),
    max_gpu_latency = tonumber(rs.maxGpuLatency),
    gpu_memory_used = tonumber(rs.gpuMemoryUsed),
    gpu_memory_max = tonumber(rs.gpuMemoryMax),
    width = tonumber(rs.width),
    height = tonumber(rs.height),
    text_width = tonumber(rs.textWidth),
    text_height = tonumber(rs.textHeight),
    num_view = tonumber(rs.numViews)
  }
  if include_views then
    stats.views = _convert_view_stats(rs.numViews, rs.viewStats)
  end
  return stats
end

function m.init_gfx(options)
  local gfx = require("gfx") -- so we can set module level values

  local t0 = truss.tic()
  if m._bgfx_initted then
    truss.error("Tried to init gfx twice.")
    return
  end

  options = options or {}

  local reset, debug = m._make_reset_flags(options)

  if options.lowlatency then
    log.info("Trying to init bgfx in single-threaded mode...")
    m._safe_wait_frames = 1
    -- secret bgfx feature: call render_frame before init => single-threaded
    bgfx.render_frame(-1) -- no timeout 
    gfx.single_threaded = true
  end

  local cb_ptr = nil
  local renderer_type = bgfx.RENDERER_TYPE_COUNT
  if options.backend then
    local rname = "RENDERER_TYPE_" .. string.upper(options.backend)
    renderer_type = bgfx[rname]
    if not renderer_type then
      truss.error("Nonexistent backend " .. rname)
      return false
    end
  end

  local w, h = options.width, options.height
  if options.window then
    w, h = options.window.get_window_size()
    if options.window.get_bgfx_callback then
      cb_ptr = options.window.get_bgfx_callback()
    end
  end
  if not (w and h) then
    truss.error("gfx.init_gfx needs to be supplied with width and height.")
    return false
  end

  log.debug("bgfx init ctor")
  m._init_struct = terralib.new(bgfx.init_t)
  bgfx.init_ctor(m._init_struct)
  m._init_struct['type']  = renderer_type
  m._init_struct.callback = cb_ptr
  m._init_struct.debug    = false -- TODO/FEATURE: allow these to be set?
  m._init_struct.profile  = false 

  bgfx.init(m._init_struct)
  local bb_format = require("./formats.t").find_format_from_enum(m._init_struct.resolution.format)
  log.info("Backbuffer format: " .. bb_format.name)
  bgfx.reset(w, h, reset, m._init_struct.resolution.format)

  gfx.backbuffer_width, gfx.backbuffer_height = w, h
  m._bgfx_initted = true

  bgfx.set_debug(debug)

  log.info("initted bgfx")
  local backend_type = bgfx.get_renderer_type()
  local backend_name = ffi.string(bgfx.get_renderer_name(backend_type))
  gfx.backend_name = backend_name
  gfx.backend_type = backend_type
  gfx.short_backend_name = m._translate_backend_type(backend_type)
  log.info("Renderer name: " .. backend_name)
  log.info("Short renderer name: " .. gfx.short_backend_name)
  local dt = truss.toc(t0) * 1000.0
  log.info(string.format("bgfx init took %.2f ms.", dt))
  
  gfx.BACKBUFFER = require("gfx/rendertarget.t").BackbufferTarget()
end

function m._translate_backend_type(bgfx_type)
  local rtypes = {
    "NOOP",
    "DIRECT3D9",
    "DIRECT3D11",
    "DIRECT3D12",
    "GNM",
    "METAL",
    "OPENGLES",
    "OPENGL",
    "VULKAN"
  }
  for _, rtype in ipairs(rtypes) do
    if bgfx["RENDERER_TYPE_" .. rtype] == bgfx_type then
      return rtype
    end
  end
  return "UNKNOWN"
end

function m.schedule(task, frame_delay)
  local target = m._schedule_frame + (frame_delay or m._safe_wait_frames)
  m._scheduled_tasks[target] = m._scheduled_tasks[target] or {}
  table.insert(m._scheduled_tasks[target], task)
end

function m.set_transform(mat)
  if mat.data then bgfx.set_transform(mat.data, 1) end
end

function m.frame()
  m.bgfx_frame_index = bgfx.frame(false)

  while m._schedule_frame < m.frame_index do
    local tasks = m._scheduled_tasks[m._schedule_frame]
    if tasks then
      for _, task in ipairs(tasks) do task() end
    end
    m._scheduled_tasks[m._schedule_frame] = nil
    m._schedule_frame = m._schedule_frame + 1
  end

  m.frame_index = m.frame_index + 1
  return m.frame_index
end

local state_aliases = {
  primitive = "pt", 
  rgb_write = "write_rgb",
  alpha_write = "write_a",
  depth_write = "write_z"
}

m.DefaultStateOptions = {
  write_rgb = true, write_a = true, write_z = true,
  conservative_raster = false, msaa = true,
  depth_test = "less", cull = "cw", blend = false, pt = false
}

function m.submit(view, program, depth, preserve_state)
  if type(view) == "table" then view = view._viewid end
  bgfx.submit(view, program, depth or 0, not not preserve_state)
end

function m.create_state(user_options)
  if not user_options then return bgfx.STATE_DEFAULT end
  local state = bgfx.STATE_NONE
  local math = require("math")
  local options = {}
  truss.extend_table(options, m.DefaultStateOptions)
  truss.extend_table(options, user_options)

  for k,v in pairs(options) do
    k = state_aliases[k] or k
    if m.DefaultStateOptions[k] == nil then
      truss.error("Unknown state option [" .. k .. "]")
    end

    local const_name = "STATE_" .. string.upper(k)
    if v then
      if v ~= true then
        const_name = const_name .. "_" .. string.upper(v)
      end
      if not bgfx[const_name] then truss.error("No flag " .. const_name) end
      state = math.ullor(state, bgfx[const_name])
    end
  end

  return state
end
m.State = m.create_state -- alias

function m.invalid_handle(ttype)
  local ret = terralib.new(ttype)
  ret.idx = bgfx.INVALID_HANDLE
  return ret
end

function m.invalidate_handle(v)
  v.idx = bgfx.INVALID_HANDLE
end

function m.set_state(state)
  bgfx.set_state(state or bgfx.STATE_DEFAULT, 0)
end

function m.save_screenshot(filename, target)
  local fb = target and target.framebuffer
  if not fb then
    fb = m.invalid_handle(bgfx.frame_buffer_handle_t)
  end
  bgfx.request_screen_shot(fb, filename)
end

return m
