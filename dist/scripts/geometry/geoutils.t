-- geoutils.t
--
-- various geometry utilities

local m = {}
local Vector = require("math").Vector

local function get_random_color(vertex)
  local rand = math.random
  return Vector(rand()*255, rand()*255, rand()*255)
end

-- assigns random colors to all the vertices, in place
-- any existing colors are discarded
function m.color_randomly(srcdata)
  local attr = srcdata.attributes
  attr.color0 = m.map_attribute(attr.position, get_random_color)
  return srcdata
end

local function rgb_stride(index, vertex)
  local i = ((index-1) % 3)+1
  local c = {0, 0, 0, 0}
  c[i] = 255
  return Vector():from_array(c)
end

-- color each triangle with one vertex R, one G, and one B
-- assumes data is a triangle soup
function m.color_rgb_triangles(srcdata, destattr)
  srcdata.attributes[destattr or "color0"] =
    m.map_indexed_attribute(srcdata.attributes.position, rgb_stride)
end

local function normalize_vertex(v, rad)
  v:normalize():multiply(rad)
end

-- projects the positions of the srcdata in place onto a sphere
function m.spherize(srcdata, radius)
  m.map_attribute(srcdata.attributes.position, normalize_vertex, radius)
end

local function canonize_vertex(v, precision)
  local p = precision
  if v.elem then -- is a Vector
    local n = v.elem
    return tostring(math.floor(n.x * p) / p) ..
      "_" .. tostring(math.floor(n.y * p) / p) ..
      "_" .. tostring(math.floor(n.z * p) / p)
  else -- is a normal list
    return tostring(math.floor(v[1] * p) / p) ..
      "_" .. tostring(math.floor(v[2] * p) / p) ..
      "_" .. tostring(math.floor(v[3] * p) / p)
  end
end

local function convert_index(idx, vtable)
  if type(idx) == "number" then
    return vtable[idx]
  else
    return {vtable[idx[1]], vtable[idx[2]], vtable[idx[3]]}
  end
end

-- combines duplicate vertices; attributes other than positions are
-- discarded
function m.combine_duplicate_vertices(srcdata, precision)
  local vtable = {}
  local ctable = {}

  -- first, hash (bin) all the vertex positions together and renumber
  -- vertices
  local nextVIdx = 0
  local newpositions = {}
  local positions = srcdata.attributes.position
  for i, v in ipairs(positions) do
    local str_pos = canonize_vertex(v)
    local new_vid = ctable[str_pos]
    if not new_vid then
      new_vid = nextVIdx
      nextVIdx = nextVIdx + 1
      table.insert(newpositions, v)
      ctable[str_pos] = new_vid
    end
    vtable[i-1] = new_vid
  end

  -- now reindex indices
  local newindices = {}
  for _, i in ipairs(srcdata.indices) do
    table.insert(newindices, convert_index(i, vtable))
  end

  -- return updated data
  return {
    indices = newindices,
    attributes = {
      position = newpositions
    }
  }
end

local function remap_vertex(idx, remap_list, nextidx, vtable)
  local strid = tostring(idx)
  local remapped_idx = vtable[strid]
  if remapped_idx then
    return remapped_idx, nextidx
  end
  remap_list[nextidx+1] = idx+1
  vtable[strid] = nextidx
  return nextidx, nextidx+1
end

local function remap_midpoint(idx1, idx2, remap_list, nextidx, vtable)
  if idx1 > idx2 then
    idx1, idx2 = idx2, idx1
  end
  local strid = idx1 .. "|" .. idx2
  local remapped_idx = vtable[strid]
  if remapped_idx then
    return remapped_idx, nextidx
  end
  remap_list[nextidx+1] = {idx1+1, idx2+1}
  vtable[strid] = nextidx
  return nextidx, nextidx+1
end

local function resolve_remap_list(src_attributes, remap_list)
  local ret = {}
  for attr_name, src in pairs(src_attributes) do
    local dest = {}
    for idx, op in ipairs(remap_list) do
      if type(op) == "number" then
        dest[idx] = src[op]
      else 
        local idx1, idx2 = unpack(op)
        dest[idx] = Vector():add(src[idx1], src[idx2]):multiply(0.5)
      end
    end
    ret[attr_name] = dest
  end
  return ret
end

