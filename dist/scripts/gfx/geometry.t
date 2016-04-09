-- geometry.t
--
-- Geometry
-- a class representing indexed vertex data (vertices + index list)

local class = require("class")
local vec = require("math/vec.t")
local quat = require("math/quat.t")
local matrix = require("math/matrix.t")
local bufferutils = require("gfx/bufferutils.t")

local Quaternion = quat.Quaternion
local Matrix4 = matrix.Matrix4
local Vector = vec.Vector

local m = {}

local buffer_library_ = {} -- needed for memory management reasons
local last_geo_idx_ = 0

local StaticGeometry = class("StaticGeometry")
function StaticGeometry:init(name)
    if name then
        self.name = name
    else
        self.name = "__anon_staticgeometry_" .. last_geo_idx_
        last_geo_idx_ = last_geo_idx_ + 1
    end
    self.allocated = false
    self.built     = false
end

local DynamicGeometry = class("DynamicGeometry")
function DynamicGeometry:init(name)
    if name then
        self.name = name
    else
        self.name = "__anon_dyngeometry_" .. last_geo_idx_
        last_geo_idx_ = last_geo_idx_ + 1
    end
    self.allocated = false
    self.built     = false
end

local TransientGeometry = class("TransientGeometry")
function TransientGeometry:init(name)
    self.name = name or "__anon_transientgeometry_" .. last_geo_idx_
    last_geo_idx_ = last_geo_idx_ + 1
    self.allocated = false

    self.transientVB_ = terralib.new(bgfx.bgfx_transient_vertex_buffer_t)
    self.transientIB_ = terralib.new(bgfx.bgfx_transient_index_buffer_t)
end

function TransientGeometry:allocate(vertInfo, nVertices, nIndices)
    if self.allocated and not self.bound then
        log.error("TransientGeometry [" .. self.name ..
                    "] must be bound before it can be allocated again!")
        return
    end

    if nVertices >= 2^16 then
        log.error("TransientGeometry [" .. self.name ..
                   "] cannot have more then 2^16 vertices.")
        return
    end

    local hasSpace = bgfx.bgfx_check_avail_transient_buffers(nVertices,
                                           vertInfo.vertDecl, nIndices)
    if not hasSpace then
        log.error("Not enough space to allocate " .. nVertices ..
                    " / " .. nIndices .. " in transient buffer.")
        return
    end

    bgfx.bgfx_alloc_transient_buffers(self.transientVB_, vertInfo.vertDecl, nVertices,
                                      self.transientIB_, nIndices)

    self.indices = terralib.cast(&uint16, self.transientIB_.data)
    self.verts   = terralib.cast(&vertInfo.vertType, self.transientVB_.data)
    self.allocated = true

    return self
end

-- create what would typically be called a "screenSpaceQuad"
-- width and height default to 1.0, uv coordinates go 0-1
--
--        /|  actually implemented as a triangle that overflows the screen
--      /__|  like this
--    /|   |
--  /__|___|  hey it saves one triangle, that adds up
function TransientGeometry:fullScreenTri(width, height, originBottomLeft, vinfo)
    local minx = -width
    local maxx =  width
    local miny =  0.0
    local maxy =  height*2.0
    local minu = -1.0
    local maxu =  1.0
    local minv =  0.0
    local maxv =  2.0

    if originBottomLeft then
        minv, maxv = 1, -1
    end

    if not vinfo then
        local vdefs = require("gfx/vertexdefs.t")
        vinfo = vdefs.createStandardVertexType({"position", "texcoord0"})
    end

    self:allocate(vinfo, 3, 3)
    local verts = self.verts
    local v0p, v0t = verts[0].position, verts[0].texcoord0
    local v1p, v1t = verts[1].position, verts[1].texcoord0
    local v2p, v2t = verts[2].position, verts[2].texcoord0

    v0p[0], v0p[1], v0p[2] = minx, miny, 0.0
    v0t[0], v0t[1] = minu, minv
    v1p[0], v1p[1], v1p[2] = maxx, miny, 0.0
    v1t[0], v1t[1] = maxu, minv
    v2p[0], v2p[1], v2p[2] = maxx, maxy, 0.0
    v2t[0], v2t[1] = maxu, maxv

    for i = 0,2 do
        self.indices[i] = i
    end

    return self
end

