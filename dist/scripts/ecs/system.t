-- ecs/system.t
--
-- a base system class which just emits events

local class = require("class")
local m = {}

local System = class("System")
m.System = System

function System:init(mount_name, evtname, priority)
  self._components = {}
  self.stages = {}
  self.mount_name = mount_name
  if evtname then
    self.stages["update"] = priority or 1
    self._evtname = evtname
  end
  setmetatable(self._components, { __mode = 'k' })
end

function System:register_component(component)
  if self._iterating then
    self._added_components[component] = true
  else
    self._components[component] = true
  end
end

function System:unregister_component(component)
  self._components[component] = nil
end

function System:call_on_components(funcname, ...)
  -- adding a key to a table while iterating it with pairs() is undefined
  -- so if a component is registered during this call, it gets added to a
  -- temporary table which we then merge after the main iteration
  self._iterating = true
  self._added_components = {}
  for comp, _ in pairs(self._components) do
    if comp._dead then
      self._components[comp] = nil
    else
      -- e.g., if funcname = "update" call comp:update(...)
      comp[funcname](comp, ...)
    end
  end
  -- merge in any components registered during iteration
  for comp, _ in pairs(self._added_components) do
    self._components[comp] = true
  end
  self._iterating = false
  self._added_components = nil
end

function System:update()
  if self.funcname then self:call_on_components(self.funcname) end
end

local ScenegraphSystem = class("ScenegraphSystem")
m.ScenegraphSystem = ScenegraphSystem

function ScenegraphSystem:init()
  self._identity_mat = require("math").Matrix4():identity()
end

function ScenegraphSystem:update(ecs)
  if ecs.scene then ecs.scene:recursive_update_world_mat(self._identity_mat) end
end

return m
