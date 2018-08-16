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
description"Creates an 'invalid' bgfx handle of the provided type."
example[[
local invalid = gfx.invalid_handle(bgfx.frame_buffer_handle_t)
]]
returns{cdata['handle_t'] 'handle'}

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