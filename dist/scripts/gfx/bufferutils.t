-- bufferutils.t
--
-- utility functions for managing bgfx buffers

local m = {}
local vertexdefs = require("gfx/vertexdefs.t")

local function check_index_size_(geo, nindices)
  if geo.n_indices ~= nindices then
    truss.error("Wrong number of indices, expected "
        .. (geo.n_indices or "nil")
        .. " got " .. (nindices or "nil"))
    return false
  end
  return true
end

-- setIndices
--
-- sets face indices, checking whether the input is a list of lists
-- or a flat list
function m.set_indices(geo, indexdata)
  if #indexdata == 0 then return end
  if type(indexdata[1]) == "table" then
    m.set_indices_list_of_lists(geo, indexdata)
  else
    m.set_indices_flat_list(geo, indexdata)
  end
end

-- set_indices_list_of_lists
--
-- sets face indices from a list of lists
-- e.g. {{0,1,2}, {1,2,3}, {3,4,5}, {5,2,1}}
function m.set_indices_list_of_lists(geo, facelist)
  local nfaces = #facelist
  local nindices = nfaces * 3 -- assume triangles
  if not check_index_size_(geo, nindices) then return end

  local dest = geo.indices
  local destIndex = 0
  for f = 1,nfaces do
    dest[destIndex]   = facelist[f][1] or 0
    dest[destIndex+1] = facelist[f][2] or 0
    dest[destIndex+2] = facelist[f][3] or 0
    destIndex = destIndex + 3
  end
end

-- set_indices_flat_list
--
-- set face indices from a flat list (spacing to indicate triangles)
-- e.g., {0,1,2,  1,2,3,  3,4,5,  5,2,1}
function m.set_indices_flat_list(geo, indexlist)
  local nindices = #indexlist
  if not check_index_size_(geo, nindices) then return end

  local dest = geo.indices
  local destIndex = 0
  for idx = 1,nindices do
    dest[idx-1] = indexlist[idx] or 0
  end
end

-- make_list_setter
--
-- makes a function to set an attribute from a list
function m.make_list_setter(attribname, nvals)
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
function m.make_vector_setter(attribname, nvals)
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
m.setters = {}
for _, attrib_info in ipairs(vertexdefs.DefaultAttributeInfo) do
  local attrib_name = attrib_info[1]
  m.setters[attrib_name .. "_F"] = m.make_list_setter(attrib_name, 1)
  for i = 1,4 do
    m.setters[attrib_name .. "_L" .. i] = m.make_list_setter(attrib_name, i)
    m.setters[attrib_name .. "_V" .. i] = m.make_vector_setter(attrib_name, i)
  end
end

-- setter for when you just need random colors, ignores attribVal
m.setters.color0_RAND = function(vertex, attrib_val)
  vertex.color0[0] = math.random() * 255.0
  vertex.color0[1] = math.random() * 255.0
  vertex.color0[2] = math.random() * 255.0
  vertex.color0[3] = math.random() * 255.0
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
  local setter = m.setters[setter_tag]

  if setter == nil then
    log.error("Could not find setter for attribute type " .. setter_tag)
    return nil
  end

  return setter
end

function m.set_attribute(target, attrib_name, attrib_list, setter)
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

  setter = setter or m.get_setter(target, attrib_name, attrib_list)
  if not setter then truss.error("No setter for attribute " .. attrib_name) end

  -- actually set the data
  if not target.verts then truss.error("Target not allocated.") end
  local dest = target.verts
  for v = 1,list_size do
    -- dest (data.verts) is a C-style array so zero indexed
    setter(dest[v-1], attrib_list[v])
  end
end

return m
