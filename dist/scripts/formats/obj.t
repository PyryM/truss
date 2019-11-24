-- formats/obj.t
--
-- reads/writes wavefront .obj files

local class = require("class")
local m = {}

m.verbose = false

function m.load_obj(filename, invert)
  local starttime = truss.tic()
  local src_message = truss.C.load_file(filename)
  if src_message == nil then
    log.error("Error: unable to open file " .. filename)
    return nil
  end

  local srcstr = ffi.string(src_message.data, src_message.data_length)
  local ret = m.parse_obj(srcstr, invert)
  truss.C.release_message(src_message)
  local dtime = truss.toc(starttime)
  log.info("Loaded " .. filename .. " in " .. (dtime*1000.0) .. " ms")
  return ret
end

m.load = m.load_obj

-- implementation details

local strfind = string.find
local tinsert = table.insert
local strsub = string.sub

local stringutils = require("utils/stringutils.t")
local strsplit = stringutils.split

local function is_comment(linegps)
  local firstChar = strsub(linegps[1], 1, 1)
  return firstChar == "#"
end

local attribute_table = {["v"] = "positions",
                        ["vn"] = "normals",
                        ["vt"] = "uvs",
                        ["vp"] = "pspaces"}

local function is_attribute(linegps)
  local g1 = linegps[1]
  return attribute_table[g1] ~= nil
end

local function parse_attribute(linegps, attribs)
  local atype = attribute_table[linegps[1]]
  local aval = {}
  for i = 2,#linegps do
      aval[i-1] = tonumber(linegps[i])
  end
  if attribs[atype] == nil then attribs[atype] = {} end
  tinsert(attribs[atype], aval)
end

local function is_face(linegps)
  if #linegps == 5 and linegps[1] == "f" then --QUAD!!!!
    m.quadcount = m.quadcount + 1
    return false
  end
  return #linegps == 4 and linegps[1] == "f"
end

local function parse_face(linegps, rawfaces)
  tinsert(rawfaces, {linegps[2], linegps[3], linegps[4]})
end

local function parse_index(idxstr)
  local gps = strsplit("/", idxstr)
  local ret = {}
  local ngps = #gps
  for i = 1,ngps do
    if #(gps[i]) > 0 then
      ret[i] = tonumber(gps[i])
    end
  end
  -- can't use unpack(ret) because ret[2] might be nil
  -- in a .obj with normals but not uvs, and unpack uses
  -- the length (which breaks on embedded nils)
  -- to determine how many values to unpack
  return ret[1],ret[2],ret[3]
end

-- reindex_vertices(rawfaces) --> indexedfaces, vertexlist
--
-- since an obj file may specify different indices for a
-- face's position, normals, and uvs, this function resolves
-- these into unified vertex indices where each index corresponds
-- to a single position, normal, uv.
function m.reindex_vertices(rawfaces)
  local vtable = {}
  local vindex = 0
  local vertexlist = {}

  local function resolve_vertex(vstr)
    if vtable[vstr] == nil then
      vtable[vstr] = vindex
      tinsert(vertexlist, vstr)
      vindex = vindex + 1
    end
    return vtable[vstr]
  end

  local indexedfaces = {}
  local nfaces = #rawfaces
  for f = 1,nfaces do
    local cf = rawfaces[f]
    local nf = {resolve_vertex(cf[1]),
                resolve_vertex(cf[2]),
                resolve_vertex(cf[3])}
    indexedfaces[f] = nf
  end

  return indexedfaces, vertexlist
end

-- gather_vertices(vertexlist, posList, texList, normalList)
--                 --> {positions=, uvs=, normals=}
--
-- takes in the vertex list, where each vertex is a string like
-- "3/4/5" and pulls pos[3], uvs[4] and normals[5] and adds them
-- to the appropriate position, uv, and normal lists
function m.gather_vertices(vertexlist, posList, texList, normalList)
  local nvertices = #vertexlist
  local positions, uvs, normals = {}, {}, {}
  for i = 1,nvertices do
    local posIndex, texIndex, normalIndex = parse_index(vertexlist[i])
    if posIndex    then positions[i] =    posList[posIndex]    end
    if texIndex    then uvs[i]       =    texList[texIndex]    end
    if normalIndex then normals[i]   = normalList[normalIndex] end
  end
  return {position = positions, texcoord0 = uvs, normal = normals}
end

