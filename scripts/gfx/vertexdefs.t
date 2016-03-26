-- vertexdefs.t
--
-- bgfx vertex definitions

local m = {}

m.AttributeNames = {
    "position",
    "normal",
    "tangent",
    "bitangent",
    "color0",
    "color1",
    "indices",
    "weight",
    "texcoord0",
    "texcoord1",
    "texcoord2",
    "texcoord3",
    "texcoord4",
    "texcoord5",
    "texcoord6",
    "texcoord7"
}

m.AttributeBGFXEnums = {}
for i,attribName in ipairs(m.AttributeNames) do
    local enumVal = bgfx["BGFX_ATTRIB_" .. string.upper(attribName)]
    m.AttributeBGFXEnums[attribName] = enumVal
end

struct m.PosColorVertex {
    position: float[3];
    color0:   uint8[4];
}

struct m.PosNormalVertex {
    position: float[3];
    normal:   float[3];
}

struct m.PosNormalUVVertex {
    position:  float[3];
    normal:    float[3];
    texcoord0: float[2];
}

terra m.declarePosColorVertex(vertDecl : &bgfx.bgfx_vertex_decl_t)
    bgfx.bgfx_vertex_decl_begin(vertDecl, bgfx.bgfx_get_renderer_type())
    bgfx.bgfx_vertex_decl_add(vertDecl, bgfx.BGFX_ATTRIB_POSITION, 3, bgfx.BGFX_ATTRIB_TYPE_FLOAT, false, false)
    -- COLOR0 is normalized (the 'true' flag) which indicates that uint8 values [0,255] should be scaled to [0.0,1.0]
    bgfx.bgfx_vertex_decl_add(vertDecl, bgfx.BGFX_ATTRIB_COLOR0, 4, bgfx.BGFX_ATTRIB_TYPE_UINT8, true, false)
    bgfx.bgfx_vertex_decl_end(vertDecl)
end

terra m.declarePosNormalVertex(vertDecl: &bgfx.bgfx_vertex_decl_t)
    bgfx.bgfx_vertex_decl_begin(vertDecl, bgfx.bgfx_get_renderer_type())
    bgfx.bgfx_vertex_decl_add(vertDecl, bgfx.BGFX_ATTRIB_POSITION, 3, bgfx.BGFX_ATTRIB_TYPE_FLOAT, false, false)
    bgfx.bgfx_vertex_decl_add(vertDecl, bgfx.BGFX_ATTRIB_NORMAL, 3, bgfx.BGFX_ATTRIB_TYPE_FLOAT, false, false)
    bgfx.bgfx_vertex_decl_end(vertDecl)
end

terra m.declarePosNormalUVVertex(vertDecl: &bgfx.bgfx_vertex_decl_t)
    bgfx.bgfx_vertex_decl_begin(vertDecl, bgfx.bgfx_get_renderer_type())
    bgfx.bgfx_vertex_decl_add(vertDecl, bgfx.BGFX_ATTRIB_POSITION, 3, bgfx.BGFX_ATTRIB_TYPE_FLOAT, false, false)
    bgfx.bgfx_vertex_decl_add(vertDecl, bgfx.BGFX_ATTRIB_NORMAL, 3, bgfx.BGFX_ATTRIB_TYPE_FLOAT, false, false)
    bgfx.bgfx_vertex_decl_add(vertDecl, bgfx.BGFX_ATTRIB_TEXCOORD0, 2, bgfx.BGFX_ATTRIB_TYPE_FLOAT, false, false)
    bgfx.bgfx_vertex_decl_end(vertDecl)
end

local vdefs = {}

function m.createPosColorVertexInfo()
    if not vdefs["p_c0"] then 
        local vspec = terralib.new(bgfx.bgfx_vertex_decl_t)
        m.declarePosColorVertex(vspec)
        vdefs["p_c0"] = {vertType = m.PosColorVertex, vertDecl = vspec, attributes = {position=3, color0=4}}
    end
    return vdefs["p_c0"]
end

function m.createPosNormalVertexInfo()
    if not vdefs["p_n"] then
        local vspec = terralib.new(bgfx.bgfx_vertex_decl_t)
        m.declarePosNormalVertex(vspec)
        vdefs["p_n"] = {vertType = m.PosNormalVertex, vertDecl = vspec, attributes = {position=3, normal=3}}
    end
    return vdefs["p_n"]
end

function m.createPosNormalUVVertexInfo()
    if not vdefs["p_n_t0"] then
        local vspec = terralib.new(bgfx.bgfx_vertex_decl_t)
        m.declarePosNormalUVVertex(vspec)
        vdefs["p_n_t0"] = {vertType = m.PosNormalUVVertex, vertDecl = vspec, attributes = {position=3, normal=3, texcoord0=2}}
    end
    return vdefs["p_n_t0"]
end

return m