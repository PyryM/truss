local m = {}

local raw_create_window = nil
local raw_destroy_window = nil
local raw_pointer = nil
local raw_get_event = nil
local raw_num_events = nil
local raw_window_width = nil
local raw_window_height = nil

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
    raw_num_events = addon_c.truss_sdl_num_events
    raw_get_event = addon_c.truss_sdl_get_event
    raw_window_width = addon_c.truss_sdl_window_width
    raw_window_height = addon_c.truss_sdl_window_height
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

function m.create_window(width, height, name, fullscreen)
    raw_create_window(raw_pointer, width, height, name, fullscreen or 0)
end

function m.get_window_size()
  local h = raw_window_height(raw_pointer)
  local w = raw_window_width(raw_pointer) 

  return w, h 
end

function m.set_clipboard(data)
    return m.rawfunctions.truss_sdl_set_clipboard(raw_pointer, data)
end

function m.get_clipboard()
    local cstr = m.rawfunctions.truss_sdl_get_clipboard(raw_pointer)
    if not cstr then return nil end
    return ffi.string(cstr)
end

function m.set_relative_mouse_mode(mode)
    m.rawfunctions.truss_sdl_set_relative_mouse_mode(raw_pointer, mode)
end

function m.get_bgfx_callback()
    return m.rawfunctions.truss_sdl_get_bgfx_cb(raw_pointer)
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

return m