function m.parse_obj(objstring, invert)
  local lines = stringutils.split_lines(objstring) -- TODO: fix stringutils
  local nlines = #lines
  local attributes = {}
  local rawfaces = {}
  local strip = stringutils.strip

  -- read in raw data
  m.quadcount = 0
  for i = 1,nlines do
    local curline = strip(lines[i])
    local gps = strsplit("%s+", curline)
    if not is_comment(gps) then
      if is_attribute(gps) then
        parse_attribute(gps, attributes)
      elseif is_face(gps) then
        parse_face(gps, rawfaces)
      elseif m.verbose then -- wasn't attribute or face, so what is it?
        log.error("objloader: couldn't parse line [" .. curline .. "]")
      end
    end
  end
  if m.quadcount > 0 then
    log.warn("Warning: model contained " .. m.quadcount
                .. " quads, which were ignored!")
  end

  if m.verbose then
    log.debug("#raw faces: " .. #rawfaces)
    log.debug("#raw positions: " .. #(attributes.positions or {}))
    log.debug("#raw uvs: " .. #(attributes.uvs or {}))
    log.debug("#raw normals: " .. #(attributes.normals or {}))
  end

  -- unify vertices
  local faces, vertexlist = m.reindex_vertices(rawfaces)

  -- produce attribute lists
  local attr = m.gather_vertices(vertexlist, attributes.positions or {},
                                             attributes.uvs or {},
                                             attributes.normals or {})

  -- add in face index list
  local ret = {
    indices = faces,
    attributes = attr
  }
  if #(attr.normal) == 0 then attr.normal = nil end
  if #(attr.texcoord0) == 0 then attr.texcoord0 = nil end

  if m.verbose then
    log.debug("#triangles (faces): " .. #ret.indices)
    log.debug("#vertices: " .. #(attr.position or {}))
    log.debug("#normals: " .. #(attr.normal or {}))
    log.debug("#uvs: " .. #(attr.texcoord0 or {}))
  end

  return ret
end

local ObjDumper = class("ObjDumper")
function ObjDumper:init()
  self.v = {}
  self.vn = {}
  self.vt = {}
  self.f = {}
end

function ObjDumper:_push_attr(aname, x, y, z)
  if z then
    table.insert(self[aname], ("%s %f %f %f"):format(aname, x, y, z))
  else
    table.insert(self[aname], ("%s %f %f"):format(aname, x, y))
  end
end

function ObjDumper:_push_attr_var(aname, aval)
  if aval.elem then -- vector
    aval = aval.elem
  end
  if aval.x then -- {x = , y =, z =} table
    self:_push_attr(aname, aval.x, aval.y, aval.z)
  else -- assume array
    self:_push_attr(aname, aval[1], aval[2], aval[3])
  end
end

function ObjDumper:push_vert(v, vt, vn)
  if v.position then -- compiled vertex type
    self:_push_attr("v", v.position[0], v.position[1], v.position[2])
    if v.normal then
      self:_push_attr("vn", v.normal[0], v.normal[1], v.normal[2])
    end
    if v.texcoord0 then
      self:_push_attr("vt", v.texcoord0[0], v.texcoord0[1])
    end
  else
    self:_push_attr_var("v", v)
    self:_push_attr_var("vn", v)
    self:_push_attr_var("vt", v)
  end
end

function ObjDumper:push_face(i1, i2, i3)
  if type(i1) == "table" then
    return self:push_face(unpack(i1))
  end
  if not self.face_format then
    local ff = "%d"
    if #self.vn > 0 or #self.vt > 0 then
      if #self.vt > 0 then
        ff = ff .. "/%d"
      else
        ff = ff .. "/"
      end
      if #self.vn > 0 then
        ff = ff .. "/%d"
      end
    end
    self.face_format = ff
  end
  local ff = self.face_format
  i1 = i1 + 1 -- obj format is 1-indexed
  i2 = i2 + 1
  i3 = i3 + 1
  local s1 = ff:format(i1,i1,i1)
  local s2 = ff:format(i2,i2,i2)
  local s3 = ff:format(i3,i3,i3)
  table.insert(self.f, ("f %s %s %s"):format(s1, s2, s3))
end

function ObjDumper:dump()
  local vcount = #self.v
  if #self.vn > 0 and #self.vn ~= vcount then
    truss.error("Vertex count mismatch: v: ", vcount, " vn: ", #self.vn)
  end
  if #self.vt > 0 and #self.vt ~= vcount then
    truss.error("Vertex count mismatch: v: ", vcount, " vt: ", #self.vt)
  end
  local ret = table.concat(self.v, "\n")
  ret = ret .. "\n" .. table.concat(self.vt, "\n")
  ret = ret .. "\n" .. table.concat(self.vn, "\n")
  ret = ret .. "\n" .. table.concat(self.f, "\n")
  return ret
end

local gexport = require("./geoexport.t")

function m.dump(geo)
  return gexport.dump(geo, ObjDumper())
end

function m.save(filename, geo)
  return gexport.save(filename, geo, ObjDumper())
end

return m