function m.makeFastTransientQuadFunc(vinfo)
    if not vinfo then
        local vdefs = require("gfx/vertexdefs.t")
        vinfo = vdefs.createStandardVertexType({"position", "texcoord0"})
    end
    local vtype = vinfo.vertType
    local vdecl = vinfo.vertDecl
    local terra fastQuad(x0: float, y0: float, x1: float, y1: float, z: float)
        var vb: bgfx.bgfx_transient_vertex_buffer_t
        var ib: bgfx.bgfx_transient_index_buffer_t

        bgfx.bgfx_alloc_transient_buffers(&vb, &vdecl, 4, &ib, 6)
        var vertex: &vtype = [&vtype](vb.data)

        vertex[0].position[0] = x0
        vertex[0].position[1] = y0
        vertex[0].position[2] = z
        vertex[0].texcoord0[0] = 0.0
        vertex[0].texcoord0[1] = 0.0

        vertex[1].position[0] = x1
        vertex[1].position[1] = y0
        vertex[1].position[2] = z
        vertex[1].texcoord0[0] = 1.0
        vertex[1].texcoord0[1] = 0.0

        vertex[2].position[0] = x1
        vertex[2].position[1] = y1
        vertex[2].position[2] = z
        vertex[2].texcoord0[0] = 1.0
        vertex[2].texcoord0[1] = 1.0

        vertex[3].position[0] = x0
        vertex[3].position[1] = y1
        vertex[3].position[2] = z
        vertex[3].texcoord0[0] = 0.0
        vertex[3].texcoord0[1] = 1.0

        var indexb: &uint16 = [&uint16](ib.data)
        indexb[0] = 0
        indexb[1] = 1
        indexb[2] = 2

        indexb[3] = 2
        indexb[4] = 3
        indexb[5] = 0

        bgfx.bgfx_set_transient_vertex_buffer(&vb, 0, 4)
        bgfx.bgfx_set_transient_index_buffer(&ib, 0, 6)
    end
    return fastQuad
end

function TransientGeometry:quad(x0, y0, x1, y1, z, vinfo)
    if not vinfo then
        local vdefs = require("gfx/vertexdefs.t")
        vinfo = vdefs.createStandardVertexType({"position", "texcoord0"})
    end
    self:allocate(vinfo, 4, 6)
    local vs = self.verts
    local v0,v1,v2,v3 = vs[0],vs[1],vs[2],vs[3]
    v0.position[0], v0.position[1], v0.position[2] = x0, y0, z
    v0.texcoord0[0], v0.texcoord0[1] = 0.0, 0.0

    v1.position[0], v1.position[1], v1.position[2] = x1, y0, z
    v1.texcoord0[0], v1.texcoord0[1] = 1.0, 0.0

    v2.position[0], v2.position[1], v2.position[2] = x1, y1, z
    v2.texcoord0[0], v2.texcoord0[1] = 1.0, 1.0

    v3.position[0], v3.position[1], v3.position[2] = x0, y1, z
    v3.texcoord0[0], v3.texcoord0[1] = 0.0, 1.0

    local idx = self.indices
    idx[0], idx[1], idx[2] = 0, 1, 2
    idx[3], idx[4], idx[5] = 2, 3, 0

    return self
end

function TransientGeometry:bind()
    if not self.allocated then
        log.error("Cannot bind unallocated transient buffer!")
        return
    end

    bgfx.bgfx_set_transient_vertex_buffer(self.transientVB_, 0, bgfx.UINT32_MAX)
    bgfx.bgfx_set_transient_index_buffer(self.transientIB_, 0, bgfx.UINT32_MAX)

    self.bound = true
    return self
end

function TransientGeometry:build()
    -- transient geometry does not need to be built; this stub exists only for
    -- compatibility with functions that do try to build
    return self
end

function TransientGeometry:beginFrame()
    if self.allocated and not self.bound then
        log.warn("Allocating transient geometry without binding it the same frame will leak memory!")
    end

    self.indices = nil
    self.verts = nil
    self.allocated = false
    self.bound = false
    return self
end

function StaticGeometry:allocate(vertInfo, nVertices, nIndices)
    local indexType = uint16
    if nVertices >= 2^16 then
        log.debug("Using 32 bit indices in index buffer!")
        indexType = uint32
        self.has32bitIndices = true
    end

    self.vertInfo = vertInfo
    self.verts = terralib.new(vertInfo.vertType[nVertices])
    self.nVertices = nVertices
    self.indices = terralib.new(indexType[nIndices])
    self.nIndices = nIndices
    self.vertDataSize = sizeof(vertInfo.vertType[nVertices])
    self.indexDataSize = sizeof(indexType[nIndices])
    self.allocated = true
    return self
end
DynamicGeometry.allocate = StaticGeometry.allocate

function StaticGeometry:setIndices(indices)
    bufferutils.setIndices(self, indices)
end
DynamicGeometry.setIndices = StaticGeometry.setIndices
TransientGeometry.setIndices = StaticGeometry.setIndices

function StaticGeometry:setAttribute(attribName, attribList)
    bufferutils.setAttribute(self, attribName, attribList)
end
DynamicGeometry.setAttribute = StaticGeometry.setAttribute
TransientGeometry.setAttribute = StaticGeometry.setAttribute

