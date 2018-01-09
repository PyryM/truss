-- geometry.t
--
-- represent indexed geometry

local class = require("class")
local math = require("math")
local bufferutils = require("gfx/bufferutils.t")
local gfx = nil -- need to delay load

local Quaternion = math.Quaternion
local Matrix4 = math.Matrix4
local Vector = math.Vector

local m = {}

local last_geo_idx = 0

local StaticGeometry = class("StaticGeometry")
function StaticGeometry:init(name)
  self.name = name or "__anon_staticgeometry_" .. last_geo_idx
  last_geo_idx = last_geo_idx + 1
  self.allocated = false
  self.committed = false
end

local DynamicGeometry = class("DynamicGeometry")
function DynamicGeometry:init(name)
  self.name = name or "__anon_dyngeometry_" .. last_geo_idx
  last_geo_idx = last_geo_idx + 1
  self.allocated = false
  self.committed = false
end

local TransientGeometry = class("TransientGeometry")
function TransientGeometry:init(name)
  self.name = name or "__anon_transientgeometry_" .. last_geo_idx
  last_geo_idx = last_geo_idx + 1
  self.allocated = false

  self._transient_vb = terralib.new(bgfx.transient_vertex_buffer_t)
  self._transient_ib = terralib.new(bgfx.transient_index_buffer_t)
end

function TransientGeometry:allocate(n_verts, n_indices, vertinfo)
  if self.allocated and not self._bound then
    truss.error("TransientGeometry [" .. self.name ..
          "] must be bound before it can be allocated again!")
    return
  end

  if n_verts >= 2^16 then
    truss.error("TransientGeometry [" .. self.name ..
           "] cannot have more then 2^16 vertices.")
    return false
  end

  local verts_available = bgfx.get_avail_transient_vertex_buffer(n_verts,
                            vertinfo.vdecl)
  if verts_available < n_verts then
    log.error("Not enough space to allocate " .. n_verts .. " vertices.")
    return false
  end
  local indices_available = bgfx.get_avail_transient_index_buffer(n_indices)
  if indices_available < n_indices then
    log.error("Not enough space to allocate " .. n_indices .. " indices.")
    return false
  end

  bgfx.alloc_transient_buffers(self._transient_vb, vertinfo.vdecl, n_verts,
                    self._transient_ib, n_indices)

  self.indices = terralib.cast(&uint16, self._transient_ib.data)
  self.verts   = terralib.cast(&vertinfo.ttype, self._transient_vb.data)
  self.allocated = true

  return self
end

-- create what would typically be called a "fullscreen quad"
-- width and height default to 1.0, uv coordinates go 0-1
--
--     /|  actually implemented as a triangle that overflows the screen
--    /_|  <-- like this
--   /| |
--  /_|_|  hey it saves one triangle, that adds up
function TransientGeometry:fullscreen_tri(width, height, origin_bottom, vinfo)
  local minx = -width
  local maxx =  width
  local miny =  0.0
  local maxy =  height*2.0
  local minu = -1.0
  local maxu =  1.0
  local minv =  1.0 --v coordinate is flipped to account for texture coords
  local maxv = -1.0

  if origin_bottom then
    minv, maxv = 1, -1
  end

  if not vinfo then
    local vdefs = require("gfx/vertexdefs.t")
    vinfo = vdefs.create_basic_vertex_type({"position", "texcoord0"})
  end

  self:allocate(3, 3, vinfo)
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

function m.make_fast_transient_quad_func(vinfo)
  if not vinfo then
    local vdefs = require("gfx/vertexdefs.t")
    vinfo = vdefs.create_basic_vertex_type({"position", "texcoord0"})
  end
  local vtype = vinfo.ttype
  local vdecl = vinfo.vdecl
  local terra fastQuad(x0: float, y0: float, x1: float, y1: float, z: float)
    var vb: bgfx.transient_vertex_buffer_t
    var ib: bgfx.transient_index_buffer_t

    bgfx.alloc_transient_buffers(&vb, &vdecl, 4, &ib, 6)
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

    bgfx.set_transient_vertex_buffer(0, &vb, 0, 4)
    bgfx.set_transient_index_buffer(&ib, 0, 6)
  end
  return fastQuad
end

function TransientGeometry:quad(x0, y0, x1, y1, z, vinfo)
  if not vinfo then
    local vdefs = require("gfx/vertexdefs.t")
    vinfo = vdefs.create_basic_vertex_type({"position", "texcoord0"})
  end
  self:allocate(4, 6, vinfo)
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

  bgfx.set_transient_vertex_buffer(0, self._transient_vb, 0, bgfx.UINT32_MAX)
  bgfx.set_transient_index_buffer(self._transient_ib, 0, bgfx.UINT32_MAX)

  self._bound = true
  return self
end

function TransientGeometry:commit()
  -- transient buffers are committed when allocated, so this does nothing
  return self
end

