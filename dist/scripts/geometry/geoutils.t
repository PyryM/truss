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

local function rgbStride(index, vertex)
    local i = ((index-1) % 3)+1
    local c = {0, 0, 0, 0}
    c[i] = 255
    return Vector():fromArray(c)
end

-- color each triangle with one vertex R, one G, and one B
-- assumes data is a triangle soup
function m.colorRGBTriangles(srcdata, destattr)
    srcdata.attributes[destattr or "color0"] =
        m.mapIndexedAttribute(srcdata.attributes.position, rgbStride)
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

function m.mapIndexedAttribute(attribData, f, arg)
    local ret = {}
    for i,v in ipairs(attribData) do
        ret[i] = f(i, v, arg)
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
    local nfaces = #idxs
    for i = 1, nfaces do
        local f = idxs[i]
        local idx0 = f[1]+1
        local idx1 = f[2]+1
        local idx2 = f[3]+1
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
        v.elem.w = 0.0
        v:normalize()
    end

    srcdata.attributes.normal = normals
end

-- creates a geometry from a geometry data using the default vertex type
function m.toBasicGeo(geoName, data)
    local gfx = require("gfx")
    local attrNames = {"position", "normal"}
    if not data.attributes.normal then m.computeNormals(data) end
    if data.attributes.texcoord0 then table.insert(attrNames, "texcoord0") end
    local vertexInfo = gfx.createStandardVertexType(attrNames)
    return gfx.StaticGeometry(geoName):fromData(vertexInfo, data)
end

local function pushTriVerts(src, dest, tri)
    table.insert(dest, src[tri[1]+1])
    table.insert(dest, src[tri[2]+1])
    table.insert(dest, src[tri[3]+1])
end

-- splits indexed triangles into a 'triangle soup' so that no triangles share
-- vertices
function m.splitData(data)
    local ret = {indices = {}, attributes = {}}
    -- split attributes
    for attrName, attr in pairs(data.attributes) do
        local dest = {}
        for idx, tri in ipairs(data.indices) do
            pushTriVerts(attr, dest, tri)
        end
        ret.attributes[attrName] = dest
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
function m.mergeData(datalist, attributes)
    local ret = {indices = {}, attributes = {}}
    for _,v in ipairs(attributes) do ret.attributes[v] = {} end

    local idxOffset = 0
    for _,v in ipairs(datalist) do
        local data, pose = v[1], v[2]
        local nverts = #(data.attributes.position)
        -- copy attributes (assume vector attributes)
        for attrName,vertexList in pairs(ret.attributes) do
            local srcAttr = data.attributes[attrName]
            local ntarget = (srcAttr ~= nil) and #(srcAttr)
            if ntarget ~= nverts then
                log.error("geometryutils.mergeData: attribute " .. attrName ..
                          " expected " .. nverts .. ", had " .. tostring(ntarget))
                return nil
            end
            for _,attrVal in ipairs(srcAttr) do
                local newVal = Vector():copy(attrVal)
                if pose then
                    if attrName == "position" then newVal.elem.w = 1.0 end
                    pose:multiplyVector(newVal)
                end
                table.insert(vertexList, newVal)
            end
        end
        -- copy indices (assume list-of-lists format)
        for _,triangle in ipairs(data.indices) do
            local s0,s1,s2 = triangle[1], triangle[2], triangle[3]
            local i0,i1,i2 = s0+idxOffset, s1+idxOffset, s2+idxOffset
            table.insert(ret.indices, {i0, i1, i2})
        end
        idxOffset = idxOffset + nverts
    end
    return ret
end

return m
