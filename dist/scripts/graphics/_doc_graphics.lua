-- graphics documentation

module 'graphics'
description[[
The graphics module contains higher-level graphics representations.
]]

sourcefile 'pipeline.t'

classdef 'Pipeline'
description[[
Represents an ordered series of stages, each of which may
submit drawcalls into a render target.
]]

classfunc 'init'
table_args{
  verbose = bool{'whether to log debug information', default = false},
  globals = object['gfx.CompiledGlobals'] 'global uniforms'
}
description[[
Create a new pipeline.
]]

classfunc 'match'
args{object['gfx.TagSet'] 'tags', list 'target'}
returns{list 'renderops'}
description[[
Query the pipeline for renderops that apply to a given set of tags.
If a `target` list is provided, the renderops will be appended into it, 
otherwise a new list will be created and returned.
]]

classfunc 'match_scene'
args{string 'scene_name', list 'target'}
returns{object 'matcher'}
description[[
Query the pipeline for stages that apply to a given scene. Passing
in nil is the same as passing "default". The object returned is a 
normal list (table with sequential natural number keys),
with the addition of the function `:match(tags)` that can be used to 
then further match on tags.
]]
example[[
local stages = pipeline:match_scene("extra_scene")
for idx, stage in ipairs(stages) do
  -- this is allowed
end
-- we can also further refine down to renderops on tags
local renderops = stages:match(gfx.TagSet{transparent = true})
]]

classfunc 'pre_render'
description[[
Called before main rendering, simply calls `:pre_render` on each stage.
]]

classfunc 'post_render'
description[[
Called after main rendering, simply calls `:post_render` on each stage.
]]

classfunc 'bind'
args{int{'start_view_id', default = 0}, int{'view_count', default = 255}}
description[[
Bind the stages in this pipeline to bgfx view ids.
]]

classfunc 'add_stage'
args{object['graphics.Stage'] 'stage', string 'stage_name'}
description[[
Add a stage to this pipeline. If `stage_name` is given, then the 
stage will be visible under `pipeline.stages[stage_name]`.
]]

classdef 'SubPipeline'
description[[
A stage which can recursively hold another pipeline.
]]

classfunc 'init'
table_args{
  num_views = int{'number of view ids to reserver', default = 10},
  filter = callable 'filter function',
  stage_name = string{'stage name', default = 'SubPipeline'},
  enabled = bool{'whether the stage is initially enabled', default = true},
  globals = object['gfx.CompiledGlobals'] 'global uniforms',
  scene = string{'scene name', default = 'nil/"default"'},
  pipeline = object['graphics.Pipeline'] 'sub pipeline'
}
description[[
Create a SubPipeline. Shares the interface of {{graphics.Stage}}.
]]

classfunc 'set_pipeline'
args{object['graphics.Pipeline'] 'pipeline'}
description[[
Set the sub-pipeline bound into this stage. If the pipeline requires more
views that the `num_views` this was created with, an error will be thrown.
]]

sourcefile 'stage.t'

classdef 'Stage'
description[[
Base class for pipeline stages, although stages are not required to
inherit from this class as long as they implement `bind`, `num_views`,
and `match`. A stage that optionally implements `pre_render` or 
`post_render` will have those called at the appropriate times.
]]

classfunc 'init'
table_args {
  render_ops = list 'render ops',
  filter = callable 'function to filter tags on',
  globals = object['gfx.CompiledGlobals'] 'global uniforms',
  exclusive = bool{'if true, match at most one renderop to a tagset', default=false},
  stage_name = string 'stage name',
  always_clear = bool{'if true, clear the rendertarget even if no draw calls', default = false},
  view = table{'a gfx.View or a table of view options'},
  scene = string{'the scene this stage is associated with', default = 'nil/"default"'}
}
description[[
Create a new stage. If the `view` option is unspecified, then the entire
options table is passed into the `gfx.View` constructor.
]]
example[[
-- the base Stage can be used to create typical forward rendering stages
pipeline:add_stage(graphics.Stage{
  name = "forward",
  always_clear = true,
  -- 'clear' is a gfx.View option, and not a Stage option as such,
  -- but since we didn't specify a view, this entire options table is
  -- passed into the gfx.View constructor
  clear = {color = 0x000000ff, depth = 1.0},
  -- we let this stage share a reference to the pipeline's globals
  globals = pipeline.globals,
  render_ops = {graphics.DrawOp(), graphics.CameraControlOp()}
})
]]

classfunc 'num_views'
returns{int 'view_count'}
description[[
Returns how many views this Stage requires. The base class Stage
always returns 1, but derived classes can override it as needed.
]]

classfunc 'bind'
args{int 'start_view_id', int 'view_count'}
description[[
Bind this stage to one or more bgfx view ids. The base class Stage
binds its single View to the start id, but derived classes can
override it as needed.
]]

