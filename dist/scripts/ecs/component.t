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

function Component:mount(entity, mount_name, ecs)
  entity:_auto_add_handlers(self)
end

function Component:unmount()
  if self.ent then self.ent:_remove_handlers(self) end
  self.ent = nil
end

return m
