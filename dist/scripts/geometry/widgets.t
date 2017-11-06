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

  local data = cylinder.cylinder_data{radius = radius, 
                                      height = length, 
                                      segments = segs, 
                                      capped = true}
  geoutils.compute_normals(data)
  local offset = math.Vector(0.0, center, 0.0)
  local mat = math.Matrix4():translation(offset)
  mat:left_multiply(parentmat)
  table.insert(target, {data, {position = mat}})
end

function m.geo_from_rotated_lines(lines, positions, rotations, rad, segs)
  local components = {}
  local q0 = math.Quaternion():identity()
  local p0 = math.Vector():zero()

  for i = 1, #lines do
    local mat = math.Matrix4():compose(positions[i] or p0, rotations[i] or q0)
    for _, s in ipairs(lines[i]) do
        m.create_cylinder_line(s[1], s[2], rad, segs, components, mat)
    end
  end

  return geoutils.merge_data(components, {"position", "normal"})
end

function m.box_widget_data(opts)
  opts = opts or {}
  local side_length = opts.side_length or 1.0
  local radius = opts.radius or (side_length * 0.025)
  local gap_frac = opts.gap_frac or 0.5
  local segments = opts.segments or 6
  local hs = side_length / 2.0

  local Q = math.Quaternion
  local V = math.Vector
  local base_rotations = {Q():euler{0,0,-math.pi/2},
                          Q():euler{0,0,0},
                          Q():euler{math.pi/2,0,0}}
  local base_positions = {V(-hs, 0.0, -hs), V(hs, 0.0,  hs),
                          V(-hs, 0.0,  hs), V(hs, 0.0, -hs)}
  local base_lines
  local yp = hs + radius --/ 2.0
  if gap_frac > 0.0 then
    base_lines = {{-yp, -yp * gap_frac}, {yp * gap_frac, yp}}
  else
    base_lines = {{-yp, yp}}
  end

  local temp_mat = math.Matrix4():identity()

  local lines, rotations, positions = {}, {}, {}
  for _, r in ipairs(base_rotations) do
    for _, p in ipairs(base_positions) do
      table.insert(lines, base_lines)
      table.insert(rotations, r)
      temp_mat:from_quaternion(r)
      local p_rotated = p:clone()
      temp_mat:multiply_vector(p_rotated)
      table.insert(positions, p_rotated)
    end
  end

  return m.geo_from_rotated_lines(lines, positions, rotations, radius, segments)
end

function m.axis_widget_data(opts)
  opts = opts or {}
  local scale = opts.scale or 1.0
  local segments = opts.segments or 12
  local radius = scale * 0.02
  local length = opts.length or scale

  local Q = math.Quaternion
  local rotations = {Q():euler{0,0,-math.pi/2},
                     Q():euler{0,0,0},
                     Q():euler{math.pi/2,0,0}}
  local bsize = scale * 0.1
  local lines = {
    {{-length*0.25, length}},
    {{-length*0.25, length-bsize*2}, {length-bsize, length}},
    {{-length*0.25, length-bsize*4}, {length-bsize*3,length-bsize*2}, {length-bsize, length}}
  }

  return m.geo_from_rotated_lines(lines, {}, rotations, radius, segments)
end

m._geometries = {axis_widget = m.axis_widget_data, 
                 box_widget = m.box_widget_data}

return m
