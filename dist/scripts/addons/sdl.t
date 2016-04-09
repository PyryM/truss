local m = {}

local raw_create_window = nil
local raw_destroy_window = nil
local raw_pointer = nil
local raw_get_event = nil
local raw_num_events = nil

function m.wrap(addonName, addonTable, addonPointer, addonVersion)
    -- rename constants from TRSS_SDL_EVENT_... to just EVENT_...
    -- so that they can be accessed by sdl.EVENT_... 
    for k,v in pairs(addonTable) do
        local prefix = 'TRSS_SDL_'
        if string.find(k, prefix) then
            local newname = string.sub(k, string.len(prefix)+1)
            m[newname] = v
        end
    end

    -- store raw functions into local variables
    -- (hide them in upvalues to make them 'private')
    raw_create_window = addonTable.trss_sdl_create_window
    raw_destroy_window = addonTable.trss_sdl_destroy_window
    raw_num_events = addonTable.trss_sdl_num_events
    raw_get_event = addonTable.trss_sdl_get_event
    raw_pointer = addonPointer

    m.VERSION = addonVersion
    m.rawfunctions = addonTable
    m.rawpointer = addonPointer

    return m
end

function m:startTextinput()
    return m.rawfunctions.trss_sdl_start_textinput(raw_pointer)
end

function m:stopTextinput()
    return m.rawfunctions.trss_sdl_stop_textinput(raw_pointer)
end

function m:createWindow(width, height, name)
    raw_create_window(raw_pointer, width, height, name)
end

function m:setClipboard(data)
    return m.rawfunctions.trss_sdl_set_clipboard(raw_pointer, data)
end

function m:setRelativeMouseMode(mode)
    m.rawfunctions.trss_sdl_set_relative_mouse_mode(raw_pointer, mode)
end

function m:getClipboard()
    local cstr = m.rawfunctions.trss_sdl_get_clipboard(raw_pointer)
    if not cstr then return nil end
    return ffi.string(cstr)
end

function m:getBGFXCallback()
    return m.rawfunctions.trss_sdl_get_bgfx_cb(raw_pointer)
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
function m:events()
    local n = raw_num_events(raw_pointer)
    return event_iterator, {idx=0, n=n}
end

return m