function TransientGeometry:begin_frame()
  if self.allocated and not self._bound then
    log.warn("Allocating transient geometry without binding it the same frame will leak memory!")
  end

  self.indices = nil
  self.verts = nil
  self.allocated = false
  self._bound = false
  return self
end

function StaticGeometry:allocate(n_verts, n_indices, vertinfo)
  if self.allocated then truss.error("Geometry already allocated!") end

  local index_type = uint16
  if n_verts >= 2^16 then
    log.debug("Using 32 bit indices in index buffer!")
    index_type = uint32
  end
  self.index_type = index_type

  self.vertinfo = vertinfo
  self.verts = truss.allocate(vertinfo.ttype[n_verts])
  self.n_verts = n_verts
  self.indices = truss.allocate(index_type[n_indices])
  self.n_indices = n_indices
  self.vert_data_size = sizeof(vertinfo.ttype[n_verts])
  self.index_data_size = sizeof(index_type[n_indices])
  self.allocated = true
  return self
end
DynamicGeometry.allocate = StaticGeometry.allocate

function StaticGeometry:copy(src)
  if not src.allocated then truss.error("Cannot copy unallocated geometry") end
  self:allocate(src.n_verts, src.n_indices, src.vertinfo)
  for i = 0, (self.n_verts - 1) do
    self.verts[i] = src.verts[i]
  end
  for i = 0, (self.n_indices - 1) do
    self.indices[i] = src.indices[i]
  end
  return self
end
DynamicGeometry.copy = StaticGeometry.copy

function StaticGeometry:clone(name)
  return self.class(name):copy(self)
end
DynamicGeometry.clone = StaticGeometry.clone

-- release CPU memory for vertex and index buffers
function StaticGeometry:deallocate()
  local verts, indices = self.verts, self.indices
  self.verts, self.indices = nil, nil
  self.allocated = false

  -- edge case: after being committed, buffers can't be safely released
  -- until bgfx is done with them, which in multithreaded mode may be
  -- several frames later, so instead schedule the deletion by moving
  -- the buffer references into closure 'upvalues' that are cleared later
  if not self.committed then return self end
  gfx = gfx or require("gfx")
  gfx.schedule(function()
    verts, indices = nil, nil
  end)
  return self
end
DynamicGeometry.deallocate = StaticGeometry.deallocate

-- deprecated aliases for deallocate
StaticGeometry.release_backing = StaticGeometry.deallocate
DynamicGeometry.release_backing = DynamicGeometry.deallocate

function StaticGeometry:compute_bounds()
  if not self.allocated then 
    truss.error("Cannot compute bounds for unallocated geometry.") 
  end
  local n_verts = self.n_verts
  local sx, sy, sz = 0.0, 0.0, 0.0
  local r = 0.0
  -- compute cm and bounding radius *from origin*
  -- use double vectors to accumulate CM to avoid precision issues
  local cm_v = math.VectorD():zero()
  local tempv = math.VectorD():zero()
  for i = 0, n_verts - 1 do
    local p = self.verts[i].position
    tempv:set(p[0], p[1], p[2])
    cm_v:add(tempv)
    r = math.max(r, tempv:length3())
  end
  cm_v:divide(n_verts)
  -- compute bounding radius *from cm*
  local cm_r = 0.0
  for i = 0, n_verts - 1 do
    local p = self.verts[i].position
    tempv:set(p[0], p[1], p[2]):sub(cm_v)
    cm_r = math.max(cm_r, tempv:length3())
  end
  self.bounds = {
    origin_radius = r,
    radius = cm_r,
    center = math.Vector():copy(cm_v) -- convert to float vector
  }
  return self
end
DynamicGeometry.compute_bounds = StaticGeometry.compute_bounds

function StaticGeometry:set_indices(indices)
  bufferutils.set_indices(self, indices)
  return self
end
DynamicGeometry.set_indices = StaticGeometry.set_indices
TransientGeometry.set_indices = StaticGeometry.set_indices

function StaticGeometry:set_attribute(attrib_name, attrib_list)
  bufferutils.set_attribute(self, attrib_name, attrib_list)
  return self
end
DynamicGeometry.set_attribute = StaticGeometry.set_attribute
TransientGeometry.set_attribute = StaticGeometry.set_attribute

