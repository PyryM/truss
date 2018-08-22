-- gfx documentation

module{"gfx"}
description[[
Mid-level rendering primitives, effectively more lua-like versions of
what bgfx provides.
]]

sourcefile{"common.t"}
description[[General top-level gfx functions.]]

func 'init_gfx'
description[[
Initializes the graphics system. A window *must* have been created first.
]]
table_args{
  window = object 'must have `:get_window_size()`',
  width = number 'backbuffer width; required if window not specified',
  height = number 'backbuffer height; required if window not specified',
  backend = enum {'backend to use', options = {
    'noop', 'direct3d9', 'direct3d11', 'direct3d12', 'gnm', 'metal',
    'opengles', 'opengl', 'vulkan'
  }},
  lowlatency = bool{'set options for low-latency mode', default=false},
  msaa = bool{'enable msaa antialiasing', default=false},
  vsync = bool{'enable vsync', default=true},
  debugtext = bool{'draw debug text overlays', default=false},
}
returns{bool 'Success or failure'}

funcdef{"reset_gfx"}
description[[
Resets the graphics system (e.g., to resize the backbuffer on window size change).
See `init_gfx` for arguments.
]]

funcdef{"schedule"}
args{callable 'fn: function to call', number{'n_frames', optional = true}}
returns{number 'delay_frames: in how many frames the function will be called'}
description[[
  Schedules a function to be called after a specified number of frames. 
  If the number of frames isn't specified, 
  then it is scheduled for a 'safe' number of frames that depends on whether
  bgfx is running in single or multithreaded mode.
]]

funcdef{"create_state"}
description[[
Returns a state encoding the provided drawing options. These are largely the
bgfx state options verbatim.

Note that `depth_test` = false and `depth_test` = 'always' 
are functionally identical.

The bgfx macros to create more specialized blend modes have not been 
translated yet.
]]
table_args{
  rbg_write = bool{'write color to target', default = true},
  depth_write = bool{'write depth to target', default = true},
  alpha_write = bool{'write alpha to target', default = true},
  conservative_raster = bool{'conservative rasterization', default = false},
  msaa = bool{'use msaa (if enabled)', default = true},
  depth_test = enum{'depth test mode',
    options = {'less', 'lequal', 'equal', 'gequal', 'greater', 'notequal', 'never', 'always', false}, 
    default = "less"
  },
  cull = enum{'culling mode', options = {"cw", "ccw", false}, default ="cw"},
  blend = enum{'blend mode',
    options = {'add', 'alpha', 'darken', 'lighten', 'multiply', 'normal', 'screen', 'linear_burn', false},
    default = false
  },
  pt = enum{'primitive mode (false is triangles)', 
    options = {'tristrip', 'lines', 'linestrip', 'points', false},
    default = false
  }
}
returns{cdata['uint64'] 'state_flags'}

sourcefile{"vertexdefs.t"}
description[[
Create vertex type definitions.
]]

funcdef 'create_vertex_type'
args {dict 'attributes', list 'order'}
description[[
Create (or fetch a cached version) a vertex type. The argument
`attribute_table` should be a table of `attrib_name= options` attributes.
If provided, the `order` argument should be a list of attribute names in
the order that they should be present in the created vertex ctype; if
left unspecified, attributes will be sorted into a default order.
Attribute names are fixed by bgfx; see `gfx.ATTRIBUTE_INFO` for the
list of names.
Each attribute's options must specify a `ctype` (a terra
type) of either `float`, `uint8`, or `uint16` and a `count` of 1-4.

Due to C alignment requirements, it is *highly advised* that
each attribute should occupy a multiple of 4 bytes; e.g., `uint8`
typed attributes should have a count of 4, and `int16` a count of 2/4.

A `uint8` attribute can also be specified as `normalized`, in which case
integer values 0-255 will be normalized to 0.0-1.0 when seen in a shader.
If `normalized` is `false` or unspecified, then 255 in the buffer will be
seen as a floating-point 255.0 in the shader.
]]
returns {object 'vertex_info'}
example[[
local vinfo = gfx.create_vertex_type{
  position = {ctype = float, count = 3},
  normal   = {ctype = float, count = 3},
  color0   = {ctype = uint8, count = 4, normalized = true}
}
]]

funcdef 'create_basic_vertex_type'
args {list 'attribute_list', 
  bool 'preserve_order: whether to create attributes in listed order'}
returns {object 'vertex_info'}
description[[
Create a vertex type using default options for the specified attributes.
]]
example[[
local vinfo = gfx.create_basic_vertex_type({"position", "normal"})
]]

funcdef 'guess_vertex_type'
args {object 'geometry_data'}
description[[
Create a vertex type compatible with the given geometry data 
(see `StaticGeometry:from_data`).
Inferred attributes will be created with default type and count.
]]
returns {object 'vertex_info'}

funcdef{"invalid_handle"}
args{ctype 'handle_t: bgfx handle type'}
description "Creates an 'invalid' bgfx handle of the provided type."
example[[
local invalid = gfx.invalid_handle(bgfx.frame_buffer_handle_t)
]]
returns{cdata['handle_t'] 'handle'}

