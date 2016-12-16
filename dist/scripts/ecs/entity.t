-- ecs/entity.t
--
-- the base entity for the entity component system

local class = require("class")
local sg = require("scenegraph/scenegraph.t")
local m = {}

local Entity = class("Entity")
m.Entity = Entity
Entity:with(sg.ScenegraphMixin)
function Entity:init(name)
    self._components = {}
    self:sg_init()
    if name then self.name = name end
end

-- return a string identifying this component for error messages
function Entity:error_name(funcname)
    return "Entity[" .. (self.name or "?") .. "]: "
end

-- throw an error with convenient formatting
function Entity:error(error_message)
    truss.error(self:error_name() .. error_message)
end

-- add a component *instance* to an entity
-- the name must be unique, and cannot be any of the keys in the entity
function Entity:add_component(component, component_name)
    component_name = component_name or component.mount_name
    if self[component_name] then
        self:error("[" .. component_name .. "] is already key in entity!")
    end

    if self._components[component_name] then
        self:error("[" .. component_name .. "] is already in entity!")
    end

    self._components[component_name] = component
    self[component_name] = component
    component:mount(self, component_name)
end

-- remove a component by its mounted name
function Entity:remove_component(component_name)
    local comp = self._components[component_name]
    if not comp then
        log.warning(self:error_name .. "tried to remove component ["
                    .. component_name .. "] that doesn't exist.")
        return
    end
    self._components[component_name] = nil
    self[component_name] = nil
    comp:unmount(self)
end

return m