function StaticGeometry:fromData(vertexInfo, modeldata, noBuild)
    if modeldata == nil or vertexInfo == nil then
        log.error("Geometry:fromData: nil vertexInfo or modeldata!")
        return
    end

    local nindices
    if type(modeldata.indices[1]) == "number" then
        nindices = #modeldata.indices
    else
        nindices = #modeldata.indices * 3
    end
    self:allocate(vertexInfo, #(modeldata.attributes.position), nindices)

    for attribName, attribData in pairs(modeldata.attributes) do
        self:setAttribute(attribName, attribData)
    end
    self:setIndices(modeldata.indices)

    if noBuild then
        return self
    else
        return self:build()
    end
end
DynamicGeometry.fromData = StaticGeometry.fromData
TransientGeometry.fromData = StaticGeometry.fromData

function StaticGeometry:build(recreate)
    if not self.allocated then
        log.error("Cannot build geometry with no allocated data!")
        return
    end

    local flags = bgfx_const.BGFX_BUFFER_NONE
    if self.has32bitIndices then
        log.debug("Building w/ 32 bit index buffer!")
        flags = bgfx_const.BGFX_BUFFER_INDEX32
    end

    if (self.vbh or self.ibh) and (not recreate) then
        log.warn("Tried to rebuild StaticGeometry [" ..
                    self.name .. "] without explicit recreate!")
        return
    end

    if self.vbh then
        bgfx.bgfx_destroy_vertex_buffer(self.vbh)
    end
    if self.ibh then
        bgfx.bgfx_destroy_index_buffer(self.ibh)
    end

    -- Create static bgfx buffers
    -- Warning! This only wraps the data, so make sure it doesn't go out
    -- of scope for at least two frames (bgfx requirement)
    self.vbh = bgfx.bgfx_create_vertex_buffer(
          bgfx.bgfx_make_ref(self.verts, self.vertDataSize),
          self.vertInfo.vertDecl, flags )

    self.ibh = bgfx.bgfx_create_index_buffer(
          bgfx.bgfx_make_ref(self.indices, self.indexDataSize), flags )

    self.built = (self.vbh ~= nil) and (self.ibh ~= nil)

    return self
end

function StaticGeometry:update()
    self:build()
end

local function check_built_(geo)
    if geo.built then return true end

    if not geo.warned then
        log.warn("Warning: geometry [" .. geo.name .. "] has not been built.")
        geo.warned = true
    end
    return false
end

function StaticGeometry:bind()
    if not check_built_(self) then return end

    bgfx.bgfx_set_vertex_buffer(self.vbh, 0, bgfx.UINT32_MAX)
    bgfx.bgfx_set_index_buffer(self.ibh, 0, bgfx.UINT32_MAX)

    return true
end

function DynamicGeometry:build(recreate)
    local flags = 0

    if self.built and not recreate then
        log.warn("Tried to rebuilt already built DynamicGeometry " ..
                  self.name)
        return
    end

    if self.vbh then
        bgfx.bgfx_destroy_dynamic_vertex_buffer(self.vbh)
    end
    if self.ibh then
        bgfx.bgfx_destroy_dynamic_index_buffer(self.ibh)
    end

    log.debug("Creating dynamic buffer...")

    -- Create dynamic bgfx buffers
    -- Warning! This only wraps the data, so make sure it doesn't go out
    -- of scope for at least two frames (bgfx requirement)
    self.vbh = bgfx.bgfx_create_dynamic_vertex_buffer_mem(
          bgfx.bgfx_make_ref(self.verts, self.vertDataSize),
          self.vertInfo.vertDecl, flags )

    self.ibh = bgfx.bgfx_create_dynamic_index_buffer_mem(
          bgfx.bgfx_make_ref(self.indices, self.indexDataSize), flags )

    self.built = (self.vbh ~= nil) and (self.ibh ~= nil)

    return self
end

function DynamicGeometry:update()
    if not self.built then
        self:build()
    else
        self:updateVertices()
        self:updateIndices()
    end

    return self
end

function DynamicGeometry:updateVertices()
    if not self.vbh then return end

    bgfx.bgfx_update_dynamic_vertex_buffer(self.vbh, 0,
        bgfx.bgfx_make_ref(self.verts, self.vertDataSize))

    return self
end

function DynamicGeometry:updateIndices()
    if not self.ibh then return end

    bgfx.bgfx_update_dynamic_index_buffer(self.ibh, 0,
         bgfx.bgfx_make_ref(self.indices, self.indexDataSize))

    return self
end

function DynamicGeometry:bind()
    if not check_built_(self) then return end

    -- for some reason set_dynamic_vertex_buffer does not take a start
    -- index argument, only the number of vertices
    bgfx.bgfx_set_dynamic_vertex_buffer(self.vbh,
                                         0, bgfx.UINT32_MAX)

    bgfx.bgfx_set_dynamic_index_buffer(self.ibh,
                                        0, bgfx.UINT32_MAX)
end

m.StaticGeometry    = StaticGeometry -- 'export' Geometry
m.DynamicGeometry   = DynamicGeometry
m.TransientGeometry = TransientGeometry

return m
