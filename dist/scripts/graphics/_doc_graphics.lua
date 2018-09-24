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

sourcefile 'camera.t'

classdef 'CameraComponent'
description[[
A {{RenderComponent}} which represents a camera, to be used in 
conjunction with {{CameraControlOp}} or {{MultiCameraOp}}. 
Mounts onto an entity as `.camera`.
]]

classfunc 'init'
table_args {
  tag = string{'identifying tag', default = 'primary'},
  orthographic = bool{'whether this is an orthographic camera', default = false},
  left = number{'left bound (orthographic)', default = -1.0},
  right = number{'right bound (orthographic)', default = 1.0},
  top = number{'top bound (orthographic)', default = 1.0},
  bottom = number{'bottom bound (orthographic)', default = -1.0},
  near = number{'near clip plane distance', default = 0.01},
  far = number{'far clip plane distance', default = 30.0},
  fov = number{'vertical field of view in degrees (perspective)', default = 70.0},
  aspect = number{'aspect ratio w/h (perspective)', default = 1.0}
}
description[[
Create a camera component as either a perspective (default) or orthographic
camera. The camera will be matched to {{CameraControlOp}}s by the 
specified `tag`.
]]
example[[
pipeline:add_stage(graphics.Stage{
  render_ops = {graphics.DrawOp(), graphics.CameraControlOp()}
})
pipeline:add_stage(graphics.Stage{
  render_target = some_secondary_render_target,
  render_ops = {graphics.DrawOp(), graphics.CameraControlOp("secondary")}
})
some_entity:add_component(graphics.CameraComponent{})
some_entity:add_component(graphics.CameraComponent{tag = 'secondary'})
]]

classfunc 'make_projection'
args{number 'fov: vertical fov in degrees', number 'aspect: w/h', number 'near', number 'far'}
returns{self}
description[[
Change this camera into a perspective projection.
]]

classfunc 'make_orthographic'
args{number 'left', number 'right', number 'bottom', number 'top', number 'near', number 'far'}
returns{self}
description[[
Change this camera into an orthographic projection.
]]

classfunc 'set_projection'
args{object['math.Matrix4'] 'projection_matrix'}
returns{self}
description[[
Directly set the projection matrix. The provided argument is copied.
]]

classfunc 'get_matrices'
returns{object['math.Matrix4'] 'view_matrix', object['math.Matrix4'] 'projection_matrix'}
description[[
Get the view and projection matrices for this camera. The returned matrices
are the internal matrices directly and shouldn't be modified.
]]

classfunc 'get_view_proj_mat'
args{object['math.Matrix4'] 'target: optional target to copy the result into'}
returns{object['math.Matrix4'] 'view_proj_matrix'}
description[[
Return the combined 'view-projection matrix', i.e., proj*view. If `target`
is provided, the result will be directly computed into `target`, otherwise
an internal matrix will be returned.
]]

classfunc 'unproject'
args{number 'ndc_x', number 'ndc_y', bool 'local_frame', object['math.Vector'] 'origin', object['math.Vector'] 'direction'}
returns{object['math.Vector'] 'origin', object['math.Vector'] 'direction'}
description[[
"Unproject" an image coordinate (in normalized device coordinates, i.e., in range -1 to 1)
to a ray, in either local or world coordinates depending on `local_frame`.
If `origin` and `direction` are provided, they will be modified to hold the
result, otherwise new vectors will be returned.
]]

classdef 'CameraControlOp'
description[[
A {{RenderOperation}} that updates a Stage's view and projection matrices
according to a {{CameraComponent}}.
]]

classfunc 'init'
args{string 'tag'}
description[[
Create a CameraControlOp. The sole argument is the camera 'tag' which is
used to identify which {{CameraComponent}} will be tracked. If no tag
is given, it will default to "primary".
]]

classdef 'MultiCameraOp'
description[[
A {{RenderOperation}} that updates view and projection matrices for
multiple views within a MultiviewStage. Cameras are matched to views
according to their camera tags and the view names.
]]

classfunc 'init'
description[[
Create a MultiCameraOp. Takes no arguments because cameras are matched
to views by their names.
]]
example[[
pipeline:add_stage(graphics.MultiviewStage{
  render_ops = {graphics.MultiDrawOp(), graphics.MultiCameraOp()},
  views = {
    {name = "left_bob", viewport = left_viewport}, 
    {name = "right_alice", viewport = right_viewport}
  }
})
-- note how the view names "left_bob" and "right_alice" above 
-- correspond to the camera tags below
local left_camera = scene:create_child(graphics.Camera, "blargh",
                                      {tag = "left_bob"})
local right_camera = scene:create_child(graphics.Camera, "foo",
                                        {tag = "right_alice"})
]]

classdef 'Camera'
description[[
This is a {{ecs.promote}}'d version of CameraComponent.
]]
example[[
local camera = scene:create_child(graphics.Camera, "primary_camera", {
  fov = 85.0,
  aspect = gfx.backbuffer_width / gfx.backbuffer_height
})
]]

func 'CubeCamera'
table_args {
  near = number 'near clip plane',
  far = number 'far clip plane',
  name = string{'prefix for camera names', default = 'face'},
  tag = string{'prefix for camera tags', default = 'cube'}
}
description[[
A constructor function that is used to create six cameras, each viewing
one 90 degree cube face. The cameras will have tags like "cube_nx" for
each of the six face ids "nx", "px", "ny", "py", "nz", "pz". The face/camera
"nx" is oriented to look in the negative x direction, for example.

For a complete example, see {{file:scripts/examples/cuberender.t}}.
]]
example[[
pipeline:add_stage(graphics.MultiviewStage{
  render_ops = {graphics.MultiDrawOp(), graphics.MultiCameraOp()},
  views = {
    {name = "cube_px", render_target = face_targets.px}, 
    {name = "cube_nx", render_target = face_targets.nx},
    {name = "cube_py", render_target = face_targets.py},
    {name = "cube_ny", render_target = face_targets.ny},
    {name = "cube_pz", render_target = face_targets.pz},
    {name = "cube_nz", render_target = face_targets.nz}
  }
})
local cubecam = scene:create_child(graphics.CubeCamera, "cube_cam", {
  near = 0.01, far = 30.0
})
]]