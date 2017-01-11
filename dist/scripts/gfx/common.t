-- gfx/common.t
--
-- basic gfx stuff

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

function m.init_gfx(options)
  local gfx = require("gfx") -- so we can set module level values

  if m._bgfx_initted then
    truss.error("Tried to init gfx twice.")
    return
  end

  options = options or {}

  local debug = 0
  if options.debugtext then
    debug = debug + bgfx.DEBUG_TEXT
  end
  local reset = 0
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

    -- put bgfx into single-threaded mode by calling render_frame before init
    m._safe_wait_frames = 1
    bgfx.render_frame()
  end

  local cb_ptr = nil
  --sdl:getBGFXCallback()
  local renderer_type = bgfx.RENDERER_TYPE_COUNT
  if options.renderer then
    local rname = "RENDERER_TYPE_" .. options.renderer
    renderer_type = bgfx[rname]
  end

  bgfx.init(renderer_type, 0, 0, cb_ptr, nil)
  if not options.window and (not options.width or not options.height) then
    truss.error("gfx.init_gfx needs to be supplied with width and height.")
  end
  local w, h = options.width, options.height
  if options.window then
    w, h = options.window.get_window_size()
  end
  bgfx.reset(w, h, reset)
  gfx.backbuffer_width, gfx.backbuffer_height = w, h
  m._bgfx_initted = true

  bgfx.set_debug(debug)

  log.info("initted bgfx")
  local renderer_type = bgfx.get_renderer_type()
  local renderer_name = ffi.string(bgfx.get_renderer_name(renderer_type))
  gfx.renderer_name = renderer_name
  gfx.renderer_type = renderer_type
  gfx.short_renderer_name = m._translate_renderer_type(renderer_type)
  log.info("Renderer name: " .. renderer_name)
  log.info("Short renderer name: " .. gfx.short_renderer_name)
end

function m._translate_renderer_type(bgfx_type)
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

local state_aliases = {primitive = "pt"}
m.DefaultStateOptions = {
  rgb_write = true, depth_write = true, alpha_write = true,
  conservative_raster = false, msaa = true,
  depth_test = "less", cull = "cw", blend = false, pt = false
}

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

function m.set_state(state)
  bgfx.set_state(state or bgfx.STATE_DEFAULT, 0)
end

return m
