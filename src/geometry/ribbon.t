-- geometry/ribbon.t
--
-- create ribbons and derivatives

local math = require("math")
local m = {}

local function to_vector(v)
  if v.elem then return v:clone() else return math.Vector(unpack(v)) end
end

function m.ribbon_data(options)
  if options.points then
    truss.error("Creating a ribbon from a single list of points not implemented yet.")
  end
  local position = {}
  local texcoord0 = {}
  local indices = {}
  local inner, outer = options.inner_points, options.outer_points
  local npts = #inner
  if #outer ~= npts then
    truss.error("Inner/outer point list size mismatch: " .. 
                #inner .. " vs. " .. #outer)
  end
  for src_idx = 1, npts do
    local u = (src_idx-1) / (npts-1)
    table.insert(position, to_vector(inner[src_idx]))
    table.insert(position, to_vector(outer[src_idx]))
    table.insert(texcoord0, math.Vector(u, 0.0))
    table.insert(texcoord0, math.Vector(u, 1.0))
  end
  for tri_idx = 0, npts-2 do
    local i0 = tri_idx*2
    table.insert(indices, {i0, i0+1, i0+2})
    table.insert(indices, {i0+1, i0+3, i0+2})
  end
  return {
    attributes = {position = position, texcoord0 = texcoord0},
    indices = indices
  }
end

function m.rectangle_frame_data(options)
  local outer_width = options.outer_width or options.width or 1
  local outer_height = options.outer_height or options.height or 1
  local thickness2 = (options.thickness or 0.1)*2
  local inner_width = options.inner_width or (outer_width - thickness2)
  local inner_height = options.inner_height or (outer_height - thickness2)
  local x_o, x_i = outer_width / 2, inner_width / 2
  local y_o, y_i = outer_height / 2, inner_height / 2
  return m.ribbon_data{
    outer_points = {
      {x_o, y_o}, {-x_o, y_o}, {-x_o, -y_o}, {x_o, -y_o}, {x_o, y_o}
    },
    inner_points = {
      {x_i, y_i}, {-x_i, y_i}, {-x_i, -y_i}, {x_i, -y_i}, {x_i, y_i}
    }
  }
end

m._geometries = {
  ribbon = m.ribbon_data, 
  rectangle_frame = m.rectangle_frame_data
}

return m