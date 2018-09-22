-- ecs documentation

module{"ecs"}
description[[
An 'entity component system' framework. Note that because of the way that
Lua memory allocation and management work, a 'true' ECS in which components
are kept in contiguous memory is not possible. This is perhaps better thought
of as a 'loosely coupled component' framework.
]]

sourcefile{"entity.t"}
description[[
Entities hold components and can be arranged into a tree.
]]

-- func 'promote'
-- args {string 'name', class 'component', class 'parent'}
-- returns {class 'promoted_component'}
-- description[[
-- Promote a component class into an Entity subclass.
-- ]]
-- example[[
-- local ColorComp = ecs.Component:extend("ColorComp")
-- function ColorComp:init(r, g, b)
--   self.mount_name = "color"
--   self:set_color(r, g, b)
-- end
-- function ColorComp:set_color(r, g, b)
--   self._internal_color = {r or 255, g or 255, b or 255}
-- end
-- local ColorEntity = ecs.promote("ColorEntity", ColorComp, ecs.Entity3d)

-- -- this is a bit inconvenient
-- local ent = some_ecs:create(ecs.Entity3d, "blargh", ColorComp(128,128,255))
-- ent.color:set_color(0, 0, 0)

-- -- slightly better
-- local ent = some_ecs:create(ColorEntity, "blargh", 128, 128, 255)
-- ent:set_color(0, 0, 0)

-- -- note that promote only redirects *functions*
-- print(tostring(ent._internal_color)) -- prints 'nil'
-- ]]

classdef 'Entity'
description[[
An Entity that does not have a spatial transformation associated with it.
]]

classfunc 'init'
args {
  object 'ecs: the ECS instance in which to create this entity',
  string 'name: the name of this entity (does not have to be unique)',
  varargs 'components: any components to add'
}
returns {self}
description[[
Create an Entity. Note that Entities must be created within an ECS instance
by passing in the instance. Typically, Entities should not be directly
created, but instead `ecs.create()` or `Entity:create_child()` should be used.
]]

classfunc 'create'
args {
  callable 'constructor: class or function that constructs an Entity',
  varargs 'args: additional args to pass to constructor (typically name)'
}
returns {object['Entity'] 'new_entity'}
description[[
Create a new Entity in the same ECS as this Entity. This is just sugar
for calling `entity.ecs:create(...)`. An entity created this way will
have no parent (is not part of any entity tree).
]]

classfunc 'create_child'
args {
  callable 'constructor: class or function that constructs an Entity',
  varargs 'args: additional args to pass to constructor (typically name)'
}
returns {object['Entity'] 'new_entity'}
description[[
Create a new entity as a child of this Entity.
]]
example[[
-- assume root is an Entity
local child = root:create_child(ecs.Entity, "Entity_Named_Alex")

-- we can pass a constructor function too
local function make_color_entity(_ecs, name, r, g, b)
  local ret = ecs.Entity(_ecs, name)
  -- assuming 'ColorComponent' is a thing
  ret:add_component(ColorComponent(r, g, b)) 
  return ret
end
local child = root:create_child(make_color_entity, "Blue", 0, 0, 255)
]]

classfunc 'log_name'
returns {string 'friendly_name'}
description[[
Return a nicely formatted string identifying this entity for log/error
messages. Note that `tostring(entity)` redirects to this.
]]

classfunc 'error'
args {string 'message'}
description[[
Throw an error from this Entity. Right now this just prepends the entity's
`:log_name()` to the error message.
]]

classfunc 'warning'
args {string 'message'}
description[[
Log a warning from this Entity.
]]

classfunc 'is_in_subtree'
args {object['Entity'] 'query_parent'}
returns{bool 'in_parent'}
description[[
Test whether this Entity is in the subtree rooted at `query_parent`.
An Entity is considered to be in its own subtree.
]]

classfunc 'set_parent'
args {object['Entity'] 'new_parent'}
description[[
Reparent this entity. If the reparenting would create a cycle
(i.e., if `new_parent:is_in_subtree(child)`),
an error is thrown. The `new_parent` can be `nil` in which case
the entity simply has no parent.
]]

classfunc 'detach'
description[[
Sugar for `entity:set_parent(nil)`.
]]

classfunc 'add_child'
args {object['Entity'] 'new_child'}
returns {object['Entity'] 'child'}
description[[
Add a child to this entity. Note that this is sugar for
`child:set_parent(parent)`.
]]