function StaticGeometry:from_data(modeldata, vertinfo, no_commit)
  if not modeldata then
    truss.error("Geometry:from_data: nil modeldata!")
  end

  local nindices = #modeldata.indices
  if type(modeldata.indices[1]) ~= "number" then -- list of lists format
    nindices = nindices * 3                      -- assume triangles
  end
  if not vertinfo then
    gfx = gfx or require("gfx")
    vertinfo = gfx.guess_vertex_type(modeldata)
  end
  self:allocate(#(modeldata.attributes.position), nindices, vertinfo)

  for a_name, a_data in pairs(modeldata.attributes) do
    self:set_attribute(a_name, a_data)
  end
  self:set_indices(modeldata.indices)

  if no_commit then return self else return self:commit() end
end
DynamicGeometry.from_data = StaticGeometry.from_data
TransientGeometry.from_data = StaticGeometry.from_data

function StaticGeometry:_create_bgfx_buffers(flags)
  self._vbh = bgfx.create_vertex_buffer(
      bgfx.make_ref(self.verts, self.vert_data_size),
      self.vertinfo.vdecl, flags )

  self._ibh = bgfx.create_index_buffer(
      bgfx.make_ref(self.indices, self.index_data_size), flags )
end

function DynamicGeometry:_mem_ref(data, datasize)
  -- In multithreaded mode we need to copy the underlying memory because
  -- bgfx will not actually look at it until several frames later.
  --
  -- In single threaded mode we can safely just pass in a reference to
  -- the memory.
  gfx = gfx or require("gfx")
  if self.force_unsafe_updates or gfx.single_threaded then
    return bgfx.make_ref(data, datasize)
  else
    return bgfx.copy(data, datasize)
  end
end

function DynamicGeometry:_create_bgfx_buffers(flags)
  self._vbh = bgfx.create_dynamic_vertex_buffer_mem(
      self:_mem_ref(self.verts, self.vert_data_size),
      self.vertinfo.vdecl, flags )

  self._ibh = bgfx.create_dynamic_index_buffer_mem(
      self:_mem_ref(self.indices, self.index_data_size), flags )
end

function StaticGeometry:commit()
  if not self.allocated then
    truss.error("Cannot commit geometry with no allocated data!")
  end

  if self.committed then
    log.warn("StaticGeometry: cannot commit, already committed.")
    return self
  end

  local flags = bgfx.BUFFER_NONE
  if self.index_type == uint32 then
    log.debug("Building w/ 32 bit index buffer!")
    flags = bgfx.BUFFER_INDEX32
  end

  self:_create_bgfx_buffers(flags)

  if not bgfx.check_handle(self._vbh) then truss.error("invalid vbh") end
  if not bgfx.check_handle(self._ibh) then truss.error("invalid ibh") end
  self.committed = true

  return self
end
DynamicGeometry.commit = StaticGeometry.commit

function StaticGeometry:uncommit()
  if self._vbh then bgfx.destroy_vertex_buffer(self._vbh) end
  if self._ibh then bgfx.destroy_index_buffer(self._ibh) end
  self._vbh, self._ibh = nil, nil
  self.committed = false
end

function DynamicGeometry:uncommit()
  if self._vbh then bgfx.destroy_dynamic_vertex_buffer(self._vbh) end
  if self._ibh then bgfx.destroy_dynamic_index_buffer(self._ibh) end
  self._vbh, self._ibh = nil, nil
  self.committed = false
end

function StaticGeometry:destroy()
  self:release_backing()
  self:uncommit()
end
DynamicGeometry.destroy = StaticGeometry.destroy

local function check_committed(geo)
  if geo.committed then return true end

  if not geo._warned then
    log.warn("Geometry [" .. geo.name .. "] has not been committed.")
    geo._warned = true
  end
  return false
end

function StaticGeometry:bind()
  if not check_committed(self) then return end

  bgfx.set_vertex_buffer(0, self._vbh, 0, bgfx.UINT32_MAX)
  bgfx.set_index_buffer(self._ibh, 0, bgfx.UINT32_MAX)
end

function StaticGeometry:bind_partial(start_v, n_v, start_i, n_i)
  if not check_committed(self) then return end

  bgfx.set_vertex_buffer(0, self._vbh, start_v, n_v)
  bgfx.set_index_buffer(self._ibh, start_i, n_i)
end

function DynamicGeometry:bind()
  if not check_committed(self) then return end

  bgfx.set_dynamic_vertex_buffer(0, self._vbh, 0, bgfx.UINT32_MAX)
  bgfx.set_dynamic_index_buffer(self._ibh, 0, bgfx.UINT32_MAX)
end

function DynamicGeometry:bind_partial(start_v, n_v, start_i, n_i)
  if not check_committed(self) then return end

  bgfx.set_dynamic_vertex_buffer(0, self._vbh, start_v, n_v)
  bgfx.set_dynamic_index_buffer(self._ibh, start_i, n_i)
end

function DynamicGeometry:update()
  if not self.committed then
    self:commit()
  else
    self:update_vertices()
    self:update_indices()
  end

  return self
end

function DynamicGeometry:update_vertices()
  if not self._vbh then return end

  bgfx.update_dynamic_vertex_buffer(self._vbh, 0,
    self:_mem_ref(self.verts, self.vert_data_size))

  return self
end

function DynamicGeometry:update_indices()
  if not self._ibh then return end

  bgfx.update_dynamic_index_buffer(self._ibh, 0,
    self:_mem_ref(self.indices, self.index_data_size))

  return self
end

m.StaticGeometry    = StaticGeometry
m.DynamicGeometry   = DynamicGeometry
m.TransientGeometry = TransientGeometry

return m
