-- geoutils.t
--
-- various geometry utilities

local m = {}
local Vector = require("math").Vector

local function getRandomColor(vertex)
    local rand = math.random
    return Vector(rand()*255, rand()*255, rand()*255)
end

-- assigns random colors to all the vertices, in place
-- any existing colors are discarded
function m.colorRandomly(srcdata)
    local attr = srcdata.attributes
    attr.color0 = m.mapAttribute(attr.position, getRandomColor)
    return srcdata
end

local function normalizeVertex(v, rad)
    v:normalize():multiplyScalar(rad)
end

-- projects the positions of the srcdata in place onto a sphere
function m.spherize(srcdata, radius)
    m.mapAttribute(srcdata.attributes.position, normalizeVertex, radius)
end

local function canonizeVertex(v, precision)
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

local function convertIndex(idx, vtable)
    if type(idx) == "number" then
        return vtable[idx]
    else
        return {vtable[idx[1]], vtable[idx[2]], vtable[idx[3]]}
    end
end

-- combines duplicate vertices; attributes other than positions are
-- discarded
function m.combineDuplicateVertices(srcdata, precision)
    local vtable = {}
    local ctable = {}

    -- first, hash (bin) all the vertex positions together and renumber
    -- vertices
    local nextVIdx = 0
    local newpositions = {}
    local positions = srcdata.attributes.position
    for i, v in ipairs(positions) do
        local str_pos = canonizeVertex(v)
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
        table.insert(newindices, convertIndex(i, vtable))
    end

    -- return updated data
    return {
        indices = newindices,
        attributes = {
            position = newpositions
        }
    }
end

local function remapVertex(srcPositions, idx, newpositions, nextidx, vtable)
    local strid = tostring(idx)
    local remappedIdx = vtable[strid]
    if remappedIdx then 
        return remappedIdx, nextidx 
    end
    newpositions[nextidx+1] = srcPositions[idx+1]
    vtable[strid] = nextidx
    return nextidx, nextidx+1
end


local function remapMidpoint(srcPositions, idx1, idx2, newpositions, nextidx, vtable)
    if idx1 > idx2 then
        idx1, idx2 = idx2, idx1
    end
    local strid = idx1 .. "|" .. idx2
    local remappedIdx = vtable[strid]
    if remappedIdx then 
        return remappedIdx, nextidx 
    end
    local newvert = Vector()
    newvert:addVecs(srcPositions[idx1+1], srcPositions[idx2+1])
    newvert:multiplyScalar(0.5)
    newpositions[nextidx+1] = newvert
    vtable[strid] = nextidx
    return nextidx, nextidx+1
end

-- does a single subdivision of each triangular face of the data
-- assumes indices in list-of-lists format
-- only subdivides positions; other attributes are ignored
function m.subdivide(srcdata)
    local vtable = {}

    local newindices = {}
    local newpositions = {}
    
    local srcindices = srcdata.indices
    local positions = srcdata.attributes.position

    local nextidx = 0

    for _, face in ipairs(srcindices) do
        local i0, i1, i2, i01, i02, i12
        i0, nextidx = remapVertex(positions, face[1], newpositions, nextidx, vtable)
        i1, nextidx = remapVertex(positions, face[2], newpositions, nextidx, vtable)
        i2, nextidx = remapVertex(positions, face[3], newpositions, nextidx, vtable)
        i01, nextidx = remapMidpoint(positions, face[1], face[2], newpositions, nextidx, vtable)
        i02, nextidx = remapMidpoint(positions, face[1], face[3], newpositions, nextidx, vtable)
        i12, nextidx = remapMidpoint(positions, face[2], face[3], newpositions, nextidx, vtable)
        table.insert(newindices, {i0, i01, i02})
        table.insert(newindices, {i01, i1, i12})
        table.insert(newindices, {i02, i12, i2})
        table.insert(newindices, {i01, i12, i02})
    end

    return {
        indices = newindices,
        attributes = {
            position = newpositions
        }
    }
end

function m.mapAttribute(attribData, f, arg)
    local ret = {}
    for i,v in ipairs(attribData) do
        ret[i] = f(v, arg)
    end
    return ret
end

-- computes normals for data, modifying srcdata in place to add
-- srcdata.attributes.normal
function m.computeNormals(srcdata)
    local tempV0 = Vector()
    local tempV1 = Vector()
    local tempN  = Vector() 

    local normals = {}
    -- prepopulate normals
    for i, _ in ipairs(srcdata.attributes.position) do
        normals[i] = Vector():zero()
    end

    -- Compute face normals and sum into the 3 vertices of each face
    local idxs = srcdata.indices
    local ps = srcdata.attributes.position
    local nindices = #idxs
    for i = 1, nindices-2 do
        local idx0 = idxs[i  ]+1
        local idx1 = idxs[i+1]+1
        local idx2 = idxs[i+2]+1
        tempV0:subVecs(ps[idx1], ps[idx0])
        tempV1:subVecs(ps[idx2], ps[idx0])
        tempN:crossVecs(tempV0, tempV1):normalize()
        tempN.elem.w = 1.0
        normals[idx0]:add(tempN)
        normals[idx1]:add(tempN)
        normals[idx2]:add(tempN)
    end

    -- Average the vertex normals by dividing by the sum (in w)
    for _, v in ipairs(normals) do
        v:multiplyScalar(1.0 / math.max(v.elem.w, 1))
    end

    srcdata.attributes.normal = normals
end

return m