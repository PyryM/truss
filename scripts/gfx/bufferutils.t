-- bufferutils.t
--
-- utility functions for managing bgfx buffers

local m = {}

local function check_index_size_(geo, nindices)
    if geo.nIndices ~= nindices then
        error("Wrong number of indices, expected " 
                .. (geo.nIndices or "nil")
                .. " got " .. (nindices or "nil"))
        return false
    end
    return true
end

-- setIndices
--
-- sets face indices, checking whether the input is a list of lists
-- or a flat list
function m.setIndices(geo, indexdata)
    if #indexdata == 0 then return end
    if type(indexdata[1]) == "table" then
        m.setIndicesLoL(geo, indexdata)
    else
        m.setIndicesFlat(geo, indexdata)
    end
end

-- setIndicesLoL
--
-- sets face indices from a list of lists
-- e.g. {{0,1,2}, {1,2,3}, {3,4,5}, {5,2,1}}
function m.setIndicesLoL(geo, facelist)
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

-- setIndicesFlat
--
-- set face indices from a flat list (spacing to indicate triangles)
-- e.g., {0,1,2,  1,2,3,  3,4,5,  5,2,1}
function m.setIndicesFlat(geo, indexlist)
    local nindices = #indexlist
    if not check_index_size_(geo, nindices) then return end

    local dest = geo.indices
    local destIndex = 0
    for idx = 1,nindices do
        dest[idx-1] = indexlist[idx] or 0
    end
end

-- makeSetter
--
-- makes a function to set an attribute name from a 
-- number of values
function m.makeSetter(attribname, nvals)
    if nvals > 1 then
        return function(vdata, vindex, attribVal)
            for i = 1,nvals do
                -- vdata is C-style struct and so zero indexed
                vdata[vindex][attribname][i-1] = attribVal[i]
            end
        end
    else 
        return function(vdata, vindex, attribVal)
            vdata[vindex][attribname] = attribVal
        end
    end
end

-- convenience setters
m.positionSetter = m.makeSetter("position", 3)
m.normalSetter = m.makeSetter("normal", 3)
m.uvSetter = m.makeSetter("tex0", 2)
m.colorSetter = m.makeSetter("color", 4)

-- setter for when you just need random colors, ignores attribVal
function m.randomColorSetter(vdata, vindex, attribVal)
    vdata[vindex].color[0] = math.random() * 255.0
    vdata[vindex].color[1] = math.random() * 255.0
    vdata[vindex].color[2] = math.random() * 255.0
    vdata[vindex].color[3] = math.random() * 255.0
end

local attrib_setters = {
    position = m.positionSetter,
    normal = m.normalSetter,
    tex0 = m.uvSetter,
    color = m.colorSetter
}

function m.setNamedAttribute(data, attribname, attriblist)
    local setter = attrib_setters[attribname]
    if setter == nil then
        log.error("No setter for attribute [" .. attribname .. "]")
        return
    end
    m.setAttributesSafe(data, attribname, setter, attriblist)
end

-- setAttributesSafe
--
-- like set attributes but checks if the attribute exists
function m.setAttributesSafe(data, attribname, setter, attriblist)
    if data.vertInfo.attributes[attribname] == nil then
        trss.trss_log(0, "Buffer does not have attribute " .. attribname)
        return
    end
    m.setAttributes(data, setter, attriblist)
end

-- setAttributes
--
-- sets vertex attributes (e.g, positions) given a list
-- of attributes (per vertex) and a setter for that attrib
-- setter(vertData, vertexIndex, attribValue)
function m.setAttributes(data, setter, attriblist)
    local nvertices = #attriblist
    if data.nVertices ~= nvertices then
        error("Wrong number of vertices, expected " 
                .. (data.nVertices or "nil")
                .. " got " .. (nvertices or "nil"))
        return
    end

    local dest = data.verts
    for v = 1,nvertices do
        -- dest (data.verts) is a C-style array so zero indexed
        setter(dest, v-1, attriblist[v])
    end
end

return m