---
title: gfx
---

The gfx module is a lightweight wrapper around raw bgfx calls.

{{ site.begin_sidebar }}
### Anatomy of a bgfx/gfx submit

Most commonly an individual submission/drawcall will have to
specify the following things:

1. transform matrix
2. index and vertex buffers
3. shader uniforms
4. draw state (blending mode, backface culling, etc.)
5. bgfx view
6. shader program (vertex + fragment shader)

```lua
-- 
gfx.set_transform(model_matrix)    -- 1 
model_geometry:bind()              -- 2
material_uniforms:bind()           -- 3
gfx.set_state(material_draw_state) -- 4
gfx.submit(view, material_program) -- 5+6
```

{{ site.end_sidebar }}

## Common gfx functions (gfx/common.t)

### init_gfx(options)
Initializes the graphics system (bgfx)-- a window *must* be created first.

| Option        | Description           | Default  |
| ------------- |---------------------- | -------- |
| window        | any object with `get_window_size()` | nil |
| width         | backbuffer width; required if window not specified | nil |
| height        | backbuffer height; required if window not specified | nil |
| backend       | rendering backend API | use bgfx OS default |
| lowlatency    | reduce rendering latency (single-threaded) | false |
| msaa          | use msaa antialiasing | false |
| vsync         | use vsync             | true  |
| debugtext     | draw debug text       | false |

Returns: false on failure.

### reset_gfx(options)
Resets the graphics system (e.g., to resize the backbuffer on window size change).
Options are the same as `init_gfx()`.

Returns: false on failure.

### schedule(func, frames)
Schedules `func` to be called after a specified number of frames. If `frames` is
omitted, then it is scheduled for a 'safe' number of frames (3 in multithreaded
mode, 1 in single-threaded mode).

This is useful for bgfx operations that require that memory references lives for
a certain number of frames.

### set_transform(matrix)
Sets the model matrix for the next call to `submit`. The provided `matrix` should
be a math.Matrix4.

### frame()
Renders the current frames and runs scheduled functions. If vsync is enabled, this
call will block to maintain frame timing.

### submit(view, program, depth, preserve_state)
Submit a draw call to bgfx. `view` can either be a numeric view id, or a gfx.View
object. `depth` controls draw call sorting within the view, although note that
calls are first batched according to program, state, etc. and `depth` only controls
sorting after that. If `preserve_state` is set to true, then all the parameters
for this submission will be retained for the next one.

### State(options), create_state(options)
Returns a state encoding the provided drawing options. These are largely the
bgfx state options verbatim.

| Option        | Description           | Default  |
| ------------- |---------------------- | -------- |
| rbg_write        | write color to target | true |
| depth_write         | write depth to target | true |
| alpha_write        | write alpha to target | true |
| conservative_raster       | use conservative rasterization | false |
| msaa    | use msaa (if enabled) | true |
| depth_test | depth test mode (see below) | "less" |
| cull         | backface culling: "cw", "ccw", false | "cw"  |
| blend     | blend mode (see below)   | false |
| pt or primitive | alternate primitive mode (see below) | false |

`depth_test` specific options:
'less', 'lequal', 'equal', 'gequal', 'greater', 'notequal', 'never', 'always', false

Note that `depth_test` = false and `depth_test` = 'always' are functionally identical.

`blend` specific options:
'add', 'alpha', 'darken', 'lighten', 'multiply', 'normal', 'screen', 'linear_burn', false

Although bgfx supports much greater flexibility in blend modes than these presets,
but currently you will need to manually construct a state by combining bgfx flags to
make use of that.

`primitive` specific options:
'tristrip', 'lines', 'linestrip', 'points', false (= triangles)

This controls how indices from the index buffer are interpreted to produce drawn primitives.
The default (false) is triangles.

### set_state(state)
Sets the state for the next submission; `state` can either be directly created by combining
bgfx flags, or through the `gfx.State` and `gfx.create_state` functions.

### invalid_handle(ctype)
Creates an 'invalid' bgfx handle of the provided C type.

