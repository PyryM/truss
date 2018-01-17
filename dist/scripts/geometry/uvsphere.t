-- geometry/uvsphere.t
--
-- creates "UV" (lat/lon) spheres

local m = {}

local math = require("math")
local Vector = math.Vector

-- the "plate carree" projection, a special case of equirectangular
function m.plate_carree(lat, lon)
  local u = 1.0 - (lon / (2*math.pi)) -- map [0,2pi]     => [1,0]
  local v = lat / math.pi + 0.5     -- map [-pi/2,pi/2] => [0,1]
  return u,v
end

function m.sphere_to_cartesian(lat, lon, rad)
  local x = rad * math.cos(lat) * math.cos(lon)
  local y = rad * math.sin(lat)
  local z = rad * math.cos(lat) * math.sin(lon)
  return x, y, z
end

function m.uvsphere_data(options)
  options = options or {}
  local projfunc = options.projfunc or m.plate_carree
  local rad = options.rad or 1.0
  local lat_divs = (options.lat_divs or 10) + 1
  local lon_divs = (options.lon_divs or 10) + 1
  local cap_size = options.cap_size or (5.0 * math.pi/180.0)

  local lon_start = 0.0
  local lon_end   = math.pi * 2.0

  local lat_start = -((math.pi / 2.0) - cap_size)
  local lat_end   =   (math.pi / 2.0) - cap_size

  local d_lon = (lon_end - lon_start) / (lon_divs-1)
  local d_lat = (lat_end - lat_start) / (lat_divs-1)

  local indices = {}

  -- insert cap vertices
  local positions = {Vector(0,1,0), Vector(0,-1,0)}
  local normals = {Vector(0,1,0), Vector(0,-1,0)}
  local uvs = {Vector(0.5, 1), Vector(0.5, 0)} -- not correct, swirls at poles

  -- create remaining vertices
  for lat_idx = 1, lat_divs do
    for lon_idx = 1, lon_divs do
      local lat = lat_start + (lat_idx-1)*d_lat
      local lon = lon_start + (lon_idx-1)*d_lon
      local x,y,z = m.sphere_to_cartesian(lat, lon, rad)
      local u,v = projfunc(lat, lon)
      u = u * (options.u_mult or 1)
      v = v * (options.v_mult or 1)
      table.insert(positions, Vector(x,y,z))
      table.insert(normals, Vector(x,y,z):normalize())
      table.insert(uvs, Vector(u, v))
    end
  end

  local function get_vertex_indices(lat_idx, lon_idx)
    local v0 = (lat_idx-1)*lon_divs + (lon_idx-1) + 2
    local v1 = v0 + 1
    local v2 = v0 + lon_divs
    local v3 = v2 + 1
    return v0,v1,v2,v3
  end

  -- create 'body' triangles
  for lat_idx = 1, lat_divs-1 do
    for lon_idx = 1, lon_divs-1 do
      local v0,v1,v2,v3 = get_vertex_indices(lat_idx, lon_idx)
      table.insert(indices, {v0, v2, v1})
      table.insert(indices, {v1, v2, v3})
    end
  end

  -- create 'cap' triangles
  for lon_idx = 1, lon_divs-1 do
    local v0 = (lon_idx-1) + 2
    table.insert(indices, {v0, v0+1, 1})
    local v0 = lon_divs*(lat_divs-1) + (lon_idx-1) + 2
    table.insert(indices, {v0, 0, v0+1})
  end


  return {indices = indices, attributes = {position = positions,
                                           normal = normals,
                                           texcoord0 = uvs}}
end

m._geometries = {uvsphere = m.uvsphere_data}

return m