-- does a single subdivision of each triangular face of the data
-- assumes indices in list-of-lists format
function m._subdivide(srcdata)
  local newindices = {}
  local remap_list = {}
  local vtable = {}

  local nextidx = 0
  for _, face in ipairs(srcdata.indices) do
    local i0, i1, i2, i01, i02, i12
    i0, nextidx = remap_vertex(face[1], remap_list, nextidx, vtable)
    i1, nextidx = remap_vertex(face[2], remap_list, nextidx, vtable)
    i2, nextidx = remap_vertex(face[3], remap_list, nextidx, vtable)
    i01, nextidx = remap_midpoint(face[1], face[2], remap_list, nextidx, vtable)
    i02, nextidx = remap_midpoint(face[1], face[3], remap_list, nextidx, vtable)
    i12, nextidx = remap_midpoint(face[2], face[3], remap_list, nextidx, vtable)
    table.insert(newindices, {i0, i01, i02})
    table.insert(newindices, {i01, i1, i12})
    table.insert(newindices, {i02, i12, i2})
    table.insert(newindices, {i01, i12, i02})
  end

  return {
    indices = newindices,
    attributes = resolve_remap_list(srcdata.attributes, remap_list)
  }
end

function m.subdivide(data, rounds)
  for i = 1, (rounds or 1) do data = m._subdivide(data) end
  return data
end

function m.map_attribute(data, f, arg)
  local ret = {}
  for i,v in ipairs(data) do
    ret[i] = f(v, arg)
  end
  return ret
end

function m.map_indexed_attribute(data, f, arg)
  local ret = {}
  for i,v in ipairs(data) do
    ret[i] = f(i, v, arg)
  end
  return ret
end

-- computes normals for data, modifying srcdata in place to add
-- srcdata.attributes.normal
function m.compute_normals(srcdata)
  local tempV0 = Vector()
  local tempV1 = Vector()
  local tempN  = Vector()

  local normals = {}
  for i, _ in ipairs(srcdata.attributes.position) do
    normals[i] = Vector():zero()
  end

  -- Compute face normals and sum into the 3 vertices of each face
  local idxs = srcdata.indices
  local ps = srcdata.attributes.position
  local nfaces = #idxs
  for i = 1, nfaces do
    local f = idxs[i]
    local idx0 = f[1]+1
    local idx1 = f[2]+1
    local idx2 = f[3]+1
    tempV0:sub(ps[idx1], ps[idx0])
    tempV1:sub(ps[idx2], ps[idx0])
    tempN:cross(tempV0, tempV1):normalize()
    tempN.elem.w = 1.0 -- use w component to track denominator of average
    normals[idx0]:add(tempN)
    normals[idx1]:add(tempN)
    normals[idx2]:add(tempN)
  end

  -- Average the vertex normals by dividing by the sum (in w)
  for _, v in ipairs(normals) do
    v:divide(math.max(v.elem.w, 1))
    v.elem.w = 0.0
    v:normalize()
  end

  srcdata.attributes.normal = normals
  return srcdata
end

local function push_tri_verts(src, dest, tri)
  table.insert(dest, src[tri[1]+1]:clone())
  table.insert(dest, src[tri[2]+1]:clone())
  table.insert(dest, src[tri[3]+1]:clone())
end

-- splits indexed triangles into a 'triangle soup' so that no triangles share
-- vertices
function m.split_triangles(data)
  local ret = {indices = {}, attributes = {}}
  -- split attributes
  for name, attr in pairs(data.attributes) do
    local dest = {}
    for idx, tri in ipairs(data.indices) do
      push_tri_verts(attr, dest, tri)
    end
    ret.attributes[name] = dest
  end
  -- renumber vertices
  local pos = 0
  for i = 1,#(data.indices) do
    table.insert(ret.indices, {pos, pos+1, pos+2})
    pos = pos + 3
  end
  return ret
end

