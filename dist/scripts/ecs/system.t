-- ecs/system.t
--
-- a base system class which just emits events

local class = require("class")
local m = {}

local System = class("System")
m.System = System

function System:init(mount_name, funcname)
  self._components = {}
  self.mount_name = mount_name
  self.funcname = funcname or self.mount_name
  setmetatable(self._components, { __mode = 'k' })
end

function System:register_component(component)
  if not self._added_components then self._added_components = {} end
  if self._iterating then
    self._added_components[component] = true
  else
    self._components[component] = true
  end
end

function System:num_components()
  local n = 0
  for _, comp in pairs(self._components) do n = n + 1 end
  return n
end

function System:unregister_component(component)
  self._components[component] = nil
end

function System:call_on_components(funcname, ...)
  -- adding a key to a table while iterating it with pairs() is undefined
  -- so if a component is registered during this call, it gets added to a
  -- temporary table which we then merge after the main iteration
  self._iterating = true
  for comp, _ in pairs(self._components) do
    if comp._dead then
      self._components[comp] = nil
    else
      -- e.g., if funcname = "update" call comp:update(...)
      comp[funcname](comp, ...)
    end
  end
  -- merge in any components registered during iteration
  if self._added_components then
    for comp, _ in pairs(self._added_components) do
      self._components[comp] = true
    end
    self._added_components = nil
  end
  self._iterating = false
end

function System:update()
  if self.funcname then self:call_on_components(self.funcname) end
end

return m