classfunc 'remove_child'
args {object['Entity'] 'child'}
returns {object['Entity'] 'child'}
description[[
Remove a child from this entity. Note that this is sugar for
`child:set_parent(nil)`, except that this will throw an error
if `child` is not actually a direct child of this entity.
]]

classfunc 'destroy'
args {bool 'recursive'}
description[[
Remove this entity from any trees and `:destroy()` all its
components. If `recursive` is specified, all its descendents
are likewise destroyed, otherwise they are left in a kind of
limbo, rooted to a dead parent until moved.

Lua garbage collection *does* work as normal on Entities:
simply discarding all references to an Entity (including removing
it from its parent) will eventually
cause it and all its components to be garbage collected. However,
Lua makes no guarantees about *when* the garbage collector will run,
and in the meantime the components on such an implicitly-destroyed
entity will continue to be updated.

Explicitly calling `:destroy()` will immediately remove an entity's
components from their systems.
]]

classfunc 'destroy_components'
description[[
Remove all this entity's components and call `:destroy()` on any
that support it.
]]

classfunc 'sleep'
args {bool 'recursive'}
description[[
Put this entity to sleep, temporarily pausing all its components from
being updated by their respective systems. If `recursive` is true, then
the entire tree rooted at this entity is put to sleep.
]]

classfunc 'wake'
args {bool 'recursive'}
description[[
Wake this entity, restoring its components to being updated. 
If `recursive` is true, then
the entire tree rooted at this entity is woken.
]]

classfunc 'call_recursive'
args {string 'function_name', varargs 'args'}
description[[
Call `entity[function_name](args)` on this entity and all its
descendents.
]]

classfunc 'traverse'
args {callable 'func'}
description[[
Invoke `func` on this entity and all its descendents. Basically
like map except onto the tree rooted at this entity.
]]

classfunc 'iter_tree'
returns{iterator 'iter'}
description[[
An iterator over the entities in the tree rooted at this entity, including
this entity.
]]
example[[
for entity in some_entity:iter_tree() do
  print("Entity: " .. tostring(entity))
end
]]

classfunc 'find'
args {any 'condition'}
returns {object['Entity'] 'entity'}
description[[
Find an entity in this tree that satisfies `condition`. If `condition`
is a string, then returns an entity with that name. Otherwise, `condition`
must be a function, and an entity where `condition(ent) == true` is returned.
Returns `nil` if no entity is found.
]]

classfunc 'add_component'
args {object['Component'] 'component', string 'name'}
returns {object['Component'] 'component'}
description[[
Add a component to this entity. Note that the component must actually
be instantiated; i.e., do not pass the component *constructor*. The
component is afterwards available on the entity as a field with
`name`, or `component.mount_name` if no name was specified.
]]
example[[
local mymesh = some_entity:add_component(graphics.Mesh("mesh", geo, mat))
-- now also available as some_entity.mesh
]]

classfunc 'remove_component'
args {string 'component_name'}
description[[
Remove a component from this entity by its mount name.
]]

classfunc 'emit'
args {string 'event_name', any 'event'}
description[[
Emit an event from this entity.
]]

classfunc 'on'
args {string 'event_name', any 'receiver', callable 'callback'}
description[[
Add an event listener onto this entity that will be called when
`emit` is invoked. See `ecs/event.t` for more details on the event system.
]]

classdef 'Entity3d'
fields{
  position = object['math.Vector'] 'translation',
  scale = object['math.Vector'] 'scale',
  quaternion = object['math.Quaternion'] 'rotation',
  visible = bool 'whether this entity is visible',
  matrix = object['math.Matrix4'] 'combined transform relative to parent',
  matrix_world = object['math.Matrix4'] 'world transform relative to scene root'
}
description[[
An Entity that has a spatial transformation relative to its parent.
Inherits all the functions of `ecs.Entity`. 
]]

classfunc 'update_matrix'
description[[
Update `.matrix` by composing together `.position`, `.quaternion`, and `.scale`.
]]

classfunc 'recursive_update_world_mat'
args {object['math.Matrix4'] 'parent_transform'}
description[[
Recursively update `.matrix_world` for this entity and all its descendents.
Typically this is called by the rendering system on the registered scene 
roots.
]]

sourcefile{"component.t"}
description[[

]]

sourcefile{"system.t"}
description[[

]]

sourcefile{"event.t"}
description[[
  
]]