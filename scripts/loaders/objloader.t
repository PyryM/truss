-- objloader.t
--
-- loads wavefront .obj files

local m = {}

m.verbose = false

function m.loadOBJ(filename, invert)
	local starttime = tic()
	local srcMessage = trss.trss_load_file(filename, 0)
	local srcstr = ffi.string(srcMessage.data, srcMessage.data_length)
	local ret = m.parseOBJ(srcstr, invert)
	trss.trss_release_message(srcMessage)
	local dtime = toc(starttime)
	trss.trss_log(0, "Loaded " .. filename .. " in " .. (dtime*1000.0) .. " ms")
	return ret
end

-- implementation details

local strfind = string.find
local tinsert = table.insert
local strsub = string.sub

local stringutils = truss_import("utils/stringutils.t")
local strsplit = stringutils.split

local function isComment(linegps)
	local firstChar = strsub(linegps[1], 1, 1)
	return firstChar == "#"
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
  return unpack(ret)
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
    if posIndex    then positions[i] =    posList[posIndex+1])    end
    if texIndex    then uvs[i]       =    texList[texIndex+1])    end
    if normalIndex then normals[i]   = normalList[normalIndex+1]) end
  end
  return {positions = positions, uvs = uvs, normals = normals}
end

function m.parseOBJ(objstring, invert)
	local lines = splitLines(objstring)
  local nlines = #lines
  local attributes = {positions = {}, uvs = {}, normals = {}}
  local rawfaces = {}

  -- read in raw data
  for i = 1,nlines do
    local curline = lines[i]
    local gps = strsplit(curline)
    if not isComment(gps) then
      if isAttribute(gps) then
        parseAttribute(gps, attributes)
      elseif isFace(gps) then
        parseFace(gps, rawfaces)
      elseif m.verbose then -- wasn't attribute or face, so what is it?
        log("objloader: couldn't parse line [" .. curline .. "]")
      end
    end
  end

  -- unify vertices
  local faces, vertexlist = m.reindexVertices(rawfaces)

  -- produce attribute lists
  local ret = m.gatherVertices(vertexlist, attributes.positions,
                                           attributes.uvs,
                                           attributes.normals)

  -- add in face index list
  ret.indices = faces
  ret.vertices = ret.positions -- aliased for reasons
  return ret
end