{{ site.begin_sidebar }}
```lua
-- Note that the invalid framebuffer is the backbuffer
local invalid = gfx.invalid_handle(bgfx.frame_buffer_handle_t)
```
{{ site.end_sidebar }}

### save_screenshot(filename, rendertarget)
Save a screenshot of the specified rendertarget (or backbuffer if none specified) to
the provided filename. Currently screenshots are always saved as .png regardless of
extension.

Due to bgfx limitations, a render target (other than backbuffer) 
must be specifically created with the 'readback' capability to have screenshots saved from it.

### get_stats(includeviews)
Get detailed performance statistics. If `include_views` is set to true, then additional detailed
statistics for individual views are available in the return value's `.views` field.

### load_program(vertex, fragment)
Loads a shader program specified by the given vertex and fragment shader names. The appropriate
type of shader (glsl, hlsl, etc.) will be chosen based on the backend that gfx was initialized
with.

### load_file_to_bgfx(filename)
Loads a file into a `bgfx_memory_t` reference.

### Vertex type definitions
#### create_vertex_type(attribute_table, order)
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

{{ site.begin_sidebar }}
```lua
local vinfo = gfx.create_vertex_type{
    position = {ctype = float, count = 3},
    normal   = {ctype = float, count = 3},
    color0   = {ctype = uint8, count = 4, normalized = true}
}
```
{{ site.end_sidebar }}

#### create_basic_vertex_type(attribute_list, preserve_order)
Create (or fetch a cached version) of a vertex type using default options
for its attributes. `attribute_list` should be a list of attribute names;
if `preserve_order` is specified then the resulting vertex type will have
the attributes in the same order, otherwise they will be reordered into the
default order.

{{ site.begin_sidebar }}
```lua
local vinfo = gfx.create_basic_vertex_type({"position", "normal"})
```
{{ site.end_sidebar }}

#### guess_vertex_type(geometry_data)
Create a vertex type to hold the information in `geometry_data` (see
`StaticGeometry:from_data` for details of the organization of this structure).
Note that this only looks at which attributes are present and uses the default
types and counts for those attributes.

### StaticGeometry
#### StaticGeometry(name)
Create a new StaticGeometry with the given (optional) name.

#### StaticGeometry:copy(source)
Have this StaticGeometry copy another geometry. The source geometry must be allocated
(have its data still in CPU buffers).

#### StaticGeometry:clone()
Returns a clone of this geometry. This geometry must still be allocated.

#### StaticGeometry:allocate(n_verts, n_indices, vertinfo)
Allocate space for a given number of vertices and indices, with the specified
vertex definition (see `create_vertex_type` and `create_basic_vertex_type`). Assuming default triangle primitives, `n_indices = n_faces * 3`.

After allocation, the fields `.verts` and `.indices` exist and can be modified.
Note that these buffers are *0 indexed C arrays*.

#### StaticGeometry:commit()
Commit the geometry to GPU memory, making it available for drawing operations.
After being committed, changes to the .verts and .indices fields will have
no effect on this geometry (although it can still be cloned into a *new* geometry
that can be then committed, or it can be uncommitted and then committed again).

#### StaticGeometry:uncommit()
Delete this geometry from GPU memory.

#### StaticGeometry:deallocate() (deprecated: StaticGeometry:release_backing())
Release the CPU-side memory of the geometry. The geometry will be considered
unallocated after this operation (e.g., cannot be cloned because its buffers
reside solely on GPU).

#### StaticGeometry:destroy()
Delete both GPU and CPU memory for this geometry.

#### StaticGeometry:bind()
Bind this geometry (index and vertex buffers) for the next submission. The 
geometry must be committed.

#### StaticGeometry:from_data(data, vertexinfo, nocommit)
Allocate and set this geometry from the lua table `data`, which should
be organized as
```lua
local data = {
    indices = {...},
    attributes = {
        position = {...},
        ...
    }
}
```
`.indices` should be a list-of-lists, with each list specifying three indices
for a triangle. Indices should be zero-indexed.

`.attributes` should contain fields for each vertex attribute present, and
each field should be a list of attribute values, either as lua lists, or
as math.Vectors.

