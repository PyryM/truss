-- ecs/sdl_input.t
--
-- sdl input components

local class = require("class")
local component = require("ecs/component.t")
local m = {}

local SDLInputComponent = component.Component:extend("SDLInputComponent")
local SDLInputSystem = class("SDLInputSystem")

function SDLInputComponent:init()
  self.mount_name = "SDLInput"
end

function SDLInputComponent:configure(ecs_root)
  self._sdl_system = ecs_root.systems.SDLInput
  if not self._sdl_system then
    truss.error("SDLInput component used but no SDLInputSystem in ECS!")
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

function SDLInputComponent:on_update()
  -- make sure the sdl input subsystem exists
  if not self._sdl_system or not self._entity then return

  -- iterate through sdl events and dispatch them to the entity
  for _, evt in ipairs(self._sdl_system.events) do
    local evtname = EVENT_NAMES[evt.event_type]
    self._entity:event(evtname, evt)
  end
end

function SDLInputSystem:init()
  self.events = {}
  self.sdl = require("addons/sdl.t")
end

function SDLInputSystem:update()
  -- just store all the events
  self.events = {}
  for evt in self.sdl.events() do
    table.insert(self.events, evt)
  end
end

m.SDLInputComponent = SDLInputComponent
m.SDLInputSystem = SDLInputSystem
return m
