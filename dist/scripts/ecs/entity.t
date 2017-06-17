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
local function assert_cycle_free(parent, child, err_on_failure)
  -- we would have a cycle if tracing the parent up
  -- to root would encounter the child or itself
  local depth = 0
  local curnode = parent
  local MAXD = m.MAX_TREE_DEPTH
  while curnode ~= nil do
    curnode = curnode.parent
    if curnode == parent or curnode == child then
      if err_on_failure then truss.error("Cyclical reparent.") end
      return false
    end
    depth = depth + 1
    if depth > MAXD then
      if err_on_failure then truss.error("Max tree depth exceeded.") end
      return false
    end
  end
  return true
end

-- internal function to set an entity's parent
-- used for adding, removing, and moving
function Entity:_set_parent(parent)
  if self.parent then
    self.parent.children[self] = nil
  end
  if parent then
    if not assert_cycle_free(parent, self, true) then return false end
    parent.children[self] = self
    self.parent = parent
    if self._in_tree ~= parent._in_tree then
      self:_set_in_tree(parent._in_tree)
    end
  else
    self.parent = nil
    self:_set_in_tree(false)
  end
end

function Entity:_set_in_tree(in_tree)
  self._in_tree = in_tree
  for _, child in pairs(self.children) do child:_set_in_tree(in_tree) end
end

function Entity:reparent(new_parent)
  self.ecs:move_entity(self, new_parent)
end

function Entity:add_child(child)
  self.ecs:move_entity(child, self)
end
Entity.add = Entity.add_child -- alias for backwards compatibility

function Entity:remove_child(child)
  self.ecs:move_entity(child, nil)
end

function Entity:destroy()
  -- sever this subtree at just this node,
  -- and then mark every entity+component as dead
  self:reparent(nil)
  self:call_recursive("_mark_dead")
end

function Entity:_mark_dead()
  self._dead = true
  for _, comp in pairs(self._components) do
    comp._dead = true
    if comp.destroy then comp:destroy() end
  end
end

-- call a function on this node and its descendents
function Entity:call_recursive(func_name, ...)
  if self[func_name] then self[func_name](self, ...) end
  for _, child in pairs(self.children) do
    child:call_recursive(func_name, ...)
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
    log.warning(self:error_name() .. "tried to remove component ["
                .. component_name .. "] that doesn't exist.")
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

-- send an event to this entity and all its descendents
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
