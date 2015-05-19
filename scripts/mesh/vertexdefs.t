-- vertexdefs.t
--
-- bgfx vertex definitions

local m = {}

struct m.Color {
	b: uint8;
	g: uint8;
	r: uint8;
	a: uint8;
}

struct m.PosColorVertex {
	x: float;
	y: float;
	z: float;
    union {
    	int32_color: uint32;
    	color: m.Color;
	}
}

terra m.declarePosColorVertex(vertDecl : &bgfx.bgfx_vertex_decl_t)
	bgfx.bgfx_vertex_decl_begin(vertDecl, bgfx.bgfx_get_renderer_type())
	bgfx.bgfx_vertex_decl_add(vertDecl, bgfx.BGFX_ATTRIB_POSITION, 3, bgfx.BGFX_ATTRIB_TYPE_FLOAT, false, false)
	-- COLOR0 is normalized (the 'true' flag) which indicates that uint8 values [0,255] should be scaled to [0.0,1.0]
	bgfx.bgfx_vertex_decl_add(vertDecl, bgfx.BGFX_ATTRIB_COLOR0, 4, bgfx.BGFX_ATTRIB_TYPE_UINT8, true, false)
	bgfx.bgfx_vertex_decl_end(vertDecl)
end

function m.createPosColorVertexInfo()
	local vspec = terralib.new(bgfx.bgfx_vertex_decl_t)
	m.declarePosColorVertex(vspec)
	return {vertType = m.PosColorVertex, vertDecl = vspec}
end

return m