sourcefile{"geometry.t"}
description[[
Classes representing indexed geometyr.
]]

classdef 'StaticGeometry'
description[[
Create a new StaticGeometry.
]]
args{string 'name: optional name for the geometry'}

classfunc 'copy'
description[[
Have this geometry copy another geometry. The source geometry must be allocated
(have its data still in CPU buffers).
]]
args{object['StaticGeometry'] 'other'}
returns{self}

classfunc 'clone'
description[[
Returns a clone of this geometry. This geometry must still be allocated.
]]
returns[clone]

classfunc 'allocate'
description[[
Allocate space (in CPU ram) for indexed geometry.

After allocation, the fields `.verts` and `.indices` exist and can be modified.
Note that these buffers are 0 indexed C arrays and out-of-bounds access will
cause segfaults or worse rather than nice errors.
]]
args{int 'n_verts', int 'n_indices', object 'vertex_definition'}
returns{self}
example[[
  local vdef = gfx.create_basic_vertex_type{"position", "normal", "color0"}
  local geo = gfx.StaticGeometry()
  geo:allocate(12, 20*3, vdef) -- space for 12 vertices + 20 faces
]]

classfunc 'deallocate'
description[[
Release the CPU-side memory of this geometry. If it was previously 
committed, it can still be used for drawing operations.
]]
returns{self}

classfunc 'commit'
description[[
Commit the geometry to GPU memory, making it available for drawing operations.
After being committed, changes to the .verts and .indices fields will have
no effect on this geometry (although it can still be cloned, and the clone
will have the changed values).
]]
returns{self}

classfunc 'uncommit'
description 'Delete this geometry from GPU memory.'
returns{self}

classfunc 'destroy'
description 'Delete both GPU and CPU memory for this geometry.'
returns{self}

classfunc 'bind'
description[[
Bind this geometry (index and vertex buffers) for the next submission. The 
geometry must be committed.
]]

classfunc 'from_data'
args{table 'data', object 'vertex_def', 
     bool 'nocommit: do not automatically commit'}
description[[
Allocate and set this geometry from a table of vertex and index data.

Data should contain the following fields:
`.indices` should be a list-of-lists, with each list specifying three indices
for a triangle. Indices should be zero-indexed.

`.attributes` should contain fields for each vertex attribute present, and
each field should be a list of attribute values, either as lua lists, or
as math.Vectors.

If `vertex_def` is not specified, a vertex definition will be inferred using
`gfx.guess_vertex_type`.

By default, the geometry will be automatically committed to GPU, but the 
`nocommit` option can be used to override this behavior.
]]
returns{self}
example[[
-- make a quad from two triangles
local data = {
    indices = {{0, 1, 2}, {2, 3, 0}},
    attributes = {
        position = {
          math.Vector(0, 0, 0), math.Vector(1, 0, 0),
          math.Vector(0, 1, 0), math.Vector(1, 1, 0)
        }
    }
}
local quad = gfx.StaticGeometry("quad_patch"):from_data(data)
]]

classfunc 'set_indices'
args{list 'indices'}
returns{self}
description[[
Set indices for this geometry from a lua (1-indexed) list of lists.
Note that the index values themselves are 0-indexed into .vertices.
]]
example[[
  -- assume geo was allocated with space for six indices
  local indices = {{0, 1, 2}, {2, 3, 0}}
  geo:set_indices(indices)
]]

classfunc 'set_attribute'
args{string 'attrib_name', list 'values'}
returns{self}
description[[
Set one attribute (e.g., `position`, `color2`) from a list of values.
]]
example[[
  -- assume geo was allocated with space for four vertices
  local positions = {math.Vector(0, 0, 0), math.Vector(1, 0, 0),
                     math.Vector(0, 1, 0), math.Vector(1, 1, 0)}
  geo:set_attribute("position", positions)
]]

classdef 'DynamicGeometry'
extends 'StaticGeometry'
args{string 'name'}
description[[
Create a DynamicGeometry that can be updated after creation. Updating 
a DynamicGeometry is more performant than uncommitting and recommitting
a StaticGeometry.

DynamicGeometry shares all of StaticGeometry's methods, and adds the following.
]]

classfunc 'update'
description[[
Update the GPU representation of this geometry from its CPU buffers. If
the geometry is not committed, it will be committed.
]]

classfunc 'update_vertices'
description[[
Update just the GPU vertices from the CPU vertices (.verts). The geometry
must be committed already.
]]

classfunc 'update_indices'
description[[
Update just the GPU indices from the CPU indices (.indices). The geometry
must be committed already.
]]

sourcefile{"compiled.t"}
description[[
Compiled materials.
]]

