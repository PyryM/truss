-- ecs documentation

module{"ecs"}
description[[
An 'entity component system' framework. Note that because of the way that
Lua memory allocation and management work, a 'true' ECS in which components
are kept in contiguous memory is not possible. This is perhaps better thought
of as a 'loosely coupled component' framework.
]]

sourcefile{"ecs.t"}
description[[
Defines the ecs root object.
]]

classdef 'ECS'
description[[
The ECS root object.
]]

classfunc 'init'
description[[
Create a new ECS root.
]]

classfunc 'create'
args{callable 'constructor', varargs 'args'}
returns{object['Entity'] 'constructed_entity'}
description[[
Create an entity in this ECS root. The argument `constructor`
is called as `constructor(ecs_root, ...)`, and so can either
be a class prototype directly, or a function.
]]

classfunc 'add_system'
args{object['System'] 'system', string 'name'}
returns{object['System'] 'system'}
description[[
Add a system to this ECS root. The system will be
visible as `self.systems[name]`.
]]

classfunc 'update'
description[[
Update this ECS root, calling in turn `:update()` on every system.
]]

classfunc 'insert_timing_event'
args{string 'event_type', any 'event_info'}
description[[
Insert an event into the frame timing.
]]

sourcefile{"entity.t"}
description[[
Entities hold components and can be arranged into a tree.
]]

func 'promote'
args {string 'name', class 'component', class 'parent'}
returns {class 'promoted_component'}
description[[
Promote a component class into an Entity subclass.
]]
example[[
local ColorComp = ecs.Component:extend("ColorComp")
function ColorComp:init(r, g, b)
  self.mount_name = "color"
  self:set_color(r, g, b)
end
function ColorComp:set_color(r, g, b)
  self._internal_color = {r or 255, g or 255, b or 255}
end
local ColorEntity = ecs.promote("ColorEntity", ColorComp, ecs.Entity3d)

-- this is a bit inconvenient
local ent = some_ecs:create(ecs.Entity3d, "blargh", ColorComp(128,128,255))
ent.color:set_color(0, 0, 0)

-- slightly better
local ent = some_ecs:create(ColorEntity, "blargh", 128, 128, 255)
ent:set_color(0, 0, 0)

-- note that promote only redirects *functions*
print(tostring(ent._internal_color)) -- prints 'nil'
]]

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
Components are attached to entities and do most of the 'work'.
]]

classdef{'Component'}
description[[
`Component` is the base class for components, although components do
not actually need to inherit from it as long as they implement the same
functions.
]]

classfunc 'mount'
args {string 'name'}
description[[
This function is called by an entity when a component is added to it,
with the name it is mounted as (e.g., if the mount name is 'mesh', then
the component will be exposed as `ent.mesh`).
]]

classfunc 'unmount'
description[[
This function is called by an entity when a component is removed.
]]

classfunc 'sleep'
description[[
Put this component to sleep. The default implementation unregisters
this component from every system in its `._systems` list.
]]

classfunc 'wake'
description[[
Wake this component. The default implementation registers this component
with every system in its `._systems` list.
]]

classfunc 'destroy'
description[[
Destroy this component.
]]

classfunc 'add_to_systems'
args{list 'systems'}
description[[
Populate the `._systems` list of this component; the argument `systems`
should be a list of string system names.

This function is not part of the interface of component, and is provided
mainly as a convenience for subclasses.
]]
example[[
function UpdateComponent:mount()
  self:add_to_systems({"update"})
  -- add_to_systems doesn't actually register the comp into 'update' yet,
  -- so we need to wake as well
  self:wake() 
end
]]

classdef 'UpdateComponent'
description[[
A component that will have its `:update()` function called automatically
every frame. This is a useful class to derive from.
]]
example[[
local RotatorComp = ecs.UpdateComponent:extend("RotatorComp")
function RotatorComp:update()
  self.frame = (self.frame or 0) + 1
  self.ent.quaternion:euler{x = 0, y = self.frame / 60.0, z = 0}
  self.ent:update_matrix()
end
]]

classfunc 'update'
description[[
This function will be called every frame; by default it is a stub function
that does nothing, so it is safe to override without calling `super.update`.
]]

sourcefile{"system.t"}
description[[
Systems are responsible for actually updating components.
]]

classdef 'System'
description[[
The base class for systems, although it is not necessary to actually derive
from this class so long as `register_component`, `unregister_component`,
and `update` are implemented.
]]

classfunc 'init'
args{string 'mount_name', string 'func_name: function to be called on components'}
description[[
Create a system that will be available under `ECS.systems[mount_name]`. If
`func_name` is provided, then every frame (every call to `:update()`) the system
will call `component[func_name]` on every registered component.
]]
example[[
local update_system = ECS:add_system(ecs.System("update", "update"))
]]

classfunc 'register_component'
args{object['Component'] 'component'}
description[[
Register a component onto the system. To avoid memory leaks, the
system should only keep a *weak reference* to the component.
]]

classfunc 'unregister_component'
args{object['Component'] 'component'}
description[[
Unregister a component from the system.
]]

classfunc 'update'
description[[
Update the system; called every frame by the ECS root. Typically this
should then update every component registered onto the system. The default
implementation calls the function name specified at construction on every
registered component.
]]

classfunc 'num_components'
returns{int 'component_count'}
description[[
Returns the number of components registered with this system. Not part
of the interface.
]]

classfunc 'call_on_components'
args{string 'func_name', varargs 'func_arguments'}
description[[
Call `component[func_name](component, ...)` on every registered
component. Not part of the interface.
]]

sourcefile{"event.t"}
description[[
Events.
]]

classdef 'EventEmitter'
description[[
A class that manages events and event callbacks.
]]

classfunc 'init'
description[[
Create an EventEmitter.
]]

classfunc 'emit'
args{string 'event_name', any 'event'}
description[[
Emit an event-- any callbacks registered under `event_name` will
be called as `callback(receiver, event_name, event)`.
]]

classfunc 'on'
args{string 'event_name', any 'receiver', callable 'callback'}
description[[
Register an event callback for `event_name`. The lifetime of the
callback is the lifetime of `receiver`: i.e., when `receiver` is
garbage collected, the callback is likewise removed, and this
emitter only keeps a weak reference to `receiver`.

The typical way to use this is to have `receiver` be a class instance,
and `callback` be a function on that class.

Note that any given receiver can only be used once for a given named
event: calling `:on` with the same event name and receiver multiple times
will result in the later `callbacks` replacing the previous ones.

A callback can be manually removed by calling `on` with the receiver
and `false` as the callback (or with `:remove`).
]]
example[[
local my_instance = {
  x = 0, y = 0,
  mouse_down = function(self, evt_name, evt)
    self.x, self.y = evt.x, evt.y
    print(evt.x, evt.y)
  end
}
-- Note that using my_instance as a receiver will not stop it from
-- being garbage collected: if we want this callback to continue to live,
-- we need to keep a reference to my_instance around somewhere
some_emitter:on("mouse_down", my_instance, my_instance.mouse_down)

-- we can manually remove the callback like so
some_emitter:on("mouse_down", my_instance, false)
-- or equivalently
some_emitter:remove("mouse_down", my_instance)
]]

classfunc 'remove'
args{string 'event_name', any 'receiver'}
description[[
Remove an event handler, keyed on the event name and the receiver object.
]]

classfunc 'remove_all'
args{any 'receiver'}
description[[
Remove all event handlers associated with a given receiver.
]]