-- objloader.t
--
-- loads wavefront .obj files

local m = {}

m.verbose = false

function m.loadOBJ(filename, invert)
	local starttime = tic()
	local srcMessage = trss.trss_load_file(filename, 0)
  if srcMessage == nil then 
    log.error("Error: unable to open file " .. filename)
    return nil 
  end

	local srcstr = ffi.string(srcMessage.data, srcMessage.data_length)
	local ret = m.parseOBJ(srcstr, invert)
	trss.trss_release_message(srcMessage)
	local dtime = toc(starttime)
	log.info("Loaded " .. filename .. " in " .. (dtime*1000.0) .. " ms")
	return ret
end

-- implementation details

local strfind = string.find
local tinsert = table.insert
local strsub = string.sub

local stringutils = require("utils/stringutils.t")
local strsplit = stringutils.split

local function isComment(linegps)
	local firstChar = strsub(linegps[1], 1, 1)
	return firstChar == "#"
end

local attributeTable = {["v"] = "positions",
                        ["vn"] = "normals",
                        ["vt"] = "uvs",
                        ["vp"] = "pspaces"}

local function isAttribute(linegps)
  local g1 = linegps[1]
  return attributeTable[g1] ~= nil
end

local function parseAttribute(linegps, attribs)
  local atype = attributeTable[linegps[1]]
  local aval = {}
  for i = 2,#linegps do
    aval[i-1] = tonumber(linegps[i])
  end
  if attribs[atype] == nil then attribs[atype] = {} end
  tinsert(attribs[atype], aval)
end

local function isFace(linegps)
  if #linegps == 5 and linegps[1] == "f" then --QUAD!!!!
    m.quadcount = m.quadcount + 1
    return false
  end
  return #linegps == 4 and linegps[1] == "f"
end

local function parseFace(linegps, rawfaces)
  tinsert(rawfaces, {linegps[2], linegps[3], linegps[4]})
end

local function parseIndex(idxstr)
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

-- reindexVertices(rawfaces) --> indexedfaces, vertexlist
--
-- since an obj file may specify different indices for a
-- face's position, normals, and uvs, this function resolves
-- these into unified vertex indices where each index corresponds
-- to a single position, normal, uv. 
function m.reindexVertices(rawfaces)
  local vtable = {}
  local vindex = 0
  local vertexlist = {}

  local function resolveVertex(vstr)
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
    local nf = {resolveVertex(cf[1]),
                resolveVertex(cf[2]),
                resolveVertex(cf[3])}
    indexedfaces[f] = nf
  end

  return indexedfaces, vertexlist
end

-- gatherVertices(vertexlist, posList, texList, normalList) 
--                 --> {positions=, uvs=, normals=}
--
-- takes in the vertex list, where each vertex is a string like
-- "3/4/5" and pulls pos[3], uvs[4] and normals[5] and adds them
-- to the appropriate position, uv, and normal lists
function m.gatherVertices(vertexlist, posList, texList, normalList)
  local nvertices = #vertexlist
  local positions, uvs, normals = {}, {}, {}
  for i = 1,nvertices do
    local posIndex, texIndex, normalIndex = parseIndex(vertexlist[i])
    if posIndex    then positions[i] =    posList[posIndex]    end
    if texIndex    then uvs[i]       =    texList[texIndex]    end
    if normalIndex then normals[i]   = normalList[normalIndex] end
  end
  return {positions = positions, uvs = uvs, normals = normals}
end

function m.parseOBJ(objstring, invert)
	local lines = stringutils.splitLines(objstring)
  local nlines = #lines
  local attributes = {}
  local rawfaces = {}
  local strip = stringutils.strip

  -- read in raw data
  m.quadcount = 0
  for i = 1,nlines do
    local curline = strip(lines[i])
    local gps = strsplit("%s+", curline)
    if not isComment(gps) then
      if isAttribute(gps) then
        parseAttribute(gps, attributes)
      elseif isFace(gps) then
        parseFace(gps, rawfaces)
      elseif m.verbose then -- wasn't attribute or face, so what is it?
        log.error("objloader: couldn't parse line [" .. curline .. "]")
      end
    end
  end
  if m.quadcount > 0 then
    log.warn("Warning: model contained " .. m.quadcount .. " quads, which were ignored!")
  end

  if m.verbose then
    log.debug("#raw faces: " .. #rawfaces)
    log.debug("#raw positions: " .. #(attributes.positions or {}))
    log.debug("#raw uvs: " .. #(attributes.uvs or {}))
    log.debug("#raw normals: " .. #(attributes.normals or {}))
  end

  -- unify vertices
  local faces, vertexlist = m.reindexVertices(rawfaces)

  -- produce attribute lists
  local ret = m.gatherVertices(vertexlist, attributes.positions or {},
                                           attributes.uvs or {},
                                           attributes.normals or {})

  -- add in face index list
  ret.indices = faces
  ret.vertices = ret.positions -- aliased for reasons
  if #(ret.normals) == 0 then ret.normals = nil end
  if #(ret.uvs) == 0 then ret.uvs = nil end

  if m.verbose then
    log.debug("#triangles (faces): " .. #ret.indices)
    log.debug("#vertices: " .. #(ret.vertices or {}))
    log.debug("#normals: " .. #(ret.normals or {}))
    log.debug("#uvs: " .. #(ret.uvs or {}))
  end

  return ret
end

return m