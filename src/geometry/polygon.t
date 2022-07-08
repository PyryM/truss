-- geometry/polygon.t
--
-- planar polygon stuff

local math = require("math")

local m = {}

local p0_to_p1 = math.Vector()
local p1_to_p2 = math.Vector()
local conv = math.Vector()

local function _convexity(pts, npts, idx)
  local p0 = pts[((idx-1) % npts) + 1]
  local p1 = pts[idx + 1]
  local p2 = pts[((idx+1) % npts) + 1]
  p0_to_p1:sub(p1, p0)
  p1_to_p2:sub(p2, p1)
  conv:cross(p0_to_p1, p1_to_p2)
  return conv.elem.z
end

local function _clip_ear(pts, index_map)
  local npts = #pts
  local convs = {}
  for i = 0, npts-1 do convs[i] = _convexity(pts, npts, i) end
  for i = 0, npts-1 do
    local concave_neighbor = convs[(i-1) % npts] < 0 or convs[(i+1) % npts] < 0
    if convs[i] > 0.0 and concave_neighbor then
      local p0 = index_map[pts[((i-1) % npts) + 1]]
      local p1 = index_map[pts[i+1]]
      local p2 = index_map[pts[((i+1) % npts) + 1]]
      table.remove(pts, i+1)
      return {p0, p1, p2}
    end
  end
end

local function _make_fan(target, pts, index_map)
  local npts = #pts
  for i = 1,npts-2 do
    table.insert(target, {index_map[pts[1]],
                           index_map[pts[i+1]],
                           index_map[pts[i+2]]})
  end
end

-- returns a list of indices that triangulate the pts
function m.triangulate(pts)
  local indices = {}

  local index_map = {}
  local remaining_pts = {}
  for idx, pt in ipairs(pts) do
    index_map[pt] = idx-1
    remaining_pts[idx] = pt
  end

  while #remaining_pts > 3 do
    local ear_tri = _clip_ear(remaining_pts, index_map)
    if not ear_tri then break end
    table.insert(indices, ear_tri)
  end

  _make_fan(indices, remaining_pts, index_map)

  return indices
end

function m.polygon_data(opts)
  local indices = m.triangulate(opts.pts)
  return {attributes = {position = opts.pts}, indices = indices}
end

m._geometries = {polygon = m.polygon_data}

return m
