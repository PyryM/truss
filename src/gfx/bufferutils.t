-- bufferutils.t
--
-- utility functions for managing bgfx buffers

local m = {}
local vertexdefs = require("./vertexdefs.t")

local function assert_index_size(geo, n_indices)
  if geo.n_indices ~= n_indices then
    truss.error("Wrong number of indices, expected "
        .. (geo.n_indices or "nil")
        .. " got " .. (n_indices or "nil"))
  end
end

-- set_indices
--
-- sets face indices, checking whether the input is a list of lists
-- or a flat list
function m.set_indices(geo, indexdata, strict)
  if #indexdata == 0 then return end
  if type(indexdata[1]) == "table" then
    m.set_indices_list_of_lists(geo, indexdata, strict)
  else
    m.set_indices_flat_list(geo, indexdata, strict)
  end
end

function m.set_indices_strict(geo, indexdata)
  return m.set_indices(geo, indexdata, true)
end

-- set_indices_list_of_lists
--
-- sets face indices from a list of lists
-- e.g. {{0,1,2}, {1,2,3}, {3,4,5}, {5,2,1}}
function m.set_indices_list_of_lists(geo, facelist, strict)
  local nfaces = #facelist
  local nindices = nfaces * 3 -- assume triangles
  if strict then assert_index_size(geo, nindices) end
  nfaces = math.floor(math.min(nfaces, geo.n_indices / 3))

  local dest = geo.indices
  local dest_idx = 0
  for f = 1, nfaces do
    dest[dest_idx]     = facelist[f][1] or 0
    dest[dest_idx + 1] = facelist[f][2] or 0
    dest[dest_idx + 2] = facelist[f][3] or 0
    dest_idx = dest_idx + 3
  end
end

-- set_indices_flat_list
--
-- set face indices from a flat list (spacing to indicate triangles)
-- e.g., {0,1,2,  1,2,3,  3,4,5,  5,2,1}
function m.set_indices_flat_list(geo, indexlist, strict)
  local nindices = #indexlist
  if strict then assert_index_size(geo, nindices) end
  nindices = math.min(nindices, geo.n_indices)

  local dest = geo.indices
  for idx = 1, nindices do
    dest[idx - 1] = indexlist[idx] or 0
  end
end

-- make_list_setter
--
-- makes a function to set an attribute from a list
local function make_list_setter(attribname, nvals)
  if nvals > 1 then
    return function(vertex, attrib_val)
      local tgt = vertex[attribname]
      for i = 1,nvals do
        -- the attribute is C-style struct and so zero indexed
        tgt[i-1] = attrib_val[i]
      end
    end
  else -- nvals == 1
    return function(vdata, vindex, attrib_val)
      vertex[attribname] = attrib_val
    end
  end
end

-- make_vector_setter
--
-- make a function to set an attribute from a math.Vector
local function make_vector_setter(attribname, nvals)
  local keys = {"x", "y", "z", "w"}
  return function(vertex, attrib_val)
    local tgt = vertex[attribname]
    local src = attrib_val.elem
    for i = 1,nvals do
      -- the attribute is C-style struct and so zero indexed
      tgt[i-1] = src[keys[i]]
    end
  end
end

-- populate setter list
local setters = {}
for attrib_name, _ in pairs(vertexdefs.ATTRIBUTE_INFO) do
  setters[attrib_name .. "_F"] = make_list_setter(attrib_name, 1)
  for i = 1,4 do
    setters[attrib_name .. "_L" .. i] = make_list_setter(attrib_name, i)
    setters[attrib_name .. "_V" .. i] = make_vector_setter(attrib_name, i)
  end
end

function m.get_setter(target, attrib_name, attrib_list)
  -- figure out how many elements the target has for the attribute
  -- (e.g., 3 element colors [rgb] vs. 4 element color [rgba])
  local datanum = target.vertinfo.attributes[attrib_name]
  if datanum == nil then return end

  -- determine what setter to use based on the src list
  -- (assume list is homogeneous: probably unsafe but :effort:)
  local setter_tag = ""
  local src1 = attrib_list[1]
  if type(src1) == "number" then -- list of numbers
    setter_tag = attrib_name .. "_F"
  elseif src1.elem then          -- list of Vectors
    setter_tag = attrib_name .. "_V" .. datanum
  else                           -- list of lists
    setter_tag = attrib_name .. "_L" .. datanum
  end
  local setter = setters[setter_tag]

  if setter == nil then
    log.error("Could not find setter for attribute type " .. setter_tag)
    return nil
  end

  return setter
end

function m.set_attribute(target, attrib_name, attrib_list, setter)
  local list_size = math.min(#attrib_list, target.n_verts)

  setter = setter or m.get_setter(target, attrib_name, attrib_list)
  if not setter then truss.error("No setter for attribute " .. attrib_name) end

  -- actually set the data
  if not target.verts then truss.error("Target not allocated.") end
  local dest = target.verts
  for v = 1, list_size do
    -- dest (data.verts) is a C-style array so zero indexed
    setter(dest[v-1], attrib_list[v])
  end
end

function m.set_attribute_strict(target, attrib_name, attrib_list, setter)
  local list_size = #attrib_list
  if list_size == 0 then
    log.warn("set_attribute with #attrib_list == 0 does nothing")
    return
  elseif list_size ~= target.n_verts then
    truss.error("set_attribute: wrong number of vertices, expected "
        .. (target.n_verts or "nil?")
        .. " got " .. (list_size or "nil"))
    return
  end
  return m.set_attribute(target, attrib_name, attrib_list, setter)
end

return m