If `vertexinfo` is not specified, it will try to infer a reasonable vertex layout
based on what attributes are present in the data.

By default, the geometry will be automatically committed to GPU, but the 
`nocommit` option can be used to override this behavior.

### DynamicGeometry

DynamicGeometry shares all the above methods with StaticGeometry, and also
has the following additional methods:

#### DynamicGeometry:update()
Update the GPU representation of this geometry from its CPU buffers. If
the geometry is not committed, it will be committed.

#### DynamicGeometry:update_vertices()
Update just the GPU vertices from the CPU vertices (.verts). The geometry
must be committed already.

#### DynamicGeometry:update_indices()
Update just the GPU indices from the CPU indices (.indices). The geometry
must be committed already.

### Uniforms
The `Uniform` constructor should not be used directly. Instead, create a
`VecUniform`, `MatUniform`, `VecArrayUniform`, `MatArrayUniform`,
 or `TexUniform`.

#### VecUniform(name, value)
Create a vector-typed uniform (always Vec4) with the given name (exactly
as it appears in the shader, e.g., `u_diffuseColor`) and initial value.

#### MatUniform(name, value)
Create a matrix-typed uniform (always Mat4).

#### VecArrayUniform(name, count)
Create an array-of-vectors uniform (each element is Vec4) with the given
name and count.

#### MatArrayUniform(name, count)
Create an array-of-matrices uniform (each element is Mat4) with the given
name and count.

#### TexUniform(name, sampler_index, value)
Create a texture (sampler) uniform. Both `name` and `sampler_index` must
match how the uniform is declared in the shader.

#### Uniform:clone()
Clone this uniform. The cloned uniform will share the same underlying uniform handle,
but can be independently set to a different value.

#### VecUniform:set(x, y, z, w)
Set this uniform.

{{ site.begin_sidebar }}
```lua
local gray_list = {0.5, 0.5, 0.5, 1.0}
local gray_vec = math.Vector(0.5, 0.5, 0.5, 1.0)

local u = gfx.VecUniform("u_diffuseColor")
u:set(0.5, 0.5, 0.5, 1.0) -- direct
u:set(gray_list)          -- from list
u:set(gray_vec)           -- from math.Vector
```
{{ site.end_sidebar }}

#### MatUniform:set(m)
Set this uniform

{{ site.begin_sidebar }}
```lua
local m = math.Matrix4():identity()
local u = gfx.MatUniform("u_someMatrix")
u:set(m)
```
{{ site.end_sidebar }}

#### [Vec|Mat]ArrayUniform:set(index, value)
Set an element of this array to a value; like lua in general,
indices are 1-indexed, so the first element is at index 1.
For VecArrayUniforms, the value can be either a `math.Vector` 
or an `{x, y, z, w}` list. 
For a MatArrayUniform the value must be a `math.Matrix4`.

#### [Vec|Mat]ArrayUniform:set_multiple(values)
Set multiple values in a uniform array.

{{ site.begin_sidebar }}
```lua
local u = gfx.VecArrayUniform("u_lightColors", 4)
u:set_multiple({
  math.Vector(1.0, 0.0, 0.0),
  math.Vector(0.0, 1.0, 0.0),
  {0.0, 0.0, 1.0} -- mixing math.Vectors and lists is allowed
})
```
{{ site.end_sidebar }}

#### Uniform:bind()
Bind the value of this uniform for the next submit call.

#### Uniform:bind_global(global)
Bind the 'global' uniform, or if nil, this uniform's value.

#### UniformSet(uniforms)
Create a set of uniforms. The argument `uniforms` can be either a list
of `Uniform`s, or a table of name: value pairs (in which
case `Uniform`s will be automatically created based on the
types of the values). To create a texture uniform using the
table syntax, the value must be a {sampler_index, texture}
tuple. In table syntax, vector uniforms must be `math.Vectors`.

