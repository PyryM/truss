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

-- makeLSetter
--
-- makes a function to set an attribute name from a
-- number of values
function m.makeLSetter(attribname, nvals)
    if nvals > 1 then
        return function(vdata, vindex, attribVal)
            local tgt = vdata[vindex][attribname]
            for i = 1,nvals do
                -- the attribute is C-style struct and so zero indexed
                tgt[i-1] = attribVal[i]
            end
        end
    else
        return function(vdata, vindex, attribVal)
            vdata[vindex][attribname] = attribVal
        end
    end
end

-- makeVSetter
--
-- makes a setter function that sets from a Vector
function m.makeVSetter(attribname, nvals)
    local keys = {"x", "y", "z", "w"}
    return function(vdata, vindex, attribVal)
        local tgt = vdata[vindex][attribname]
        local src = attribVal.elem
        for i = 1,nvals do
            -- the attribute is C-style struct and so zero indexed
            tgt[i-1] = src[keys[i]]
        end
    end
end

-- populate setter list
m.setters = {}
for _, aInfo in ipairs(vertexdefs.DefaultAttributeInfo) do
    local aName = aInfo[1]
    m.setters[aName .. "_F"] = m.makeLSetter(aName, 1)
    for i = 1,4 do
        m.setters[aName .. "_L" .. i] = m.makeLSetter(aName, i)
        m.setters[aName .. "_V" .. i] = m.makeVSetter(aName, i)
    end
end

-- setter for when you just need random colors, ignores attribVal
m.setters.color0_RAND = function(vdata, vindex, attribVal)
    vdata[vindex].color0[0] = math.random() * 255.0
    vdata[vindex].color0[1] = math.random() * 255.0
    vdata[vindex].color0[2] = math.random() * 255.0
    vdata[vindex].color0[3] = math.random() * 255.0
end

function m.findSetter(target, attribName, attribList)
    -- figure out how many elements the target has for the attribute
    -- (e.g., 3 element colors [rgb] vs. 4 element color [rgba])
    local datanum = target.vertinfo.attributes[attribName]
    if datanum == nil then return end

    -- determine what setter to use based on the src list
    -- (assume list is homogeneous: probably unsafe but :effort:)
    local setterTag = ""
    local src1 = attribList[1]
    if type(src1) == "number" then -- list of numbers
        setterTag = attribName .. "_F"
    elseif src1.elem then          -- list of Vectors
        setterTag = attribName .. "_V" .. datanum
    else                           -- list of lists
        setterTag = attribName .. "_L" .. datanum
    end
    local setter = m.setters[setterTag]

    if setter == nil then
        log.error("Could not find setter for attribute type " .. setterTag)
        return nil
    end

    return setter
end

function m.set_attribute(target, attribName, attribList, setter)
    local listSize = #attribList
    if listSize == 0 then
        log.warn("set_attribute with #attribList == 0 does nothing")
        return
    elseif listSize ~= target.n_verts then
        truss.error("set_attribute: wrong number of vertices, expected "
                .. (target.n_verts or "nil?")
                .. " got " .. (listSize or "nil"))
        return
    end

    setter = setter or m.findSetter(target, attribName, attribList)
    if not setter then return end -- couldn't find setter and none supplied

    -- actually set the data
    local dest = target.verts
    for v = 1,listSize do
        -- dest (data.verts) is a C-style array so zero indexed
        setter(dest, v-1, attribList[v])
    end
end

return m
