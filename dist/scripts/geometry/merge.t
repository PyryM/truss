-- geometry/merge.t
--
-- utilities for merging geometries together

local class = require("class")
local math = require("math")
local m = {}

-- merge geometry data together into a single data block
-- input: a list of {geometryData, mat4 pose} lists
function m.merge_data(datalist, attributes)
  local ret = {indices = {}, attributes = {}}
  for _, v in ipairs(attributes) do ret.attributes[v] = {} end

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
        local new_v = v:clone()
        if pose[attr_name] then
          if attr_name == "position" then 
            new_v.elem.w = 1.0 
          else -- direction vector
            new_v.elem.w = 0.0 
          end
          pose[attr_name]:multiply(new_v)
        end
        table.insert(vertex_list, new_v)
      end
    end
    -- copy indices (assume list-of-lists format)
    for _,triangle in ipairs(data.indices) do
      local s0, s1, s2 = triangle[1], triangle[2], triangle[3]
      local i0, i1, i2 = s0+offset, s1+offset, s2+offset
      table.insert(ret.indices, {i0, i1, i2})
    end
    offset = offset + nverts
  end
  return ret
end

local v = math.Vector()
local transformers = {
  [0] = function(tf, p, fill)
    v:set(p[0], p[1], p[2], p[3])
    tf:multiply_vector(v)
    p[0], p[1], p[2], p[3] = v.elem.x, v.elem.y, v.elem.z, v.elem.w
  end,
  [1] = function(tf, p, fill)
    v:set(p[0], p[1], p[2], fill[1])
    tf:multiply_vector(v)
    p[0], p[1], p[2] = v.elem.x, v.elem.y, v.elem.z
  end,
  [2] = function(tf, p, fill)
    v:set(p[0], p[1], fill[1], fill[2])
    tf:multiply_vector(v)
    p[0], p[1] = v.elem.x, v.elem.y
  end,
  [3] = function(tf, p, fill)
    v:set(p[0], fill[1], fill[2], fill[3])
    tf:multiply_vector(v)
    p[0] = v.elem.x
  end
}

local function transform_verts(verts, start_vert, end_vert, attrib, tf, fill)
  local transformer = transformers[#(fill or {})]
  for idx = start_vert, end_vert - 1 do
    transformer(tf, verts[idx][attrib], fill)
  end
end

local function copy_verts(src, dest, destpos, n_verts)
  for idx = 0, n_verts - 1 do
    dest[destpos + idx] = src[idx]
  end
end

local function copy_offset_indices(src, dest, destpos, n_indices, offset)
  for idx = 0, n_indices - 1 do
    dest[destpos + idx] = src[idx] + offset
  end
end

-- all transforms are 4x4 matrices, but attributes may have 1-4 elements,
-- so need to fill in remaining elements with something
local function make_fill(attrib, fills, attrib_count)
  local fill = fills[attrib]
  local nfill = 4 - attrib_count -- have to fill in up to four values
  if not fill then
    fill = {}
    for i = 1, nfill do fill[i] = 0.0 end
  elseif fill and #fill ~= nfill then
    truss.error("gave " .. #fill .. " fill values for attrib " .. attrib
                .. " but needed " .. nfill)
  end
  return fill
end

local default_fills = {
  position = {1.0}, -- pad out positions with w = 1
  normal = {0.0}    -- pad out normals with w = 0
}

-- directly merge a list of {geometry, pose} pairs
-- all geometries must have the same vertex type 
function m.merge_geometries(geo_list, attribute_fills, output_type)
  if #geo_list == 0 then return nil end
  -- calculate output size and ensure all geometries have same vtype
  local vertinfo = geo_list[1][1].vertinfo
  local fills = {}
  for attrib, count in pairs(vertinfo.attributes) do
    fills[attrib] = make_fill(attrib, attribute_fills or default_fills, count)
  end
  local n_verts = 0
  local n_indices = 0
  for _, geo_pair in ipairs(geo_list) do
    n_verts = n_verts + geo_pair[1].n_verts
    n_indices = n_indices + geo_pair[1].n_indices
    if geo_pair[1].vertinfo ~= vertinfo then
      truss.error("Cannot merge different vertex types: " 
                  .. vertinfo.type_id .. " vs " 
                  .. geo_pair[1].vertinfo.type_id)
    end
  end

  local ret = (output_type or require("gfx").StaticGeometry)()
  ret:allocate(n_verts, n_indices, vertinfo)

  local n_written_indices = 0
  local n_written_verts = 0
  for _, geo_pair in ipairs(geo_list) do
    local geo, transforms = unpack(geo_pair)
    -- copy + transform vertices
    copy_verts(geo.verts, ret.verts, n_written_verts, geo.n_verts)
    for attrib, tf in pairs(transforms or {}) do
      transform_verts(ret.verts, n_written_verts, 
                      n_written_verts + geo.n_verts, 
                      attrib, tf, fills[attrib])
    end
    -- copy indices, offsetting by how many vertices the *previous* geos used
    copy_offset_indices(geo.indices, ret.indices, n_written_indices, 
                        geo.n_indices, n_written_verts)
    n_written_indices = n_written_indices + geo.n_indices
    n_written_verts = n_written_verts + geo.n_verts
  end

  ret:commit()
  return ret
end

function m.merge_tree(options)
  local mergelist = {}
  local filter = options.filter or function(ent)
    return ent.visible and (ent.mesh or {}).geo
  end
  for entity in options.root:iter_tree() do
    local geo = filter(entity)
    if geo then
      local m = entity.matrix_world or entity.matrix
      table.insert(mergelist, {geo, {position = m, normal = m}})
    end
  end

  return m.merge_geometries(mergelist, options.fill, options.geo_type)
end

-- a convenience class to avoid having to build geometries
-- in the real scenegraph to merge them
local Builder = class("Builder")
m.Builder = Builder

function Builder:init()
  self._ecs = require("ecs").ECS()
  self.root = self._ecs.scene
end

function Builder:build(options)
  -- update our own private scenegraph
  self.root:recursive_update_world_mat(math.Matrix4():identity(), true)
  options = options or {}
  options.root = self.root
  return m.merge_tree(options)
end

return m