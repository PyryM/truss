-- gfx/common.t
--
-- basic gfx stuff

local m = {}
m.frame_index = 0
m.bgfx_frame_index = 0
m._scheduled_tasks = {}

function m.init_gfx(options)
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
  bgfx.reset(options.width or 800, options.height or 600, reset)
  m._bgfx_initted = true

  bgfx.set_debug(debug)

  log.info("initted bgfx")
  local renderer_type = bgfx.get_renderer_type()
  local renderer_name = ffi.string(bgfx.get_renderer_name(renderer_type))
  m.renderer_name = renderer_name
  m.renderer_type = renderer_type
  m.short_renderer_name = m._translate_renderer_type(renderer_type)
  log.info("Renderer name: " .. renderer_name)
  log.info("Short renderer name: " .. m.short_renderer_name)
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
end

function m.get_renderer_name()
  return m.renderer_name
end

function m.get_renderer_type()
  return m.short_renderer_name
end

function m.frame()
  m.frame_index = m.frame_index + 1
  m.bgfx_frame_index = bgfx.frame(false)
end

return m