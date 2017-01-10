-- ecs/entity.t
--
-- the base entity for the entity component system

local class = require("class")
local sg = require("scenegraph/scenegraph.t")
local event = require("ecs/event.t")
local m = {}

local Entity = class("Entity")
m.Entity = Entity
Entity:with(sg.ScenegraphMixin)
function Entity:init(name)
  self._components = {}
  self._event_handlers = {}
  self:sg_init()
  if name then self.name = name end
end

-- return a string identifying this component for error messages
function Entity:error_name(funcname)
  return "Entity[" .. (self.name or "?") .. "]: "
end

-- throw an error with convenient formatting
function Entity:error(error_message)
  truss.error(self:error_name() .. error_message)
end

-- add a component *instance* to an entity
-- the name must be unique, and cannot be any of the keys in the entity
function Entity:add_component(component, component_name)
  component_name = component_name or component.mount_name
  if self[component_name] then
    self:error("[" .. component_name .. "] is already key in entity!")
  end

  if self._components[component_name] then
    self:error("[" .. component_name .. "] is already in entity!")
  end

  self._components[component_name] = component
  self[component_name] = component
  component:mount(self, component_name)
end

-- remove a component by its mounted name
function Entity:remove_component(component_name)
  local comp = self._components[component_name]
  if not comp then
    log.warning(self:error_name() .. "tried to remove component ["
                .. component_name .. "] that doesn't exist.")
    return
  end
  self._components[component_name] = nil
  self[component_name] = nil
  comp:unmount(self)
  self:_remove_handlers(comp)
end

function Entity:_add_handler(event_name, component)
  self._event_handlers[event_name] = self._event_handlers[event_name] or {}
  self._event_handlers[event_name][component] = component
end

function Entity:_remove_handlers(component)
  for _, handlers in pairs(self._event_handlers) do
    handlers[component] = nil
  end
end

function Entity:_auto_add_handlers(component)
  local c = component.class or component
  for k,v in pairs(c) do
    if type(v) == "function" and k:sub(1, 3) == "on_" then
      self:_add_handler(k, component)
    end
  end
end

local function dispatch_event(targets, event_name, arg)
  if not targets then return end
  for _, handler in pairs(targets) do
    -- i.e., for "on_update", first try handler:on_update(arg)
    -- then fall back to handler:event("on_update", arg)
    if handler[event_name] then
      handler[event_name](handler, arg)
    elseif handler.event then
      handler:event(event_name, arg)
    end
  end
end

-- send an event to any components that want to handle it
function Entity:event(event_name, arg)
  --dispatch_event(self._event_handlers["*"], event_name, arg)
  dispatch_event(self._event_handlers[event_name], event_name, arg)
end

return m
