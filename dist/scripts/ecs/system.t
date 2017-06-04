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
  setmetatable(self._components, { __mode = 'v' })
end

function System:register_component(component, callback)
  if not callback then
    callback = function(evtname, ...)
      component[evtname](...)
    end
  end
  self._components[component] = callback
end

function System:unregister_component(component)
  self._components[component] = nil
end

function System:emit(evtname, ...)
  for owner, callback in pairs(self._components) do
    if owner._dead then
      self._components[owner] = nil
    elseif owner.ent._in_tree ~= false then
      callback(evtname, ...)
    end
  end
end

function GenericSystem:update()
  if self._evtname then self:emit(self._evtname) end
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
