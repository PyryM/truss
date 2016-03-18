-- geoutils.t
--
-- various geometry utilities

local m = {}

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

-- does a single subdivision of each triangular face of the data
function m.subdivide(srcdata)
    -- TODO
end

function m.mapAttribute(attribData, f)
    local ret = {}
    for i,v in ipairs(attribData) do
        ret[i] = f(v)
    end
    return ret
end

-- computes normals for data, modifying srcdata in place to add
-- srcdata.attributes.normal
function m.computeNormals(srcdata)
    local Vector = require("math").Vector
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