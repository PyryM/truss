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
  self._components[component] = true
end

function System:unregister_component(component)
  self._components[component] = nil
end

function System:call_on_components(funcname, ...)
  for comp, _ in pairs(self._components) do
    if comp._dead then
      self._components[comp] = nil
    else
      -- e.g., if funcname = "update" call comp:update(...)
      comp[funcname](comp, ...)
    end
  end
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