{{ site.begin_sidebar }}
```lua
-- create empty, :add
local uset = gfx.UniformSet()
uset:add(gfx.TexUniform("s_noiseMap", 0, gfx.Texture("textures/noise.png")))
uset:add(gfx.VecUniform("u_lightHeight", 1, {1.0, 1.0}))
uset:add(gfx.VecUniform("u_mapScale", 1, {0.5}))

-- list syntax
local uset = gfx.UniformSet{
  gfx.TexUniform("s_noiseMap", 0, gfx.Texture("textures/noise.png")),
  gfx.VecUniform("u_lightHeight", 1, {1.0, 1.0}),
  gfx.VecUniform("u_mapScale", 1, {0.5})
}

-- table/dictionary syntax
local uset = gfx.UniformSet{
  s_noiseMap = {0, gfx.Texture("textures/noise.png")},
  u_lightHeight = math.Vector(0.5),
  u_mapScale = math.Vector(1.0, 1.0)
}

-- the created uniforms are available directly on the object in all cases
uset.u_mapScale:set(math.Vector(2.0, 3.0))
```
{{ site.end_sidebar }}

#### UniformSet:clone()
Create a clone of the UniformSet, which `:clone`s every contained
`Uniform`.

#### UniformSet:bind()
Bind all the uniforms in this set for the next submit call.

#### UniformSet:bind_as_fallbacks(globals)
For each uniform in this set, bind the global version if it is present
in `globals`, otherwise bind the value in this set.

#### UniformSet:merge(rhs)
Merge (in-place) the uniforms in another `UniformSet` into this one.
The merged uniforms are cloned.

#### UniformSet:set(values)
Set uniforms in the set from a table of name: value pairs.

### RenderTarget

### View

#### Texture(filename, flags)
Create a texture from the given filename with the provided bgfx flags.

#### Texture:is_valid()
Returns true if this texture is valid.

#### Texture:load(filename, flags)
Load the image in `filename` into this Texture with the given bgfx flags.

#### Texture:create_copy_target(src, options)
Allocate this Texture as a copy target for the `src` texture. This
texture will then have the same dimensions and format as the source
texture.

#### Texture:create(options)
Allocate a 2d texture. Note that the only ways to get data into this
texture will be either by copying (blitting) into it, or by rendering
into it. For a texture that can be updated from CPU memory, use
`MemTexture`.

| Option        | Description           | Default  |
| ------------- |---------------------- | -------- |
| width        | texture width (pixels) | (required) |
| height         | texture height (pixels) | (required) |
| format        | texture format | bgfx.TEXTURE_FORMAT_BGRA8 |
| flags       | additional bgfx flags | 0 |
| blit_dest    | can blit into this texture | true |
| render_target | can render into this texture | false |

#### Texture:create_cubemap(options)
Allocate a cubemap texture. Shares most options with `Texture:create`,
except that the `.size` parameter must be set instead of `.width` and 
`.height` (because cubemap faces are always square).

#### Texture:copy(src, options)
Copy the source texture into this texture by blitting. This texture must
be blittable. If this texture wasn't allocated, it will automatically be
allocated as a blit destination of the same dimensions and format as src.

If this texture is a cubemap, the target face can be specified in options.

Note that in bgfx, blit operations do not happen 'immediately', but happen
within views like other drawing operations. Unless specified in options,
this blit/copy will attempt to take place in viewid 0 (i.e., as early
in the frame as possible).

| Option        | Description             | Default |
| ------------- |------------------------ | ------- |
| cubeface      | destination cube face   |    0    |
| viewid        | viewid in which to blit |    0    |

#### MemTexture(width, height, format, flags)
Create a texture that can be dynamically updated from CPU memory.

{{ site.begin_sidebar }}
```lua
local mtex = MemTexture(32, 32, "BGRA8")
for x = 0, 31 do
  for y = 0, 31 do
    -- note 0-indexing of data
    local pos = (y*32 + x)*4 -- 4 bytes/pixel in BGRA8
    mtex.data[pos+0] = math.random() * 255.0
    mtex.data[pos+1] = math.random() * 255.0
    mtex.data[pos+2] = math.random() * 255.0
    mtex.data[pos+3] = 255 -- alpha
  end
end
mtex:update()
```
{{ site.end_sidebar }}

#### MemTexture:update()
Update the GPU texture from the CPU-side `.data` buffer.