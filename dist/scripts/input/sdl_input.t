-- input/sdl_input.t
--
-- sdl input components

local class = require("class")
local ecs = require("ecs")
local m = {}

local SDLInputSystem = class("SDLInputSystem")

local EVENT_NAMES = {
  [0] = "on_outofbounds",
  [1] = "on_keydown",
  [2] = "on_keyup",
  [3] = "on_mousedown",
  [4] = "on_mouseup",
  [5] = "on_mousemove",
  [6] = "on_mousewheel",
  [7] = "on_window",
  [8] = "on_textinput"
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

function SDLInputSystem:update()
  for evt in sdl.events() do
    if self._autoclose and evt.event_type == sdl.EVENT_WINDOW and evt.flags == 14 then
      truss.quit()
    end
    local evtname = EVENT_NAMES[evt.event_type]
    self.evt:emit(evtname, evt)
  end
end

m.SDLInputSystem = SDLInputSystem
return m
