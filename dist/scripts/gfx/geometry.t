-- geometry.t
--
-- Geometry
-- a class representing indexed vertex data (vertices + index list)

local class = require("class")
local math = require("math")
local bufferutils = require("gfx/bufferutils.t")

local Quaternion = math.Quaternion
local Matrix4 = math.Matrix4
local Vector = math.Vector

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

  self._transient_vb = terralib.new(bgfx.bgfx_transient_vertex_buffer_t)
  self._transient_ib = terralib.new(bgfx.bgfx_transient_index_buffer_t)
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
                       vertInfo.decl, nIndices)
  if not hasSpace then
    log.error("Not enough space to allocate " .. nVertices ..
          " / " .. nIndices .. " in transient buffer.")
    return
  end

  bgfx.bgfx_alloc_transient_buffers(self._transient_vb, vertInfo.decl, nVertices,
                    self._transient_ib, nIndices)

  self.indices = terralib.cast(&uint16, self._transient_ib.data)
  self.verts   = terralib.cast(&vertInfo.ttype, self._transient_vb.data)
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
  local minv =  1.0 --v coordinate is flipped to account for texture coords
  local maxv = -1.0

  if originBottomLeft then
    minv, maxv = 1, -1
  end

  if not vinfo then
    local vdefs = require("gfx/vertexdefs.t")
    vinfo = vdefs.create_basic_vertex_type({"position", "texcoord0"})
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
    vinfo = vdefs.create_basic_vertex_type({"position", "texcoord0"})
  end
  local vtype = vinfo.ttype
  local vdecl = vinfo.decl
  local terra fastQuad(x0: float, y0: float, x1: float, y1: float, z: float)
    var vb: bgfx.bgfx_transient_vertex_buffer_t
    var ib: bgfx.bgfx_transient_index_buffer_t

    bgfx.bgfx_alloc_transient_buffers(&vb, &vdecl, 4, &ib, 6)
    var vertex: &vtype = [&vtype](vb.data)

    vertex[0].position[0] = x0
    vertex[0].position[1] = y0
    vertex[0].position[2] = z
    vertex[0].texcoord0[0] = 0.0
    vertex[0].texcoord0[1] = 1.0

    vertex[1].position[0] = x1
    vertex[1].position[1] = y0
    vertex[1].position[2] = z
    vertex[1].texcoord0[0] = 1.0
    vertex[1].texcoord0[1] = 1.0

    vertex[2].position[0] = x1
    vertex[2].position[1] = y1
    vertex[2].position[2] = z
    vertex[2].texcoord0[0] = 1.0
    vertex[2].texcoord0[1] = 0.0

    vertex[3].position[0] = x0
    vertex[3].position[1] = y1
    vertex[3].position[2] = z
    vertex[3].texcoord0[0] = 0.0
    vertex[3].texcoord0[1] = 0.0

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
    vinfo = vdefs.create_basic_vertex_type({"position", "texcoord0"})
  end
  self:allocate(vinfo, 4, 6)
  local vs = self.verts
  local v0,v1,v2,v3 = vs[0],vs[1],vs[2],vs[3]
  v0.position[0], v0.position[1], v0.position[2] = x0, y0, z
  v0.texcoord0[0], v0.texcoord0[1] = 0.0, 1.0

  v1.position[0], v1.position[1], v1.position[2] = x1, y0, z
  v1.texcoord0[0], v1.texcoord0[1] = 1.0, 1.0

  v2.position[0], v2.position[1], v2.position[2] = x1, y1, z
  v2.texcoord0[0], v2.texcoord0[1] = 1.0, 0.0

  v3.position[0], v3.position[1], v3.position[2] = x0, y1, z
  v3.texcoord0[0], v3.texcoord0[1] = 0.0, 0.0

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

  bgfx.bgfx_set_transient_vertex_buffer(self._transient_vb, 0, bgfx.UINT32_MAX)
  bgfx.bgfx_set_transient_index_buffer(self._transient_ib, 0, bgfx.UINT32_MAX)

  self.bound = true
  return self
end

function TransientGeometry:build()
  -- transient geometry does not need to be built; this stub exists only for
  -- compatibility with functions that do try to build
  return self
end

function TransientGeometry:begin_frame()
  if self.allocated and not self.bound then
    log.warn("Allocating transient geometry without binding it the same frame will leak memory!")
  end

  self.indices = nil
  self.verts = nil
  self.allocated = false
  self.bound = false
  return self
end

function StaticGeometry:allocate(vertinfo, n_verts, n_indices)
  local index_type = uint16
  if n_verts >= 2^16 then
    log.debug("Using 32 bit indices in index buffer!")
    index_type = uint32
  end
  self.index_type = index_type

  self.vertinfo = vertinfo
  self.verts = truss.allocate(vertinfo.vert_type[n_verts])
  self.n_verts = n_verts
  self.indices = truss.allocate(index_type[n_indices])
  self.n_indices = n_indices
  self.vert_data_size = sizeof(vertinfo.vert_type[n_verts])
  self.index_data_size = sizeof(index_type[n_indices])
  self.allocated = true
  return self
