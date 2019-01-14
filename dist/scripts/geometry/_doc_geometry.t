module{"geometry"}

sourcefile{'geometry generators'}
description[[
Functions for generating geometry. Note that every geometry data function
`[geo]_data` typically has an equivalent `[geo]_geo` function that returns
a `StaticGeometry` directly.
]]

func 'cube_data'
description[[
Create data for an axis-aligned cuboid centered at (0, 0, 0). The
cube faces are disconnected (have sharp normals). Each face has 
texture coordinates (0, 0) to (u_mult, v_mult).
]]
table_args{
  sx = number{'cube side length in x direction', default = 1.0},
  sy = number{'cube side length in y direction', default = 'sx'},
  sz = number{'cube side length in z direction', default = 'sy'},
  u_mult = number{'multiplier on U texture coordinate', default = 1.0},
  v_mult = number{'multiplier on V texture coordinate', default = 1.0}
}
returns{table 'data'}
example[[
local data = geometry.cube_data{1.0}
local data = geometry.cube_data{1.0, 2.0, 3.0}
local data = geometry.cube_data{sx = 2.0, sy = 2.0, sz = 1.0}
local geo = geometry.cube_geo{0.5}
]]

func 'cylinder_data'
description[[
Create data for a capped or uncapped cylinder. Normals and texture
coordinates are not currently created.
]]
table_args{
  radius = number{'cylinder radius', default = 1.0},
  height = number{'cylinder height', default = 1.0},
  segments = number{'number of segments', default = 16},
  capped = bool{'whether the cylinder is capped', default=true}
}
returns{table 'data'}
example[[
local data = geometry.cylinder_data{
  radius = 1.0, 
  height = 0.5, 
  segments = 12,
  capped = false
}
]]

func 'icosphere_data'
description[[
Create data for an approximation of a sphere derived from a subdivided
icosahedron. Each level of detail produces 4x the face count of the
previous level, i.e., at level 0 the result is an icosahedron with 20
faces, at level one the result has 80 faces. Does not produce
normals or UV coordinates.
]]
table_args{
  radius = number{'sphere radius', default = 1.0},
  detail = int{'subdivision level', default = 2}
}
returns{table 'data'}
example[[
local data = geometry.icosphere_data{radius = 2.0, detail = 3}
local geo = geometry.icosphere_geo{radius = 1.0, detail = 0}
]]

func 'plane_data'
description[[
Create data for a planar patch. The plane is oriented along the XY plane
and faces towards +Z.
]]
table_args{
  width = number{'plane width (X axis)', default = 1},
  height = number{'plane height (Y axis)', default = 1},
  segments = number{'subdivide the plane into NxN patches', default = 1},
  umin = number{'minimum U texcoord', default = 0},
  umax = number{'maximum U texcoord', default = 1},
  vmin = number{'minimum V texcoord', default = 0},
  vmax = number{'maximum V texcoord', default = 1}
}
returns{table 'data'}
example[[
local data = geometry.plane_data{width = 2, height = 1}
]]

func 'polygon_data'
description[[
Create geometry data from the triangulation of a (possibly non-convex)
planar polygon.
]]
table_args{
  pts = list 'polygon vertices'
}
returns{table 'data'}
example[[
local pts = {
  math.Vector(1, 1), 
  math.Vector(-1, 1), 
  math.Vector(0.5, 0.5), 
  math.Vector(1, -1)
}
local data = geometry.polygon_data{pts = pts}
]]

func 'uvsphere_data'
description[[
Create a typical approximation of a sphere from latitude-longitude patches.
Has both texture coordinates and normals.
]]
table_args{
  radius = number{'sphere radius', default = 1.0},
  lat_divs = int{'latitude divisions', default = 10},
  lon_divs = int{'longitude divisions', default = 10},
  cap_size = number{'how large the end caps are in radians', default = 5.0 * 3.14159/180.0},
  projfunc = callable{'projection function for UV coordinates', default = 'geometry.plate_carree'}
}
returns{table 'data'}
example[[
local data = geometry.uvsphere_data{radius = 1, lat_divs = 20, lon_divs = 40}
]]

func 'box_widget_data'
description[[
Create data for a box widget.
]]
table_args{
  side_length = number{'side length', default = 1.0},
  radius = number{'cylinder radius', default = 0.025},
  gap_frac = number{'fraction of edge that is gap', default = 0.5},
  segments = int{'cylinder segments on each edge', default = 6}
}
returns{table 'data'}
example[[
local data = geometry.box_widget_data{side_length = 2}
]]

func 'axis_widget_data'
description[[
Create data for an 'axis widget'.
]]
table_args{
  scale = number{'axis scale', default = 1.0},
  segments = int{'cylinder segments on each axis', default = 12}
}
returns{table 'data'}
example[[
local data = geometry.axis_widget_geo{scale = 10.0}
]]

sourcefile{'geoutils.t'}
description[[
Various utilities for dealing with geometry data.
]]

func 'spherize'
description[[
Project vertices onto a sphere. Modifies the data in-place.
]]
args{table 'data', number 'radius'}
returns{table 'data'}

func 'combine_duplicate_vertices'
description[[
Merge together sufficiently close vertices. Returns new
data.
]]
args{table 'data', int 'precision'}
returns{table 'data'}

func 'subdivide'
description[[
Subdivide each triangle a number of times. Each round of subdivision
multiplies the number of triangles by four. Returns new data.
]]
args{table 'data', int{'rounds: how many rounds of subdivision to apply', default = 1}}
returns{table 'data'}

func 'compute_normals'
description[[
Compute normals for each vertex as the average of the normals of each
adjacent triangle. Modifies or creates `data.attributes.normal` in-place.
]]
args{table 'data'}
returns{table 'data'}

func 'split_triangles'
description[[
Split the data into a 'triangle soup' where no triangles share vertices.
Returns new data.
]]
args{table 'data'}
returns{table 'data'}

func 'convex_hull'
description[[
Produce a triangle mesh which is the convex hull of a set of points.
Warning: poorly tested, known to fail in many edge cases, O(n^4) run time.
]]
args{list 'pts: a list of Vectors'}
returns{table 'data'}

