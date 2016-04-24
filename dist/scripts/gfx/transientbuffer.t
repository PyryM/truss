-- transientbuffer.t
--
-- utils for using bgfx transient buffers

local m = {}

local vertdefs = require('mesh/vertdefs.t')
m.posVertexInfo = vertdefs.createPosUVVertexInfo()

local PosVertexType = m.posVertexInfo.vertType
local posVertexDecl = m.posVertexInfo.vertDecl

terra m.createTransientSquare(x0: float, y0: float, 
                              x1: float, y1: float, 
                              z: float)

    var vb: bgfx.bgfx_transient_vertex_buffer_t
    var ib: bgfx.bgfx_transient_index_buffer_t

    var buffersHappy = bgfx.bgfx_alloc_transient_buffers(vb, posVertexDecl, 4, 
                                                         ib, 6)

    var vertex: &PosVertexType = [&PosVertexType](vb.data)

    vertex[0].position[0] = x0
    vertex[0].position[1] = y0
    vertex[0].position[2] = z
    vertex[0].uv[0] = 0.0
    vertex[0].uv[1] = 0.0

    vertex[1].position[0] = x1
    vertex[1].position[1] = y0
    vertex[1].position[2] = z
    vertex[1].uv[0] = 1.0
    vertex[1].uv[1] = 0.0

    vertex[2].position[0] = x1
    vertex[2].position[1] = y1
    vertex[2].position[2] = z
    vertex[2].uv[0] = 1.0
    vertex[2].uv[1] = 1.0

    vertex[3].position[0] = x0
    vertex[3].position[1] = y1
    vertex[3].position[2] = z
    vertex[3].uv[0] = 0.0
    vertex[3].uv[1] = 1.0

    var indexb: &uint16 = [&uint16](ib.data)
    indexb[0] = 0
    indexb[1] = 1
    indexb[2] = 2

    indexb[3] = 2
    indexb[4] = 3
    indexb[5] = 0

    bgfx.bgfx_set_transient_vertex_buffer(vb, 0, 4)
    bgfx.bgfx_set_transient_index_buffer(ib, 0, 6)
end

return m