funcdef "define_base_material"
description[[
Compile a material class that can efficiently hold and bind a fixed
set of uniforms.
]]
table_args{
  name = string 'name of the material class',
  uniforms = dict 'dictionary of uniform name = kind values',
  state = dict 'state dictionary passed to gfx.create_state',
  program = list '{vertex, fragment} list passed gfx.create_program'
}
returns{classproto 'MaterialClass'}
example[[
local SomeMaterial = gfx.define_base_material{
  name = "SomeMaterial",
  uniforms = {
    u_baseColor = 'vec',
    u_someMatrix = 'mat4',
    u_someTexture = {kind = 'tex', sampler = 0},
    u_globalLights = {kind = 'vec', count = 4, global = true},
  },
  state = {blend = "add"},
  program = {"vs_something", "fs_something_fancy"}
}
function SomeMaterial:custom_setter(x)
  self.uniforms.u_baseColor:set(x, x, x)
  return self
end
local material_instance = SomeMaterial():custom_setter(0.87)
]]

funcdef "anonymous_material"
description[[
Directly instantiate a material instance without first defining a material
class. This *does* compile a material behind the scenes so should be used
sparingly. The intended use is for the convenience of declaring materials
used in post-processing pipeline stages, where the material will only be
instantiated a single time for the stage.

Note that the uniforms table argument contains the actual uniform *values*
instead of the uniform *types*. Because of this, there are a few limitations:
uniform arrays are not supported, global uniforms are not supported, and
texture uniforms must be passed as {sampler_idx, Texture} tuples.
]]
table_args{
  uniforms = dict 'dictionary of uniform name = value',
  state = dict 'state dictionary passed to gfx.create_state',
  program = list '{vertex, fragment} list passed to gfx.create_program'
}
returns{ object['AnonymousMaterial'] 'material instance' }
example[[
local post_process_material = gfx.anonymous_material{
  program = {"vs_raytrace_arealights", "fs_raytrace_arealights"},
  uniforms = {
    s_normalMap = {0, self.normalmap},
    s_lightMap = {1, self.light_target},
    s_noiseMap = {2, self.noisemap},
    u_lightScale = math.Vector(1.0, self.width / self.height, 0.0, 0.0),
    u_normalScale = math.Vector(1.0, 1.0, 0.0, 0.0),
    u_extraParams = math.Vector(1.0, self.height / self.width, 0.15, 0.05),
    u_time = math.Vector(0.0, 0.0, 0.0, 0.0)
  },
  state = {
    depth_test = "always",
    cull = false,
    blend = "alpha"
  }
}
]]

classdef "BaseMaterial"
description[[
The base class that materials created with define_material inherit from.
]]

classfunc 'clone'
description[[
Clone this material instance to create a new instance with the same
uniform values, state, and program but which is unlinked from its source.
]]
returns{object["self.class"] 'cloned_self'}

classfunc 'set_state'
description[[
Set the state of this material. The argument can either be a state
table (which is then passed through gfx.create_state), or an already-evaluated
state uint.
]]
args{dict 'state: state table passed to gfx.create_state'}
returns{self}

classfunc 'set_program'
description[[
Set the program of this material. The argument can either be an actual
program object, or a {vertex_shader_name, fragment_shader_name} table.
]]
args{list 'program: {vertex, fragment} program list.'}
returns{self}

classfunc 'bind'
description[[
Bind this instance's uniform values and state for the next gfx submit.
]]
args{object['CompiledGlobals._value'] 'globals: can be nil'}
returns{self}

classdef "CompiledGlobals"
description[[
A set of global uniforms. Constructor takes no arguments because it can
hold any uniform value that has been declared global in any material.
]]

classfunc "update_globals_list"
description[[
If materials have been defined after this instance was created, this
function can be called to update the list of globals.
]]

classdef "Drawcall"
description[[
A compiled drawcall that accelerates submitting a drawing operation that
combines a geometry (vertex + index buffers) and a material (uniforms, state,
program).
]]
args{object 'geo: geometry', object 'mat: compiled material instance'}

classfunc 'set_geometry'
description[[
Set the geometry for this drawcall. Will trigger a recompilation.
]]
args{object 'geo: geometry'}
returns{self}

classfunc 'set_material'
description[[
Set the material for this drawcall. Will trigger a recompilation.
]]
args{object 'mat: compiled material instance'}
returns{self}

classfunc 'clone'
description[[
Clone this drawcall. Does not clone the linked geo/mat.
]]
returns{clone}

classfunc 'submit'
description[[
Submit a drawcall to be rendered.
]]
args{int 'viewid: bgfx view id', object['CompiledGlobals'] 'globals',
     object['Matrix4'] 'transform: model transform for drawcall'}

classfunc 'multi_submit'
description[[
Submit a drawcall to be rendered into multiple views with contiguous ids.
]]
args{int 'start_id: starting view id', int 'n_views: number of sequential views',
     object['CompiledGlobals'] 'globals',
     object['Matrix4'] 'transform: model transform for drawcall'}


funcdef{"solve_quadratic"}
description[[Solve a quadratric equation]]
args{
  number'a: first coeff', 
  number'b: second coeff', 
  number'c: third coeff'
}
example[[
-- a multiline example
local do_something = false
local second_line = tostring(nil)
for k,v in ipairs(whatever) do
  print(k)
end
]]
returns{number'first root or nil', number'second root or nil'}