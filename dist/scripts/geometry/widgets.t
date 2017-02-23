-- geometry/widgets.t
--
-- various geometric widgets like axis bars

local m = {}
local geoutils = require("geometry/geoutils.t")
local math = require("math")
local cylinder = require("geometry/cylinder.t")

function m.create_cylinder_line(y0, y1, radius, segs, target, parentmat)
  local length = y1 - y0
  local center = (y0 + y1) / 2.0

  local data = cylinder.cylinder_data(radius, length, segs, true)
  geoutils.compute_normals(data)
  local offset = math.Vector(0.0, center, 0.0)
  local mat = math.Matrix4():translation(offset)
  mat:left_multiply(parentmat)
  table.insert(target, {data, mat})
end

function m.axis_widget_data(scale, length, segments)
  scale = scale or 1.0
  segments = segments or 12
  local radius = scale * 0.02
  length = length or scale

  local q = math.Quaternion()
  local p = math.Vector():zero()

  local rotations = {{0,0,-math.pi/2}, {0,0,0}, {math.pi/2,0,0}}
  local bsize = scale * 0.1
  local lines = {
    {{-length*0.25, length}},
    {{-length*0.25, length-bsize*2}, {length-bsize, length}},
    {{-length*0.25, length-bsize*4}, {length-bsize*3,length-bsize*2}, {length-bsize, length}}
  }

  local components = {}

  for i = 1,3 do
    q:euler(rotations[i])
    local mat = math.Matrix4():compose(p, q)
    for _,s in ipairs(lines[i]) do
        m.create_cylinder_line(s[1], s[2], radius, segments, components, mat)
    end
  end

  return geoutils.merge_data(components, {"position", "normal"})
end

function m.axis_widget_geo(gname, scale, length, segments)
    return geoutils.to_basic_geo(gname, m.axis_widget_data(scale, length, segments))
end

return m
