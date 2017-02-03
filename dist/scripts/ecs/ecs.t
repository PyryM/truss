-- ecs/ecs.t
--
-- the ecs root object

local class = require("class")
local entity = require("ecs/entity.t")
local math = require("math")

local m = {}

local ECS = class("ECS")
m.ECS = ECS
function ECS:init()
  self.systems = {}
  self.scene = entity.Entity3d("ROOT")
  self.scene._sg_root = self
  self._identity_mat = math.Matrix4():identity()
  self._configuration_dirty = false
end

function ECS:add_system(system, name)
  name = name or system.mount_name
  if self.systems[name] then truss.error("System name " .. name .. "taken!") end
  self.systems[name] = system
  self._configuration_dirty = true
  return system
end

function ECS:configure()
  self.scene:configure_recursive(self)
  self._configuration_dirty = false
  return self
end

function ECS:update()
  -- reconfigure if dirty
  if self._configuration_dirty then self:configure() end

  -- update systems first
  for _, system in pairs(self.systems) do
    system:update()
  end

  -- preupdate
  self.scene:event_recursive("on_preupdate")
  -- scenegraph transform update
  self.scene:recursive_update_world_mat(self._identity_mat)
  -- update
  self.scene:event_recursive("on_update")
end

return m
