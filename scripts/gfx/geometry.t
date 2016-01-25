-- geometry.t
--
-- Geometry
-- a class representing indexed vertex data (vertices + index list)

local class = require("class")
local vec = require("math/vec.t")
local quat = require("math/quat.t")
local matrix = require("math/matrix.t")
local buffers = require("mesh/buffers.t")

local Quaternion = quat.Quaternion
local Matrix4 = matrix.Matrix4
local Vector = vec.Vector

local m = {}

local INDEX_TYPE = uint16

local buffer_library_ = {} -- needed for memory management reasons?
local last_geo_idx_ = 0

local Geometry = class("Geometry")
function Geometry:init(name)
    if name then
        self.name = name
    else
        self.name = "__anonymous_geometry_" .. last_geo_idx_
        last_geo_idx_ = last_geo_idx_ + 1
    end
    self.built = false
end

function Geometry:allocate(vertInfo, nVertices, nIndices, isDynamic)
    self.vertInfo = vertInfo
    self.verts = terralib.new(vertInfo.vertType[nVertices])
    self.nVertices = nVertices
    self.indices = terralib.new(INDEX_TYPE[nIndices])
    self.nIndices = nIndices
    self.vertDataSize = sizeof(vertInfo.vertType[nVertices])
    self.indexDataSize = sizeof(INDEX_TYPE[nIndices])
    self.isDynamic = isDynamic
    self.allocated = true
end

function Geometry:allocateTransient(vertInfo, nVertices, nIndices)
end

function Geometry:setAttribute(attribName, attribList)
end

function Geometry:setIndices(indexList)
    buffers.setIndices(self.buffers, indexList)
end

function Geometry:update_dynamic_(recreate)
    local flags = 0

    -- data already has buffers, so do simple update
    if (self.vbh and self.ibh) and (not recreate) then
        bgfx.bgfx_update_dynamic_index_buffer(self.ibh, 0,
             bgfx.bgfx_make_ref(self.indices, self.indexDataSize))

        bgfx.bgfx_update_dynamic_vertex_buffer(self.vbh, 0,
             bgfx.bgfx_make_ref(self.verts, self.vertDataSize))

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
end

function Geometry:update_static_(recreate)
    local flags = 0

    if (self.vbh or self.ibh) and (not recreate) then
        log.warn("Tried to update static geometry [" .. 
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
    data.vbh = bgfx.bgfx_create_vertex_buffer(
          bgfx.bgfx_make_ref(self.verts, self.vertDataSize),
          self.vertInfo.vertDecl, flags )

    data.ibh = bgfx.bgfx_create_index_buffer(
          bgfx.bgfx_make_ref(self.indices, self.indexDataSize), flags )
end

function Geometry:update(recreate)
    if not self.allocated then
        log.error("Cannot update geometry with no allocated data!")
        return
    end
    
    if self.isDynamic then
        self:update_dynamic_(recreate)
    else
        self:update_static_(recreate)
    end
end

function Geometry:fromBuffers(databuffers)
    self.databuffers = databuffers
    buffer_library_[self.name] = databuffers
    return self
end

function Geometry:fromData(vertexInfo, modeldata)
    if modeldata == nil or vertexInfo == nil then return end

    -- allocate static buffers
    self:allocate(vertexInfo, #(modeldata.positions), #(modeldata.indices), false)
    self:setIndices(modeldata.indices)

    self:setAttribute("position", modeldata.position)
    self:setAttribute("normal", modeldata.normal)
    self:setAttribute("tangent", modeldata.tangent)
    self:setAttribute("tex0", modeldata.tex0)
    self:setAttribute("color", modeldata.color)

    self:update()
    return self
end

function Geometry:bind()
    local databuffers = self.buffers

    if not databuffers then
        if not self.warned then
            log.warn("Warning: geometry [" .. self.name .. "] contains no data.")
            self.warned = true
        end
        return false
    end

    if databuffers.dynamic then
        -- for some reason set_dynamic_vertex_buffer does not take a start
        -- index argument, only the number of vertices
        bgfx.bgfx_set_dynamic_vertex_buffer(databuffers.vbh, 
                                            bgfx.UINT32_MAX)
        bgfx.bgfx_set_dynamic_index_buffer(databuffers.ibh, 
                                            0, bgfx.UINT32_MAX)
    else
        bgfx.bgfx_set_vertex_buffer(databuffers.vbh, 0, bgfx.UINT32_MAX)
        bgfx.bgfx_set_index_buffer(databuffers.ibh, 0, bgfx.UINT32_MAX)
    end

    return true
end

function Geometry:release()
    -- todo
end

m.Mesh = Mesh -- 'export' Mesh
m.Geometry = Geometry -- 'export' Geometry
return m