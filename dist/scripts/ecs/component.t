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

function Component:mount(entity)
  self._entity = entity
  entity:_auto_add_handlers(self)
end

function Component:unmount()
  if self._entity then self._entity:_remove_handlers(self) end
  self._entity = nil
end

return m
