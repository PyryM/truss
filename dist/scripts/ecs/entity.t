-- ecs/entity.t
--
-- the base entity for the entity component system

local class = require("class")
local math = require("math")
local event = require("ecs/event.t")
local m = {}

local Entity = class("Entity")
m.Entity = Entity
function Entity:init(name, ...)
  self._components = {}
  self._event_handlers = {}
  self.children = {}
  self.enabled = true
  self.name = name or "entity"
  self.user_handlers = {} -- a pseudo-component to hold user attached handlers

  for _, comp in ipairs({...}) do
    self:add_component(comp)
  end
end

-- return a string identifying this component for error messages
function Entity:error_name(funcname)
  return "Entity[" .. (self.name or "?") .. "]: "
end

-- throw an error with convenient formatting
function Entity:error(error_message)
  truss.error(self:error_name() .. error_message)
end

-- how deep a scenegraph tree can be
m.MAX_TREE_DEPTH = 200
-- check whether adding a prospective child to a parent
-- would cause a cycle (i.e., that our scene tree would
-- no longer be a tree)
local function would_cause_cycle(parent, child)
  -- we would have a cycle if tracing the parent up
  -- to root would encounter the child or itself
  local depth = 0
  local curnode = parent
  local MAXD = m.MAX_TREE_DEPTH
  while curnode ~= nil do
    curnode = curnode.parent
    if curnode == parent or curnode == child then
      return true, "Adding child would have caused cycle!"
    end
    depth = depth + 1
    if depth > MAXD then
      return true, "Adding child would exceed max tree depth!"
    end
  end
  return false
end

function Entity:add(child)
  if not child then
    truss.error("Cannot add nil as child.")
    return false
  end
  if would_cause_cycle(self, child) then
    local _, errmsg = would_cause_cycle(self, child)
    truss.error("Cyclic add: " .. errmsg)
    return false
  end

  -- remove child from its previous parent
  if child.parent then
    child.parent:remove(child)
  end

  self.children[child] = child
  child.parent = self

  if child._sg_root ~= self._sg_root then
    child:configure_recursive(self._sg_root)
  end

  return true
end

-- call a function on this node and its descendents
function Entity:call_recursive(func_name, ...)
  if self[func_name] then self[func_name](self, ...) end
  for _, child in pairs(self.children) do
    child:call_recursive(func_name, ...)
  end
end

function Entity:configure_recursive(sg_root)
  self._sg_root = sg_root
  if self.configure then self:configure(sg_root) end
  for _,child in pairs(self.children) do child:configure_recursive(sg_root) end
end

function Entity:remove(child)
  if not self.children[child] then return end
  self.children[child] = nil
  child.parent = nil
end

function Entity:configure(sg_root)
  sg_root = sg_root or self._sg_root
  for _,comp in pairs(self._components) do
    if comp.configure then comp:configure(sg_root) end
  end
end

-- add a component *instance* to an entity
-- the name must be unique, and cannot be any of the keys in the entity
function Entity:add_component(component, component_name)
  component_name = component_name or component.mount_name or component.name
  if self[component_name] then
    self:error("[" .. component_name .. "] is already key in entity!")
  end

  if self._components[component_name] then
    self:error("[" .. component_name .. "] is already in entity!")
  end

  self._components[component_name] = component
  self[component_name] = component
  if component.mount then component:mount(self, component_name) end
  if self._sg_root and component.configure then
    component:configure(self._sg_root)
  end

  return component
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
  if comp.unmount then comp:unmount(self) end
  self:_remove_handlers(comp)
end

function Entity:_add_handler(event_name, component)
  self._event_handlers[event_name] = self._event_handlers[event_name] or {}
  self._event_handlers[event_name][component] = component
end

function Entity:_remove_handler(event_name, component)
  (self._event_handlers[event_name] or {})[component] = nil
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
    -- then fall back to handler:on_event("on_update", arg)
    if handler[event_name] then
      handler[event_name](handler, arg)
    elseif handler.on_event then
      handler:on_event(event_name, arg)
    end
  end
end

-- send an event to any components that want to handle it
function Entity:event(event_name, arg)
  dispatch_event(self._event_handlers["on_event"], event_name, arg)
  dispatch_event(self._event_handlers[event_name], event_name, arg)
end

-- send an event to this entity and all its descendents
function Entity:event_recursive(event_name, arg)
  self:call_recursive("event", event_name, arg)
end

-- attach a function directly as an event handler
-- gets added to the "user_handlers" pseudo-component
-- only one such 'user handler' can be attached for any given event
function Entity:on(event_name, f)
  event_name = "on_" .. event_name
  if f then
    -- want function to be called as f(entity, [args]) not f(comp, [args])
    -- because the 'component' that it belongs to is a bare table user_handlers
    local f2 = function(_, ...)
      f(self, ...)
    end
    self.user_handlers[event_name] = f2
    self:_add_handler(event_name, self.user_handlers)
  else -- remove existing handlers
    self.user_handlers[event_name] = nil
    self:_remove_handler(event_name, self.user_handlers)
  end
end

-- force call a function on every component for which it exists
function Entity:broadcast(func_name, ...)
  for _, component in pairs(self._components) do
    if component[func_name] then component[func_name](component, ...) end
  end
end

-- call a function on every component for this entity and its descendents
function Entity:broadcast_recursive(func_name, ...)
  self:call_recursive("broadcast", func_name, ...)
end

-- plain Entity doesn't have a world mat
function Entity:recursive_update_world_mat(parentmat)
  -- do nothing (maybe recurse to children?)
end


local Entity3d = Entity:extend("Entity3d")
m.Entity3d = Entity3d

function Entity3d:init(name, ...)
  self.position = math.Vector(0.0, 0.0, 0.0, 0.0)
  self.scale = math.Vector(1.0, 1.0, 1.0, 0.0)
  self.quaternion = math.Quaternion():identity()
  self.matrix = math.Matrix4():identity()
  self.matrix_world = math.Matrix4():identity()
  -- call super.init after adding these fields, because some component might
  -- need to have e.g. .matrix available in its :mount
  Entity3d.super.init(self, name, ...)
end

function Entity3d:update_matrix()
  self.matrix:compose(self.position, self.quaternion, self.scale)
end

-- recursively calculate world matrices from local transforms for
-- object and all its children
function Entity3d:recursive_update_world_mat(parentmat)
  if self.enabled == false or (not self.matrix) then return end

  self.matrix_world:multiply(parentmat, self.matrix)

  for _,child in pairs(self.children) do
    child:recursive_update_world_mat(self.matrix_world)
  end
end

return m
