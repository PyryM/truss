-- vertexdefs.t
--
-- bgfx vertex definitions

local m = {}

m.AttributeInfo = {
    {"position",  "p",  float, 3, false},
    {"normal",    "n",  float, 3, false},
    {"tangent",   "t",  float, 3, false},
    {"bitangent", "b",  float, 3, false},
    {"color0",    "c0", uint8, 4, true},
    {"color1",    "c1", uint8, 4, true},
    {"indices",   "i",  uint8, 4, false},
    {"weight",    "w",  float, 4, false},
    {"texcoord0", "t0", float, 2, false},
    {"texcoord1", "t1", float, 2, false},
    {"texcoord2", "t2", float, 2, false},
    {"texcoord3", "t3", float, 2, false},
    {"texcoord4", "t4", float, 2, false},
    {"texcoord5", "t5", float, 2, false},
    {"texcoord6", "t6", float, 2, false},
    {"texcoord7", "t7", float, 2, false}
}

m.AttributeBGFXTypes = {
    [float]  = bgfx.BGFX_ATTRIB_TYPE_FLOAT,
    [uint8]  = bgfx.BGFX_ATTRIB_TYPE_UINT8,
    [int16] = bgfx.BGFX_ATTRIB_TYPE_INT16
}

m.AttributeMap = {}
m.AttributeBGFXEnums = {}
for i,attribData in ipairs(m.AttributeInfo) do
    local attribName = attribData[1]
    local enumVal = bgfx["BGFX_ATTRIB_" .. string.upper(attribName)]
    m.AttributeBGFXEnums[attribName] = enumVal
    m.AttributeMap[attribName] = attribData
end

function m.orderAttributes(attribList)
    local t = {}
    for _,v in ipairs(attribList) do
        t[v] = true
    end
    local ordered = {}
    for _,v in ipairs(m.AttributeInfo) do
        if t[v[1]] then table.insert(ordered, v[1]) end
    end
    return ordered
end

m.StandardVertexInfo = {}
function m.createStandardVertexType(orderedAttributes)
    local cname = table.concat(orderedAttributes, "_") .. "_vertex"
    if not m.StandardVertexInfo[cname] then
        local entries = {}
        local ntype = terralib.types.newstruct(cname)
        local vdecl = terralib.new(bgfx.bgfx_vertex_decl_t)
        local acounts = {}

        bgfx.bgfx_vertex_decl_begin(vdecl, bgfx.bgfx_get_renderer_type()) 
        for i,attribName in ipairs(orderedAttributes) do
            log.info("Adding " .. attribName)
            local attrib = m.AttributeMap[attribName]
            local atype = attrib[3]
            local acount = attrib[4]
            local normalized = attrib[5]
            log.info(atype)
            entries[i] = {attribName, atype[acount]}
            acounts[attribName] = acount
            local bgfx_enum = m.AttributeBGFXEnums[attribName]
            local bgfx_type = m.AttributeBGFXTypes[atype]
            bgfx.bgfx_vertex_decl_add(vdecl, bgfx_enum, acount, bgfx_type, normalized, false)
        end
        bgfx.bgfx_vertex_decl_end(vdecl)

        ntype.entries = entries

        m.StandardVertexInfo[cname] = {vertType = ntype, 
                                       vertDecl = vdecl, 
                                       attributes = acounts}
    end
    return m.StandardVertexInfo[cname]
end

function m.createPosColorVertexInfo() 
    return m.createStandardVertexType({"position", "color0"})
end

function m.createPosNormalVertexInfo()
    return m.createStandardVertexType({"position", "normal"})
end

function m.createPosNormalUVVertexInfo()
    return m.createStandardVertexType({"position", "normal", "texcoord0"})
end

return m