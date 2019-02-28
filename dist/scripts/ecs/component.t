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

function Component:mount(compname)
  self.mounted_name = compname
end

function Component:unmount()
  self.ecs = nil
  self.ent = nil
end

function Component:add_to_systems(syslist)
  self._systems = self._systems or {}
  local ecs_systems = self.ecs.systems
  for _, sysname in ipairs(syslist) do
    self._systems[sysname] = ecs_systems[sysname]
  end
end

function Component:wake()
  if not self._systems then return end
  for _, sys in pairs(self._systems) do
    sys:register_component(self)
  end
end

function Component:sleep()
  if not self._systems then return end
  for _, sys in pairs(self._systems) do
    sys:unregister_component(self)
  end
end

function Component:destroy()
  self._dead = true
end

local UpdateComponent = Component:extend("UpdateComponent")
m.UpdateComponent = UpdateComponent
function UpdateComponent:init(f)
  self.update = f
end

function UpdateComponent:mount()
  self:add_to_systems({"update"})
  self:wake()
end

function UpdateComponent:update()
  -- either override this, or pass in f
end

return m