end
DynamicGeometry.allocate = StaticGeometry.allocate

function StaticGeometry:set_indices(indices)
  bufferutils.set_indices(self, indices)
end
DynamicGeometry.set_indices = StaticGeometry.set_indices
TransientGeometry.set_indices = StaticGeometry.set_indices

function StaticGeometry:set_attribute(attribName, attribList)
  bufferutils.set_attribute(self, attribName, attribList)
end
DynamicGeometry.set_attribute = StaticGeometry.set_attribute
TransientGeometry.set_attribute = StaticGeometry.set_attribute

function StaticGeometry:from_data(vertinfo, modeldata, no_update)
  if modeldata == nil or vertinfo == nil then
    log.error("Geometry:from_data: nil vertinfo or modeldata!")
    return
  end

  local nindices
  if type(modeldata.indices[1]) == "number" then
    nindices = #modeldata.indices
  else
    nindices = #modeldata.indices * 3
  end
  self:allocate(vertinfo, #(modeldata.attributes.position), nindices)

  for a_name, a_data in pairs(modeldata.attributes) do
    self:set_attribute(a_name, a_data)
  end
  self:set_indices(modeldata.indices)

  if no_update then
    return self
  else
    return self:update()
  end
end
DynamicGeometry.from_data = StaticGeometry.from_data
TransientGeometry.from_data = StaticGeometry.from_data

function StaticGeometry:update()
  if not self.allocated then
    log.error("Cannot build geometry with no allocated data!")
    return
  end

  local flags = bgfx.BUFFER_NONE
  if self.index_type == uint32 then
    log.debug("Building w/ 32 bit index buffer!")
    flags = bgfx.BUFFER_INDEX32
  end

  if self._vbh then bgfx.destroy_vertex_buffer(self._vbh) end
  if self._ibh then bgfx.destroy_index_buffer(self._ibh) end

  -- Create static bgfx buffers
  -- Warning! This only wraps the data, so make sure it doesn't go out
  -- of scope for at least two frames (bgfx requirement)
  self._vbh = bgfx.create_vertex_buffer(
      bgfx.make_ref(self.verts, self.vert_data_size),
      self.vertinfo.decl, flags )

  self._ibh = bgfx.create_index_buffer(
      bgfx.make_ref(self.indices, self.index_data_size), flags )

  self.uploaded = (self._vbh ~= nil) and (self._ibh ~= nil)

  return self
end

local function check_built(geo)
  if geo.uploaded then return true end

  if not geo.warned then
    log.warn("Geometry [" .. geo.name .. "] has not been uploaded.")
    geo.warned = true
  end
  return false
end

function StaticGeometry:bind()
  if not check_built(self) then return end

  bgfx.set_vertex_buffer(self._vbh, 0, bgfx.UINT32_MAX)
  bgfx.set_index_buffer(self._ibh, 0, bgfx.UINT32_MAX)

  return true
end

function DynamicGeometry:_build()
  local flags = 0

  if self.uploaded and not recreate then
    log.warn("Tried to rebuilt already built DynamicGeometry " ..
          self.name)
    return
  end

  if self._vbh then bgfx.destroy_dynamic_vertex_buffer(self._vbh) end
  if self._ibh then bgfx.destroy_dynamic_index_buffer(self._ibh) end

  log.debug("Creating dynamic buffer...")

  -- Create dynamic bgfx buffers
  -- Warning! This only wraps the data, so make sure it doesn't go out
  -- of scope for at least two frames (bgfx requirement)
  self._vbh = bgfx.create_dynamic_vertex_buffer_mem(
      bgfx.make_ref(self.verts, self.vert_data_size),
      self.vertinfo.decl, flags )

  self._ibh = bgfx.create_dynamic_index_buffer_mem(
      bgfx.make_ref(self.indices, self.index_data_size), flags )

  self.built = (self._vbh ~= nil) and (self._ibh ~= nil)

  return self
end

function DynamicGeometry:update()
  if not self.built then
    self:build()
  else
    self:update_vertices()
    self:update_indices()
  end

  return self
end

function DynamicGeometry:update_vertices()
  if not self._vbh then return end

  bgfx.update_dynamic_vertex_buffer(self._vbh, 0,
    bgfx.make_ref(self.verts, self.vert_data_size))

  return self
end

function DynamicGeometry:update_indices()
  if not self._ibh then return end

  bgfx.update_dynamic_index_buffer(self._ibh, 0,
     bgfx.make_ref(self.indices, self.index_data_size))

  return self
end

function DynamicGeometry:bind()
  if not check_built(self) then return end

  bgfx.set_dynamic_vertex_buffer(self._vbh, 0, bgfx.UINT32_MAX)
  bgfx.set_dynamic_index_buffer(self._ibh, 0, bgfx.UINT32_MAX)
end

m.StaticGeometry    = StaticGeometry -- 'export' Geometry
m.DynamicGeometry   = DynamicGeometry
m.TransientGeometry = TransientGeometry

return m
