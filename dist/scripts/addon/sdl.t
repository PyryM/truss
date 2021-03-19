local m = {}

local raw_create_window = nil
local raw_destroy_window = nil
local raw_pointer = nil
local raw_get_event = nil
local raw_num_events = nil
local raw_window_size = nil
local raw_window_gl_size = nil
local raw_resize_window = nil

local function wrap(addon)
  local addon_c, addon_pointer = addon.functions, addon.pointer
  local addon_version = addon.version
  -- rename constants from TRUSS_SDL_EVENT_... to just EVENT_...
  -- so that they can be accessed by sdl.EVENT_...
  local modutils = require("core/module.t")
  modutils.reexport_without_prefix(addon_c, "TRUSS_SDL_", m)

  -- store raw functions into local variables
  -- (hide them in upvalues to make them 'private')
  raw_create_window = addon_c.truss_sdl_create_window
  raw_destroy_window = addon_c.truss_sdl_destroy_window
  raw_resize_window = addon_c.truss_sdl_resize_window
  raw_num_events = addon_c.truss_sdl_num_events
  raw_get_event = addon_c.truss_sdl_get_event
  raw_window_size = addon_c.truss_sdl_window_size
  raw_window_gl_size = addon_c.truss_sdl_window_gl_size
  raw_pointer = addon_pointer

  m.VERSION = addon_version
  m.rawfunctions = addon_c
  m.rawpointer = addon_pointer
end

if not truss.addons.sdl then
  truss.error("cannot use sdl.t: sdl addon not mounted!")
end
wrap(truss.addons.sdl)

function m.start_text_input()
  return m.rawfunctions.truss_sdl_start_textinput(raw_pointer)
end

function m.stop_text_input()
  return m.rawfunctions.truss_sdl_stop_textinput(raw_pointer)
end

function m.create_window(width, height, name, fullscreen, display)
  local t0 = truss.tic()
  if type(fullscreen) ~= "number" then
    fullscreen = (fullscreen and 1) or 0
  end
  raw_create_window(raw_pointer, width, height, name, fullscreen or 0, display or 0)
  local dt = truss.toc(t0) * 1000.0
  log.info(string.format("Took %.2f ms to create window.", dt))
end

function m.get_displays()
  local n_displays = m.rawfunctions.truss_sdl_get_display_count(raw_pointer)
  local ret = {}
  for idx = 1, n_displays do
    ret[idx] = m.rawfunctions.truss_sdl_get_display_bounds(raw_pointer, idx-1)
  end
  return ret
end

function m.create_window_ex(x, y, w, h, name, is_borderless)
  m.rawfunctions.truss_sdl_create_window_ex(
    raw_pointer, x, y, w, h, name, (is_borderless and 1) or 0
  )
end

function m.resize_window(width, height, fullscreen)
  raw_resize_window(raw_pointer, width, height, fullscreen or 0)
end

function m.get_window_size()
  local s = raw_window_size(raw_pointer)
  return s.w, s.h
end

function m.get_window_gl_size()
  local s = raw_window_gl_size(raw_pointer)
  return s.w, s.h
end

function m.set_clipboard(data)
  return m.rawfunctions.truss_sdl_set_clipboard(raw_pointer, data)
end

function m.get_clipboard()
  local cstr = m.rawfunctions.truss_sdl_get_clipboard(raw_pointer)
  if not cstr then return nil end
  return ffi.string(cstr)
end

function m.get_filedrop_path()
  local cstr = m.rawfunctions.truss_sdl_get_filedrop_path(raw_pointer)
  if not cstr then return nil end
  return ffi.string(cstr)
end

function m.create_user_path(orgname, appname)
  local cpath = m.rawfunctions.truss_sdl_get_user_path(raw_pointer, 
                                                       orgname, appname)
  return ffi.string(cpath)
end

function m.set_relative_mouse_mode(mode)
  local mode_int = 0
  if mode then mode_int = 1 end
  m.rawfunctions.truss_sdl_set_relative_mouse_mode(raw_pointer, mode_int)
end

function m.show_cursor(visible)
  local v = (visible and 1) or 0
  m.rawfunctions.truss_sdl_show_cursor(raw_pointer, v)
end

function m.create_cursor_aoa(slot, arr, hx, hy)
  local nrows = #arr
  local ncols = #(arr[1])
  if ncols % 8 > 0 or nrows % 8 > 0 then
    truss.error("Cursors must have multiple of 8 dimensions")
  end
  local data = terralib.new(uint8[nrows * ncols / 8])
  local mask = terralib.new(uint8[nrows * ncols / 8])
  local dpos = 0
  for r = 1, nrows do
    local c = 1
    for pc = 1, (ncols/8) do
      local b_data = 0
      local b_mask = 0
      local mult = 128
      for bit_idx = 0, 7 do
        local dval = arr[r][c]
        if dval > 0 then mask[dpos] = mask[dpos] + mult end
        if dval > 1 or dval < 0 then data[dpos] = data[dpos] + mult end
        c = c + 1
        mult = mult / 2
      end
      dpos = dpos + 1
    end
  end
  return m.rawfunctions.truss_sdl_create_cursor(
    raw_pointer, 
    slot, 
    data, mask, 
    ncols, nrows, 
    hx or 0, hy or 0
  )
end

function m.set_cursor(slot)
  return m.rawfunctions.truss_sdl_set_cursor(raw_pointer, slot)
end

function m.get_bgfx_callback()
  return m.rawfunctions.truss_sdl_get_bgfx_cb(raw_pointer)
end

m._controller_map = {}
m._reverse_controller_map = {}
function m.enable_controller(idx)
  local inst_id = m.rawfunctions.truss_sdl_enable_controller(raw_pointer, idx)
  if inst_id >= 0 then
    local info = {
      id = idx, 
      instance_id = inst_id, 
      name = ffi.string(m.rawfunctions.truss_sdl_get_controller_name(raw_pointer, idx))
    }
    m._reverse_controller_map[idx] = inst_id
    m._controller_map[inst_id] = info
    return info
  end
end

function m.disable_controller(idx)
  local inst_id = m._reverse_controller_map[idx]
  if inst_id then
    m._controller_map[inst_id] = nil
    m._reverse_controller_map[idx] = nil
    m.rawfunctions.truss_sdl_disable_controller(raw_pointer, idx)
  end
end

local function event_iterator(state)
  local idx = state.idx
  if idx >= state.n then
    return nil
  else
    state.idx = idx + 1
    return raw_get_event(raw_pointer, idx)
  end
end

-- allows iteration e.g.,
--  for evt in sdl:events() do ... end
function m.events()
  local n = raw_num_events(raw_pointer)
  return event_iterator, {idx=0, n=n}
end

-- convenience function to just handle closing the window
function m.handle_minimal_events()
  for evt in m.events() do
    if evt.event_type == m.EVENT_WINDOW and evt.flags == 14 then
      log.info("Received window close, quitting")
      truss.quit()
    end
  end
end

return m
