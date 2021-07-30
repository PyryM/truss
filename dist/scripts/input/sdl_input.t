-- input/sdl_input.t
--
-- sdl input components

local class = require("class")
local ecs = require("ecs")
local SDL = require("./sdl.t")
local m = {}

local SDLInputSystem = class("SDLInputSystem")

local EVENT_INFO = {
  [SDL.KEYDOWN] = {"keydown", "key"},
  [SDL.KEYUP] = {"keyup", "key"},
  [SDL.MOUSEBUTTONDOWN] = {"mousedown", "mouse"},
  [SDL.MOUSEBUTTONUP] = {"mouseup", "mouse"},
  [SDL.MOUSEMOTION] = {"mousemove", "mouse"},
  [SDL.MOUSEWHEEL] = {"mousewheel", "mouse"},
  [SDL.WINDOWEVENT] = {"window", "window"},
  [SDL.TEXTINPUT] = {"textinput", "key"},
  --[[
  [9] = {"gamepad_added", "gamepad_sys"},
  [10] = {"gamepad_removed", "gamepad_sys"},
  [11] = {"gamepad_axis", "gamepad"},
  [12] = {"gamepad_buttondown", "gamepad"},
  [13] = {"gamepad_buttonup", "gamepad"},
  ]]
  [SDL.DROPFILE] = {"filedrop", "filedrop"}
}

function SDLInputSystem:init(options)
  self.mount_name = "input"
  options = options or {}
  self._autoclose = (options.autoclose ~= false)
  self.evt = ecs.EventEmitter()
  self.keystate = {}
  self.window = assert(options.window)
end

function SDLInputSystem:on(...)
  self.evt:on(...)
end

local function translate_key_flags(flags)
  -- TODO
  return nil
end

local AXIS_NAMES = {
  "LEFTX",
  "LEFTY",
  "RIGHTX",
  "RIGHTY",
  "TRIGGERLEFT",
  "TRIGGERRIGHT"
}

local BUTTON_NAMES = {
  "A",
  "B",
  "X",
  "Y",
  "BACK",
  "GUIDE",
  "START",
  "LEFTSTICK",
  "RIGHTSTICK",
  "LEFTSHOULDER",
  "RIGHTSHOULDER",
  "DPAD_UP",
  "DPAD_DOWN",
  "DPAD_LEFT",
  "DPAD_RIGHT"
}

local function convert_gamepad_event(evt_type, evt)
  local info = sdl._controller_map[evt.flags]
  local ret = {
    id = info.id,
    controller_name = info.name
  }
  if evt_type == "gamepad_axis" then
    ret.axis = evt.x
    ret.axis_name = AXIS_NAMES[evt.x + 1]
    ret.value = evt.y
  else -- button
    ret.button = evt.x
    ret.button_name = BUTTON_NAMES[evt.x + 1]
    ret.down = (evt_type == "gamepad_buttondown")
  end
  return ret
end

local function convert_filedrop_event(evt_type, evt)
  local path = self.window:get_filedrop_path()
  return {
    path = ffi.string(path.str, path.len)
  }
end

local function convert_event(evt)
  local evt_name, evt_class = unpack(EVENT_INFO[evt.event_type])
  local new_evt
  if evt_class == "key" then
    new_evt = {}
    new_evt.keyname = ffi.string(SDL.GetKeyName(evt.keycode))
    new_evt.flags = translate_key_flags(evt.flags)
  elseif evt_class == "mouse" then
    -- TODO
    new_evt = evt
  elseif evt_class == "window" then
    -- TODO
    new_evt = evt
  elseif evt_class == "gamepad_sys" then
    new_evt = evt
  elseif evt_class == "gamepad" then
    new_evt = convert_gamepad_event(evt_name, evt)
  elseif evt_class == "filedrop" then
    new_evt = convert_filedrop_event(evt_name, evt)
  end
  return evt_name, new_evt
end

function SDLInputSystem:update()
  local still_open = self.window:poll_events()
  if self._autoclose and (not still_open) then
    truss.quit()
    return
  end
  for idx = 1, self.window:get_event_count() do
    local evt = self.window:get_event(idx-1)
    local evtname, new_evt = convert_event(evt)
    if evtname == "keydown" then
      self.keystate[new_evt.keyname] = true
    elseif evtname == "keyup" then
      self.keystate[new_evt.keyname] = false
    end
    self.evt:emit(evtname, new_evt)
  end
end

m.SDLInputSystem = SDLInputSystem
return m
