-- ecs/component.t
--
-- defines a basic component to inherit from

local class = require("class")
local m = {}

local Component = class("Component")
m.Component = Component

function Component:init()
  -- actually nothing to do
end

function Component:mount(compname, ecs)
  self.mounted_name = compname
  self.ecs = ecs
end

function Component:unmount()
  self.ecs = nil
  self.ent = nil
end

function Component:wake()
  if not self._system then
    if not self.system_name then
      truss.error("Components using default :wake() must "
                  .. "set self.system_name!")
      return
    end
    self._system = self.ent.ecs.systems[self.system_name]
  end
  self._system:register_component(self)
end

function Component:sleep()
  if self._system then
    self._system:unregister_component(self)
  end
end

function Component:destroy()
  self._dead = true
end

return m
