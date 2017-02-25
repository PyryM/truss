-- ecs/sdl_input.t
--
-- sdl input components

local class = require("class")
local component = require("ecs/component.t")
local m = {}

local SDLInputComponent = component.Component:extend("SDLInputComponent")
local SDLInputSystem = class("SDLInputSystem")

function SDLInputComponent:init()
  self.mount_name = "sdl_input"
end

function SDLInputComponent:configure(ecs_root)
  self._sdl_system = ecs_root.systems.sdl_input
  if not self._sdl_system then
    truss.error("SDLInput component used but no sdl_input in ECS!")
  end
end

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

-- Note that we use preupdate because might want to change scenegraph
function SDLInputComponent:on_preupdate()
  -- make sure the sdl input subsystem exists
  if not self._sdl_system or not self._entity then return end

  -- iterate through sdl events and dispatch them to the entity
  for _, evt in ipairs(self._sdl_system.events) do
    local evtname = EVENT_NAMES[evt.event_type]
    self._entity:event(evtname, evt)
  end
end

local sdl = nil
function SDLInputSystem:init(options)
  self.events = {}
  sdl = sdl or require("addons/sdl.t")
  self.mount_name = "sdl_input"
  options = options or {}
  self._autoclose = (options.autoclose ~= false)
end

function SDLInputSystem:update_begin()
  -- just store all the events
  self.events = {}
  for evt in sdl.events() do
    if self._autoclose and evt.event_type == sdl.EVENT_WINDOW and evt.flags == 14 then
      truss.quit()
    end
    table.insert(self.events, evt)
  end
end

m.SDLInputComponent = SDLInputComponent
m.SDLInputSystem = SDLInputSystem
return m