classfunc 'match'
args{object['gfx.TagSet'] 'tags', list 'target'}
returns{list 'renderops'}
description[[
Return renderops in this stage that apply to a given tagset. If
`target` is provided, the renderops will be appended to it, otherwise,
a new list of the renderops should be returned.

The base class `Stage:match` first checks if `self.filter(tags)` is true,
and if so, then checks each renderop if `op:matches(tags)`. If `self.filter`
is nil, then only the renderop check is performed.
]]

classfunc 'add_render_op'
args{any 'renderop'}
description[[
Add a renderop to this stage after creation.
]]

classfunc 'pre_render'
description[[
Called before main rendering. The base class implementation will apply
view clears if the `always_clear` option was set to true.
]]

classfunc 'post_render'
description[[
Called after main rendering.
Not implemented by the base class.
]]

sourcefile 'renderop.t'
description[[
A render operation is an encapsulated operation that might be applied to
a render-relevant {{graphics.Component}}. For example, a typical 'draw call'
is one kind of render operation (that applies to e.g. {{graphics.Mesh}}),
and updating a View's view+projection matrices from a Camera is another
render operation.

A render operation needs only to implement a single function: `matches(tags)`.
This function should return either `nil` if the render operation doesn't
apply to the tags, or a function `f(component, transform)` that will apply
the render operation to a given component and world transform.

A render operation can optionally implement `bind_stage(stage)` which will
be called when the render operation is added to a stage.

Render operations should not be shared across stages: each stage should get
its own render operation instances.
]]

classdef 'RenderOperation'
description[[
This base class provides a couple of convenient functions for renderops.
]]

classdef 'DrawOp'
description[[
A generic renderop that submits a drawcall.
]]

classfunc 'init'
table_args{
  filter = callable 'filter function'
}
description[[
Create a DrawOp. You can optionally specify an additional filter.
]]

classdef 'MultiDrawOp'
description[[
A renderop that will efficiently submit drawcalls into multiple views
(i.e., in a {{graphics.MultiviewStage}}). 
]]

classfunc 'init'
table_args{
  filter = callable 'filter function'
}
description[[
Create a MultiDrawOp. You can optionally specify an additional filter.
]]

sourcefile 'renderer.t'

classdef 'RenderSystem'
description[[
An ECS system that submits rendering to bgfx (through gfx).
]]

classfunc 'init'
table_args {
  auto_frame_advance = bool{'automatically submit bgfx frames', default = true},
  roots = table 'scene root entities'
}
description[[
Create a new RenderSystem. Ideally, `roots` should provide at least
a "default" scene root. If no "default" root is provided, then it
will be set as ECS.scene, but this behavior is likely to change.
]]

classfunc 'set_scene_root'
args{string 'scene', object['ecs.Entity3d'] 'root'}
description[[
Set the root entity for a given scene. A scene can be removed by
setting the root entity to 'nil'.
]]

classfunc 'set_pipeline'
args{object['graphics.Pipeline'] 'pipeline'}
description[[
Set the pipeline used by the renderer.
]]

classdef 'RenderComponent'
description[[
Base class for components that should interact with the render system.
The requirements for render components is that they should
have a `.tags` field, and that they should set their entity's `.renderable`
field to themselves.
]]

classdef 'MeshComponent'
description[[
A component representing a typical mesh, which has a geometry
({{gfx.StaticGeometry}} or {{gfx.DynamicGeometry}}) and a material
({{gfx.BaseMaterial}}).
]]

classfunc 'init'
args{object['gfx.Geometry'] 'geometry', object['gfx.BaseMaterial'] 'material'}
description[[
Create a component that will render a mesh.
]]

classfunc 'set_geometry'
args{object['gfx.Geometry'] 'geometry'}
description[[
Set the geometry of this mesh. Can cause a recompilation.
]]

classdef 'set_material'
args{object['gfx.BaseMaterial'] 'material'}
description[[
Set the material of this mesh. Can cause a recompilation.
]]

classdef 'DummyMeshComponent'
description[[
Like a `MeshComponent`, but does not actually draw. This is mainly
useful if you are building a scenegraph that will be merged into a 
single geometry and want to avoid allocating actual GPU resources.
]]

classfunc 'init'
args{object['gfx.Geometry'] 'geometry', object['gfx.BaseMaterial'] 'material'}
description[[
Create a component that holds a geometry and a material but does not 
actually compile a drawcall or draw anything.
]]

classdef 'Mesh'
description[[
The {{ecs.promote}}'ed version of `MeshComponent`.
]]
example[[
local mesh = scene_root:create_child(graphics.Mesh, "bla", geo, mat)
]]

classdef 'DummyMesh'
description[[
The {{ecs.promote}}'ed version of `DummyMeshComponent`.
]]