-- merge geometry data together into a single data block
-- input: a list of {geometryData, mat4 pose} lists
function m.merge_data(datalist, attributes)
  local ret = {indices = {}, attributes = {}}
  for _,v in ipairs(attributes) do ret.attributes[v] = {} end

  local offset = 0
  for _, v in ipairs(datalist) do
    local data, pose = v[1], v[2]
    local nverts = #(data.attributes.position)
    -- copy attributes (assume vector attributes)
    for attr_name, vertex_list in pairs(ret.attributes) do
      local src_attr = data.attributes[attr_name]
      local ntarget = (src_attr ~= nil) and #(src_attr)
      if ntarget ~= nverts then
        truss.error("geometryutils.merge_data: attribute " .. attr_name ..
              " expected " .. nverts .. ", had " .. tostring(ntarget))
        return nil
      end
      for _, v in ipairs(src_attr) do
        local new_v = Vector():copy(v)
        if pose[attr_name] then
          if attr_name == "position" then 
            new_v.elem.w = 1.0 
          else -- direction vector
            new_v.elem.w = 0.0 
          end
          pose:multiply_vector(new_v)
        end
        table.insert(vertex_list, new_v)
      end
    end
    -- copy indices (assume list-of-lists format)
    for _,triangle in ipairs(data.indices) do
      local s0,s1,s2 = triangle[1], triangle[2], triangle[3]
      local i0,i1,i2 = s0+offset, s1+offset, s2+offset
      table.insert(ret.indices, {i0, i1, i2})
    end
    offset = offset + nverts
  end
  return ret
end

-- create a convex hull from a list of points
--
-- warning: current implementation is brute force, takes O(n^4)
-- warning: current implementation does not handle non triangular faces
function m.convex_hull(pts)
  local temp_normal = Vector()
  local temp_v1 = Vector()
  local temp_v2 = Vector()
  -- test whether all points are on the same side of a given face
  -- if so, return the sign of the side they're on
  local function test_face(i, j, k)
    temp_v1:sub(pts[i], pts[j])
    temp_v2:sub(pts[i], pts[k])
    temp_normal:cross(temp_v1, temp_v2)
    -- test sign of (candidate - pts[i]) \cdot temp_normal
    -- => candidate \cdot temp_normal - (pts[i] \cdot temp_normal)
    local dd = pts[i]:dot(temp_normal)
    local sign = nil

    for idx, candidate in ipairs(pts) do
      if idx ~= i and idx ~= j and idx ~= k then
        local diff = candidate:dot(temp_normal) - dd
        if sign and sign * diff < 0 then 
          return false 
        end
        sign = diff
      end
    end
    return sign
  end

  local data = {
    attributes = {position = {}},
    indices = {}
  }
  local vmap = {}
  local function push_vertex(i)
    if vmap[i] then return vmap[i] end
    local idx = #(data.attributes.position)
    vmap[i] = idx
    table.insert(data.attributes.position, pts[i]:clone())
    return idx
  end
  local function push_face(i, j, k)
    local ni, nj, nk = push_vertex(i), push_vertex(j), push_vertex(k)
    table.insert(data.indices, {ni, nj, nk})
  end

  -- try all unordered choices of three points to make faces
  local npoints = #pts
  for i = 1, npoints - 2 do
    for j = i + 1, npoints - 1 do
      for k = j + 1, npoints do
        local sign = test_face(i, j, k)
        if sign and sign < 0 then -- determine face winding by sign
          push_face(i, j, k)
        elseif sign and sign > 0 then
          push_face(i, k, j)
        end
      end
    end
  end

  return data
end

function m.smooth(data, rounds, kernel)
  if not kernel then 
    kernel = 1.0
  end
  if type(kernel) == "number" then
    local gamma = kernel --*kernel
    kernel = function(d)
      return math.exp(-d*d / gamma)
    end
  end

  local p_src = data.attributes.position
  local p_dest = {}
  local tempv = Vector()
  local function accumulate_edge(i0, i1)
    local v0, v1 = p_src[i0], p_src[i1]
    local w = kernel(v0:distance3_to(v1))
    tempv:copy(v0):multiply(w)
    tempv.elem.w = w
    p_dest[i1]:add(tempv)
    tempv:copy(v1):multiply(w)
    tempv.elem.w = w
    p_dest[i0]:add(tempv)
  end
  for r = 1, rounds do
    for idx, v in ipairs(p_src) do 
      p_dest[idx] = (p_dest[idx] or Vector()):copy(p_src[idx])
      p_dest[idx].elem.w = 1 
    end
    for _, face in ipairs(data.indices) do
      accumulate_edge(face[1]+1, face[2]+1)
      accumulate_edge(face[2]+1, face[3]+1)
      accumulate_edge(face[3]+1, face[1]+1)
    end
    for _, v in ipairs(p_dest) do
      v:divide(v.elem.w)
    end
    p_src, p_dest = p_dest, p_src
  end
  data.attributes.position = p_src
  return data
end

return m
