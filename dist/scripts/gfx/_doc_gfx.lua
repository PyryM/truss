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
description[[
Creates an 'invalid' bgfx handle of the provided type. Bgfx occasionally
uses invalid handles as signals, e.g., an invalid `frame_buffer_handle_t`
corresponds to the backbuffer.
]]
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
Holds indexed geometry that, once committed to GPU, will not change.
]]

classfunc 'init'
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
returns{clone}

classfunc 'allocate'
description[[
Allocate space in CPU memory for indexed geometry.

After allocation, the fields `.verts` and `.indices` exist and can be modified.
Note that these buffers are 0 indexed C arrays and out-of-bounds access will
cause segfaults or worse (see `:set_indices` and `:set_attribute` for safer
ways to fill these buffers).
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
Release the CPU memory of this geometry. If it was previously 
committed, it can still be used for drawing operations.
]]
returns{self}

classfunc 'commit'
description[[
Commit the geometry to GPU, making it available for drawing operations.
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

`indices` should be a list-of-lists, with each list specifying three indices
for a triangle. Indices are zero-indexed into the vertex list.

`attributes` should contain fields for each vertex attribute present, and
each field should be a list of attribute values, either as lua lists, or
as math.Vectors.

`vertex_def` should be a vertex definition, or `nil` to automatically
infer a vertex type with `gfx.guess_vertex_type`.

By default, the geometry will be automatically committed to GPU, but the 
`nocommit` option can be used to override this behavior.
]]
returns{self}
example[[
-- make a quad from two triangles
local data = {
  indices = {{0, 1, 2}, {2, 3, 0}},
  attributes = {
    position = {math.Vector(0, 0, 0), math.Vector(1, 0, 0),
                math.Vector(0, 1, 0), math.Vector(1, 1, 0)},
    normal = {math.Vector(0, 0, 1), math.Vector(0, 0, 1),
              math.Vector(0, 0, 1), math.Vector(0, 0, 1)}
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
description[[
Indexed geometry that can be updated after being committed to GPU.
Updating a DynamicGeometry is more performant than uncommitting 
and recommitting a StaticGeometry.

DynamicGeometry has all of StaticGeometry's functions.
]]

classfunc 'init'
args{string 'name'}
description[[
Create a DynamicGeometry.
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

sourcefile 'compiled.t'
description[[
Compiled materials.
]]

funcdef 'define_base_material'
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
returns{class 'MaterialClass'}
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
returns{ class 'AnonymousMaterial' }
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

classdef 'BaseMaterial'
description[[
The base class that materials created with define_material inherit from.
]]

classfunc 'clone'
description[[
Clone this material instance to create a new instance with the same
uniform values, state, and program but which is unlinked from its source.
]]
returns{clone}

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

classdef 'CompiledGlobals'
description[[
A set of global uniforms. Constructor takes no arguments because it can
hold any uniform value that has been declared global in any material.
]]

classfunc 'update_globals_list'
description[[
If materials have been defined after this instance was created, this
function can be called to update the list of globals.
]]

classdef 'Drawcall'
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


sourcefile 'formats.t'
description[[
Defines texture formats. The texture formats are available as
`gfx.TEX_{format}` constants, e.g., `gfx.TEX_BGRA8`.
]]
example[[
truss.table_print(gfx.TEX_RGBA8)
-------------
{
  name: 'BGRA8'
  bgfx_enum: 49
  channel_type: uint8
  n_channels: 4
  channel_size: 1
  pixel_size: 4
  has_color: true
  has_depth: false
  has_stencil: false  
}
]]

fields{
  all_formats = table 'A table of every texture format.'
}

funcdef 'find_format_from_enum'
args{int 'bgfx_enum_val: bgfx texture constant'}
returns{table 'truss_format'}
description[[
Gives the truss texture info structure corresponding to a bgfx
texture identifier (e.g., BGFX_TEXTURE_FORMAT_RGBA32F).
]]

sourcefile 'shaders.t'
description[[
Functions for loading shaders.
]]

funcdef 'get_shader_path'
returns{string 'shader_path'}
description[[
Returns the file path to the directory containing the shaders
compatible with the current backend.

Requires gfx to have been initialized.
]]

funcdef 'load_shader'
args{string 'shader_name'}
returns{cdata['bgfx_shader_handle'] 'shader'}
description[[
Loads and caches a shader. Subsequent load calls for the same
name will return the cached shader. The shader name does not
need to include the directory path or file extension.
]]
example[[
local vshader = gfx.load_shader("vs_basic")
]]

funcdef 'load_program'
args{string 'vertex_shader', string 'fragment_shader'}
returns{cdata['bgfx_program_handle'] 'program'}
description[[
Loads and caches a program (a combination of vertex and fragment shaders).
The individual vertex and fragment shaders are cached as well.
]]
example[[
local program = gfx.load_program("vs_solid", "fs_solid_hadcoded_red")
]]

funcdef 'error_program'
returns{cdata['bgfx_program_handle'] 'program'}
description[[
Returns the 'error program', a zero-uniforms program meant to make it
easy to visually identify geometry that is drawn with it (the default
error program draws in a flat, unshaded bright magenta).
]]

sourcefile 'texture.t'
description[[
Textures.
]]

funcdef 'combine_tex_flags'
table_args{
  u = enum{'texture mode in U axis', 
           options={'repeat', 'mirror', 'clamp'}, 
           default='repeat'},
  v = enum{'texture mode in V axis',
           options={'repeat', 'mirror', 'clamp'}, 
           default='repeat'},
  w = enum{'texture mode in W axis',
           options={'repeat', 'mirror', 'clamp'}, 
           default='repeat'},
  min = enum{'minification filter', 
            options={'bilinear', 'point', 'anisotropic'},
            default='bilinear'},
  mag = enum{'magnification filter', 
            options={'bilinear', 'point', 'anisotropic'},
            default='bilinear'},
  mip = enum{'mip-mapping filter', 
            options={'bilinear', 'point', 'anisotropic'},
            default='bilinear'},
  msaa = bool 'msaa??',
  render_target = bool 'allow rendering to this texture',
  rt_write_only = bool 'this texture can be rendered to but not read',
  compare = bool 'compare mode??',
  compute_write = bool 'compute shaders can write to this texture',
  srgb = bool 'this is an srgb (gamma) texture',
  blit_dest = bool 'this texture can be blitted to',
  read_back = bool 'can read back this texture into CPU memory'
}
returns{int 'state_flags', table 'expanded_options'}
description[[
Combines texture options into a single integer of bit flags as expected
by bgfx.
]]

funcdef 'Texture'
args{string 'filename', table 'flags'}
returns{object['Texture'] 'texture'}
description[[
Create a texture from a file. If provided, flags should be a table
of texture options as used by `combine_tex_flags`. Supported formats
are .png, .jpg, .ktx, .dds, and .pvr. 

Note that, although this is named like a class, it is actually a function
that returns the appropriate subclass of Texture, i.e., loading a .png
will return a Texture2d, while loading a .ktx containing a cubemap will
return a TextureCube.

The .png and .jpg loaders are provided as a development convenience, but
only load RGBA8, and without mipmaps.
Cubemaps, 3d textures, hdr textures, etc. should use the other texture formats.
]]
example[[
local tex = gfx.Texture("textures/test_pattern.png")
]]

funcdef 'load_texture_data'
args{string 'filename'}
returns{table 'texture_data'}
description[[
Load a .png or .jpg file into memory as uncompressed RGBA8. The returned
table has the fields .w, .h, .n (always 4), and .data, which is a cdata
array of uint8.
]]

classdef 'Texture'
description[[
Base class for textures: not directly instantiatable, and not
exported (the 'class' gfx.Texture is actually a function that instantiates
the correct type of subclass for the requested file).
]]

classfunc 'commit'
description[[
Upload this texture to GPU, making it available for drawing operations.
]]

classfunc 'destroy'
description[[
Destroy this texture, releasing both CPU and GPU memory and
destroying all handles.
]]

classfunc 'release'
description[[
Alias for :destroy.
]]

classfunc 'is_renderable'
returns{bool 'can_render_to'}
description[[
Returns whether this texture can be used as a render target.
]]

classfunc 'is_blittable'
returns{bool 'can_blit_to'}
description[[
Returns whether this texture can be used as a blit target.
]]

classdef 'Texture2d'
description[[
A regular 2d texture.
]]

classfunc 'init'
table_args{
  dynamic = bool 'allow updates after creation',
  width = int 'width in pixels',
  height = int 'height in pixels',
  format = object['format_info'] 'a gfx.TEX_{...} texture format',
  flags = table 'texture flags (see `combine_tex_flags`)',
  commit = bool{'automatically commit texture to GPU', default=true},
  allocate = bool{'allocate a buffer to hold the texture data', default=false}
}
description[[
Create an empty 2d texture.

If allocate=true, then the .cdata array is available
to be manipulated (warning: this is a raw C array, and is thus 0-indexed and
out of range access will result in horrible segfaults or worse).
]]
example[[
-- create a gradient
local tex = gfx.Texture2d{width = 32, height = 32, allocate = true}
for row = 0, 31 do
  for col = 0, 31 do
    for channel = 0, 3 do 
      tex.cdata[(row*32+col)*4 + channel] = col*8
    end
  end
end
tex:commit() -- updating cdata after this has no effect
]]

classfunc 'update'
description[[
Update this texture on GPU if it was created as dynamic.
]]

classdef 'Texture3d'
description[[
A 3d texture.
]]

classfunc 'init'
table_args{
  width = int 'width in voxels',
  height = int 'height in voxels',
  depth = int 'depth in voxels',
  format = object['format_info'] 'a gfx.TEX_{...} texture format',
  flags = table 'texture flags (see `combine_tex_flags`)',
  commit = bool{'automatically commit texture to GPU', default=true}
}
description[[
Create an empty 3d texture. 
Dynamic 3d textures are not yet implemented.
]]

classdef 'TextureCube'
description[[
A cube-map texture, represented as six square cube faces.
]]

classfunc 'init'
table_args{
  size = int 'cube map face size, in pixels',
  format = object['format_info'] 'a gfx.TEX_{...} texture format',
  flags = table 'texture flags (see `combine_tex_flags`)',
  commit = bool{'automatically commit texture to GPU', default=true}
}
description[[
Create an empty cube map. Note that cube map faces are square, so
`size` is used instead of `width` and `height`.

Dynamic cubemap textures are not yet implemented (they can, however, be
rendered and blitted to if the correct flags are provided).
]]

sourcefile 'rendertarget.t'
description[[
Render target (buffer) management.
]]

funcdef 'ColorDepthTarget'
table_args {
  color_format = object{'texture format', default = 'gfx.TEX_BGRA8'},
  depth_format = object{'texture format', default = 'gfx.TEX_D24S8'},
  color_flags = table{'texture flags', default = '{rt = true, u = "clamp", v = "clamp"}'},
  depth_flags = table{'texture flags', default = '{rt_write_only = true}'},
  width = int 'pixel width',
  height = int 'pixel height',
  mips = bool 'automatically generate mipmaps (not working?)'
}
returns{object['RenderTarget'] 'target'}
description[[
Create a basic rendertarget with one color buffer and optionally a
depth+stencil buffer. To create a target without a depth buffer,
pass `depth_format = false`.
]]
example[[
local target = gfx.ColorDepthTarget{width = 1280, height = 720,
                                    color_format = gfx.RGBA32F,
                                    depth_format = false}
]]

funcdef 'GBufferTarget'
table_args {
  color_formats = list 'texture formats',
  depth_format = object 'texture format',
  color_flags = table{'texture flags', default = '{rt = true, u = "clamp", v = "clamp"}'},
  depth_flags = table{'texture flags', default = '{rt_write_only = true}'},
  width = int 'pixel width',
  height = int 'pixel height',
}
returns{object['RenderTarget'] 'target'}
description[[
Create a 'gbuffer' with multiple color buffers of the same size and optionally
a depth buffer. 
]]
example[[
local target = gfx.GBufferTarget{
  color_formats = {gfx.TEX_BGRA8, gfx.TEX_R32F},
  depth_format = gfx.TEX_D24,
  width = 1024, height = 1024 
}
]]

funcdef 'BackbufferTarget'
returns{object['RenderTarget'] 'backbuffer'}
description[[
Create a rendertarget representing the backbuffer. Note that
`width` and `height` aren't specified because these are set by
`gfx.init_gfx`. However, the fields `.width` and `.height` will
correctly reflect the backbuffer size.
]]
example[[
local backbuffer = gfx.BackbufferTarget()
-- this is OK: the rendertarget knows the backbuffer dimensions
local aspect = backbuffer.width / backbuffer.height
]]

funcdef 'TextureTarget'
table_args{
  tex = object['gfx.Texture'] 'texture to turn into a rendertarget',
  mip = int 'mip level to render into',
  layer = int 'layer to render into (cubemaps, arrays, 3d textures)',
  depth_format = object 'texture format',
  depth_flags = table 'texture flags'
}
returns{object['RenderTarget'] 'target'}
description[[
Create a rendertarget that renders into a given texture. The texture
must have been created with the `rt` flag. If the texture is a cubemap,
3d texture, or texture array, then the `layer` option is used to select
which face/depth/index is rendered into.

This is intended mainly to render to cubemaps and 3d textures.
Since you can use a RenderTarget for most purposes as a texture
(e.g., a texture-typed uniform can be set from a RenderTarget),
to render into a 2d texture it is preferrable to instead create
a RenderTarget and use it as a texture.
]]
example[[
local cubemap = gfx.TextureCube{
  size = 2048,
  flags = {render_target = true},
  allocate = false -- no CPU memory needed
}:commit()
local positive_y_face = gfx.TextureTarget{
  tex = cubemap,
  layer = 2, -- 0-indexed, face order: +x, -x, +y, -y, +z, -z
  depth_format = gfx.TEX_D24
}
]]

classdef 'RenderTarget'
description[[
Represents a render target.
]]
fields{
  width = int 'width in pixels',
  height = int 'height in pixels',
  has_color = bool 'whether this target has a color buffer',
  has_depth = bool 'whether this target has a depth buffer',
  is_backbuffer = bool 'whether this targets the backbuffer',
  has_stencil = bool 'whether this target has a stencil buffer',
  cloneable = bool 'whether this target can be cloned',
  framebuffer = cdata['bgfx_frame_buffer_handle'] 'raw bgfx handle'
}

classfunc 'init'
table_args {
  width = int 'pixel width',
  height = int 'pixel height',
  layers = list 'buffers to create'
}
description[[
Create a rendertarget from a list of layers. Typically you should
not invoke this directly, instead use one of the factory methods
`ColorDepthTarget`, `GBufferTarget`, or `TextureTarget`.
]]

classfunc 'clone'
returns{clone}
description[[
Clone this rendertarget to create a new rendertaget with the same
size and layer arrangement. 

Note that the actual contents of the layers are NOT copied.
]]

classfunc 'get_attachment_handle'
args{int 'idx: index of attachment to get (1-indexed)'}
returns{cdata['bgfx_texture_handle'] 'texture_handle'}
description[[
Get the raw bgfx texture handle for a given layer of this
rendertarget. E.g., in a ColorDepthTarget, index 1 is the 
color buffer, and index 2 is the depth buffer.
]]

classfunc 'destroy'
description[[
Destroy this rendertarget, releasing all CPU and GPU resources.
Attempting to destroy the backbuffer has no effect.
]]

sourcefile 'view.t'
description[[
View management.
]]

classdef 'View'
description[[
Represents a bgfx 'view'.
]]

classfunc 'init'
table_args{
  render_target = object['RenderTarget'] 'target to render into',
  view_matrix = object['Matrix4'] 'view matrix',
  proj_matrix = object['Matrix4'] 'projection matrix',
  viewport = tuple 'viewport (see set_viewport)',
  clear = table 'clear values (see set_clear)',
  sequential = bool 'if true, view will draw in strict submission order',
  name = string 'name of the view (for debugging)'
}
description[[
Create a new View. Note that the view will need to be bound to a viewid
with :bind. 
]]

classfunc 'set'
args{table 'options: see constructor for options'}
returns{self}
description[[
Change view settings; takes same options as constructor.
]]

classfunc 'set_matrices'
args{object['Matrix4'] 'view_matrix', object['Matrix4'] 'proj_matrix'}
description[[
Set view and projection matrices. Passing nil indicates that the matrix
should be left unchanged, if you only want to change one of the matrices.
]]

classfunc 'set_viewport'
args{tuple 'viewport: {x, y, width, height}'}
description[[
Set the viewport. Pass in false to clear the viewport.
Note that the viewport is defined in pixel coordinates.
]]

classfunc 'set_clear'
table_args{
  color = int 'color clear value as packed integer',
  depth = number 'depth clear value',
  stencil = int 'stencil clear value'
}
description[[
Set how the rendertarget will be cleared before this view renders.
A value can be set to false to not clear, or false can be passed in
instead of a table to not clear at all.
]]
example[[
-- typical clear values for color and depth
local v = View{clear = {color = 0x000000ff, depth = 1.0}}
v:set_clear{color = 0x000000ff, depth = false} -- clear only depth
v:set_clear(false) -- don't clear at all
]]

classfunc 'set_render_target'
args{object['RenderTarget'] 'target'}
description[[
Set the rendertarget that this view will render into. Note that
multiple views can render into the same target (in which case their
clear values are especially important).
]]

classfunc 'set_sequential'
args{bool 'sequential'}
description[[
Set whether view is in sequential rendering mode. Normally
(sequential = false) bgfx will sort submissions into a view
based on its own internal logic of what order minimizes state
changes. With sequential = true, the view will render submissions
to it in the exact order that they are submitted.
]]

classfunc 'get_dimensions'
returns{int 'width', int 'height'}
description[[
Get the dimensions of the target that this view renders into, without
accounting for viewport.
]]

classfunc 'get_active_dimensions'
returns{int 'width', int 'height'}
description[[
Get the dimensions of the target that this view renders into,
cropped according to the viewport.
]]

classfunc 'bind'
args{int 'viewid'}
returns{self}
description[[
Bind this view to a viewid. Views are rendered in increasing
order of their viewids.
]]

classfunc 'touch'
returns{self}
description[[
A view will only clear if it actually has drawcalls submitted
into it. Touching a view forces it to apply its clear even when nothing
has been submitted into it.
]]
