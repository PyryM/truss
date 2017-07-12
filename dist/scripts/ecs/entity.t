-- ecs/entity.t
--
-- the base entity for the entity component system

local class = require("class")
local math = require("math")
local m = {}

local Entity = class("Entity")
m.Entity = Entity
function Entity:init(ecs, name, ...)
  self.ecs = ecs
  self._components = {}
  self.children = {}
  self.name = name or "entity"
  self.unique_name = ecs:get_unique_name(self.name)
  self.event = false -- to prevent overriding of this

  for _, comp in ipairs({...}) do
    self:add_component(comp)
  end
end

-- create an entity in the same ecs as this entity
function Entity:create(constructor, ...)
  return self.ecs:create(constructor, ...)
end

-- create an entity as a child of this entity
function Entity:create_child(constructor, ...)
  return self:add(self:create(constructor, ...))
end

-- return a string identifying this component for error messages
function Entity:log_name(funcname)
  return "Entity[" .. (self.unique_name) .. "]: "
end

-- throw an error with convenient formatting
function Entity:error(message)
  truss.error(self:log_name() .. message)
end

-- throw a warning with convenient formatting
function Entity:warning(message)
  truss.warning(self:log_name() .. message)
end

-- check whether adding a prospective child to a parent
-- would cause a cycle (i.e., that our scene tree would
-- no longer be a tree)
local function assert_cycle_free(parent, child, err_on_failure)
  if parent:is_in_subtree(child) then
    if err_on_failure then
      truss.error("Cyclical reparent.")
    end
    return false
  else
    return true
  end
end

-- check if this entity is in a subtree rooted at a given entity
function Entity:is_in_subtree(other)
  if not other then return false end
  local curnode = self
  while curnode ~= nil do
    if curnode == other then return true end
    curnode = curnode.parent
  end
  -- got to root without hitting other
  return false
end

-- set an entity's parent
-- the entity is removed from its previous parent (if any)
-- setting a nil parent removes it from the tree
-- if the operation would cause a cycle, an error is thrown
function Entity:set_parent(parent)
  if parent == self.parent then return end
  if self.parent then
    self.parent.children[self] = nil
  end
  if parent then
    if not assert_cycle_free(parent, self, true) then return false end
    parent.children[self] = self
  end
  self.parent = parent
end

function Entity:add_child(child)
  child:set_parent(self)
  return child
end
Entity.add = Entity.add_child -- alias for backwards compatibility

function Entity:remove_child(child)
  if not self.children[child] then
    self:error("Entity does not have child " .. tostring(child))
    return
  end
  child:set_parent(nil)
  return child
end
Entity.remove = Entity.remove_child

function Entity:detach()
  self:set_parent(nil)
end

function Entity:destroy(recursive)
  if recursive then
    self:call_recursive("destroy", false)
  else
    self:set_parent(nil)
    self._dead = true
    self:destroy_components()
  end
end

function Entity:destroy_components()
  for mount_name, comp in pairs(self._components) do
    comp._dead = true
    if comp.destroy then comp:destroy() end
    self[mount_name] = nil
  end
  self._components = {}
end

function Entity:sleep(recursive)
  if recursive then
    self:call_recursive("sleep", false)
  else
    for _, comp in pairs(self._components) do
      comp:sleep()
    end
  end
end

function Entity:wake(recursive)
  if recursive then
    self:call_recursive("wake", false)
  else
    for _, comp in pairs(self._components) do
      comp:wake()
    end
  end
end

-- call a function on this node and its descendants
function Entity:call_recursive(func_name, ...)
  if self[func_name] then self[func_name](self, ...) end
  for _, child in pairs(self.children) do
    child:call_recursive(func_name, ...)
  end
end

-- call f(ent) on this entity and all its descendants
function Entity:traverse(f)
  f(self)
  for _, child in pairs(self.children) do
    child:traverse(f)
  end
end

-- allow iteration over this entity and all its descendants
function Entity:iter_tree()
  local co = coroutine.create(function() self:traverse(coroutine.yield) end)
  return function()   -- iterator
    local code, res = coroutine.resume(co)
    return res
  end
end

-- add a component *instance* to an entity
-- the name must be unique, and cannot be any of the keys in the entity
function Entity:add_component(component, component_name)
  component_name = component_name or component.mount_name or component.name
  if self[component_name] ~= nil then
    self:error("[" .. component_name .. "] is already key in entity!")
  end

  if self._components[component_name] then
    self:error("[" .. component_name .. "] is already in entity!")
  end

  self._components[component_name] = component
  self[component_name] = component
  component.ent = self
  if component.mount then
    component:mount(self, component_name, self.ecs)
  end

  return component
end

-- remove a component by its mounted name
function Entity:remove_component(component_name)
  local comp = self._components[component_name]
  if not comp then
    self:warning("can't remove nonexistent comp [" .. component_name .. "]")
    return
  end
  self._components[component_name] = nil
  self[component_name] = nil
  if comp.unmount then comp:unmount(self) end
end

function Entity:emit(event_name, evt)
  if not self.event then return end
  self.event:emit(event_name, evt)
end

-- send an event to this entity and all its descendants
function Entity:emit_recursive(event_name, evt)
  self:call_recursive("emit", event_name, evt)
end

function Entity:on(event_name, receiver, callback)
  if not self.event then
    self.event = require("ecs/event.t").EventEmitter()
  end
  self.event:on(event_name, receiver, callback)
end

-- plain Entity doesn't have a world mat
function Entity:recursive_update_world_mat(parentmat)
  -- do nothing (maybe recurse to children?)
end

local Entity3d = Entity:extend("Entity3d")
m.Entity3d = Entity3d

function Entity3d:init(ecs, name, ...)
  self.position = math.Vector(0.0, 0.0, 0.0, 0.0)
  self.scale = math.Vector(1.0, 1.0, 1.0, 0.0)
  self.quaternion = math.Quaternion():identity()
  self.matrix = math.Matrix4():identity()
  self.matrix_world = math.Matrix4():identity()
  -- call super.init after adding these fields, because some component might
  -- need to have e.g. .matrix available in its :mount
  Entity3d.super.init(self, ecs, name, ...)
end

function Entity3d:update_matrix()
  self.matrix:compose(self.position, self.quaternion, self.scale)
end

-- recursively calculate world matrices from local transforms for
-- object and all its children
function Entity3d:recursive_update_world_mat(parentmat)
  if not self.matrix then return end
  self.matrix_world:multiply(parentmat, self.matrix)
  for _,child in pairs(self.children) do
    child:recursive_update_world_mat(self.matrix_world)
  end
end

return m
