-- input/sdl_input.t
--
-- sdl input components

local class = require("class")
local ecs = require("ecs")
local m = {}

local SDLInputSystem = class("SDLInputSystem")

local EVENT_INFO = {
  [0] = {"outofbounds", "bounds"},
  [1] = {"keydown", "key"},
  [2] = {"keyup", "key"},
  [3] = {"mousedown", "mouse"},
  [4] = {"mouseup", "mouse"},
  [5] = {"mousemove", "mouse"},
  [6] = {"mousewheel", "mouse"},
  [7] = {"window", "window"},
  [8] = {"textinput", "key"}
}

local sdl = nil
function SDLInputSystem:init(options)
  sdl = sdl or require("addons/sdl.t")
  self.mount_name = "input"
  options = options or {}
  self._autoclose = (options.autoclose ~= false)
  self.evt = ecs.EventEmitter()
end

function SDLInputSystem:on(...)
  self.evt:on(...)
end

local function translate_key_flags(flags)
  -- TODO
  return nil
end

local function convert_event(evt)
  local evt_name, evt_class = unpack(EVENT_INFO[evt.event_type])
  local new_evt = {}
  if evt_class == "key" then
    new_evt.keyname = ffi.string(evt.keycode)
    new_evt.flags = translate_key_flags(evt.flags)
  elseif evt_class == "mouse" then
    -- TODO
    new_evt = evt
  elseif evt_class == "window" then
    -- TODO
    new_evt = evt
  end
  return evt_name, new_evt
end

function SDLInputSystem:update()
  for evt in sdl.events() do
    if self._autoclose and evt.event_type == sdl.EVENT_WINDOW and evt.flags == 14 then
      truss.quit()
    end
    local evtname, new_evt = convert_event(evt)
    self.evt:emit(evtname, new_evt)
  end
end

m.SDLInputSystem = SDLInputSystem
return m
