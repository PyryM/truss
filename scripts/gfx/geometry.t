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

local INDEX_TYPE = uint16

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


local function allocate_buffer_data_(geo, vertInfo, nVertices, nIndices)
    geo.vertInfo = vertInfo
    geo.verts = terralib.new(vertInfo.vertType[nVertices])
    geo.nVertices = nVertices
    geo.indices = terralib.new(INDEX_TYPE[nIndices])
    geo.nIndices = nIndices
    geo.vertDataSize = sizeof(vertInfo.vertType[nVertices])
    geo.indexDataSize = sizeof(INDEX_TYPE[nIndices])
    geo.allocated = true
end

function StaticGeometry:allocate(vertInfo, nVertices, nIndices)
    allocate_buffer_data_(self, vertInfo, nVertices, nIndices)
    return self
end
DynamicGeometry.allocate = StaticGeometry.allocate

function StaticGeometry:setIndices(indices)
    bufferutils.setIndices(self, indices)
end
DynamicGeometry.setIndices = StaticGeometry.setIndices

function StaticGeometry:setAttribute(attribName, attribList)
    bufferutils.setAttribute(self, attribName, attribList)
end
DynamicGeometry.setAttribute = StaticGeometry.setAttribute

function StaticGeometry:fromData(vertexInfo, modeldata, noBuild)
    if modeldata == nil or vertexInfo == nil then 
        log.error("Geometry:fromData: nil vertexInfo or modeldata!")
        return 
    end

    local nindices
    if type(modeldata.indices[0]) == "number" then
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

function StaticGeometry:build(recreate)
    if not self.allocated then
        log.error("Cannot build geometry with no allocated data!")
        return
    end

    local flags = 0

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
                                        bgfx.UINT32_MAX)
    bgfx.bgfx_set_dynamic_index_buffer(self.ibh, 
                                        0, bgfx.UINT32_MAX)
end

m.StaticGeometry    = StaticGeometry -- 'export' Geometry
m.DynamicGeometry   = DynamicGeometry
--m.TransientGeometry = TransientGeometry 

return m