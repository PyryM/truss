-- stlloader.t
--
-- loads binary STL files

local m = {}
local math = require("math")
local Vector = math.Vector
local vec4 = require("math/types.t").vec4_

m.verbose = false
m.MAXFACES = 21845 -- each face needs 3 vertices, to fit into 16 bit index
            -- buffer we can have at most floor(2^16 / 3) faces

local tic, toc = truss.tic, truss.toc

function m.load_stl(filename, invert)
  local starttime = tic()
  local src_message = truss.C.load_file(filename)
  if src_message == nil then
    log.error("Error: unable to open file " .. filename)
    return nil
  end

  local ret = m.parse_binary_stl(src_message.data, src_message.data_length, invert)
  truss.C.release_message(src_message)
  local dtime = toc(starttime)
  log.info("Loaded " .. filename .. " in " .. (dtime*1000.0) .. " ms")
  return ret
end

m.load = m.load_stl

-- read a little endian uint32
terra m.read_uint32_le(buffer: &uint8, startpos: uint32)
  var ret: uint32 = [uint32](buffer[startpos  ])       or
            [uint32](buffer[startpos+1]) << 8  or
            [uint32](buffer[startpos+2]) << 16 or
            [uint32](buffer[startpos+3]) << 24
  return ret
end

-- read a little endian uint16
terra m.read_uint16_le(buffer: &uint8, startpos: uint32)
  var ret: uint16 = [uint16](buffer[startpos  ]) or
            [uint16](buffer[startpos+1]) << 8
  return ret
end

-- read a uint8
terra m.read_uint8(buffer: &uint8, startpos: uint32)
  return buffer[startpos]
end

local terra sanitize_nan(v: float)
  if v == v then
    return v
  else
    return 0.0f
  end
end

terra m.read_f32(buffer: &uint8, startpos: uint32)
  var retptr: &float = [&float](&(buffer[startpos]))
  return sanitize_nan(@retptr)
end

terra m.str_to_uint8_ptr(src: &int8)
  var ret: &uint8 = [&uint8](src)
  return ret
end

function m.parse_binary_stl(databuf, datalength, invert)
  if m.verbose then
    log.debug("Going to parse a binary stl of length " .. tonumber(datalength))
  end

  local faces = m.read_uint32_le( databuf, 80 )
  if m.verbose then
    log.debug("STL contains " .. faces .. " faces.")
  end

  if faces > m.MAXFACES then
    log.warn("Warning: STL contains >2^16 vertices, will need 32bit index buffer")
  end

  local defaultR, defaultG, defaultB, alpha = 128, 128, 128, 255

  -- process STL header

  -- check for default color in header ("COLOR=rgba" sequence)
  -- by brute-forcing over the entire header space (80 bytes)
  for index = 0, 69 do -- for(index = 0; index < 80-10; ++index)
    if m.read_uint32_le(databuf, index) == 0x434F4C4F and -- COLO
       m.read_uint8(databuf, index + 4) == 0x52 and       -- R
       m.read_uint8(databuf, index + 5) == 0x3D then      -- =

      log.warn("Warning: .stl has face colors but color parsing not implemented yet.")

      defaultR = m.read_uint8(databuf, index + 6)
      defaultG = m.read_uint8(databuf, index + 7)
      defaultB = m.read_uint8(databuf, index + 8)
      alpha    = m.read_uint8(databuf, index + 9)
    end
  end

  if m.verbose then
    log.debug("stl color: " .. defaultR
              .. " " .. defaultG
              .. " " .. defaultB
              .. " " .. alpha)
  end

  -- file body
  local dataOffset = 84
  local faceLength = 12 * 4 + 2

  local offset = 0

  local vertices = {}
  local normals = {}
  local indices = {}

  local normalMult = 1.0
  if invert then normalMult = -1.0 end

  for face = 0, faces-1 do
    local start = dataOffset + face * faceLength

    local nx = normalMult * m.read_f32(databuf, start)
    local ny = normalMult * m.read_f32(databuf, start + 4)
    local nz = normalMult * m.read_f32(databuf, start + 8)

    -- indices is a normal lua array and 1-indexed
    if invert then
      indices[face+1] = {offset, offset+2, offset+1}
    else
      indices[face+1] = {offset, offset+1, offset+2}
    end

    for i = 1,3 do
      local vertexstart = start + i * 12

      -- vertices and normals are normal lua arrays and hence 1-indexed
      vertices[ offset + 1 ] =  {m.read_f32(databuf, vertexstart ),
                                  m.read_f32(databuf, vertexstart + 4 ),
                                   m.read_f32(databuf, vertexstart + 8 )}

      normals[ offset + 1 ] = {nx, ny, nz}
      offset = offset + 1
    end
  end -- face loop

  return {attributes = {position = vertices, normal = normals},
          indices = indices,
          color = {defaultR, defaultG, defaultB, alpha}}
end

local struct STLHeader {
  comment: int8[80];
  tricount: uint32;
}

local struct Vec3f {
  x: float;
  y: float;
  z: float;
}

terra Vec3f:init()
  self.x = 0
  self.y = 0
  self.z = 0
end

terra Vec3f:copy_farr(rhs: &float)
  self.x = rhs[0]
  self.y = rhs[1]
  self.z = rhs[2]
end

local struct Tri {
  normal: Vec3f;
  verts: Vec3f[3];
  attrib_byte_count: uint16;
}

terra Tri:init()
  self.normal:init()
  for i = 0, 3 do self.verts[i]:init() end
  self.attrib_byte_count = 0 -- this is just always 0
end

local STL_TRI_SIZE = 50

local terra put_triangle(target: &int8, tri: &Tri)
  var src = [&int8](tri)
  for idx = 0, STL_TRI_SIZE do
    target[idx] = src[idx]
  end
end

function m.dump_geo(geo, dump_bytes)
  if not geo.allocated then truss.error("Geo not allocated") end
  local tricount = geo.n_indices / 3

  local bytecount = terralib.sizeof(STLHeader) + STL_TRI_SIZE*tricount
  local buff = terralib.new(int8[bytecount])

  local header = terralib.cast(&STLHeader, buff)
  print("Header size: " .. terralib.sizeof(STLHeader))

  local body = buff+terralib.sizeof(STLHeader)

  local name = geo.name or "truss geometry"
  for idx = 1, 80 do
    header.comment[idx-1] = name:byte(idx) or (" "):byte(1)
  end
  header.tricount = tricount

  local function V(idx)
    return geo.verts[geo.indices[idx]]
  end

  local fidx = 0
  local indices = geo.indices
  local has_normals = geo.verts[0].normal ~= nil

  local v0 = Vector()
  local v1 = Vector()
  local v2 = Vector()
  local vn = Vector()

  local tri = terralib.new(Tri)

  for tridx = 0, tricount-1 do
    local verts = {}
    tri:init()
    if has_normals then 
      tri.normal:copy_farr(V(fidx).normal) 
    else
      -- compute normal
      v0:from_carray(V(fidx+0).position, 3)
      v1:from_carray(V(fidx+1).position, 3)
      v2:from_carray(V(fidx+2).position, 3)
      v1:sub(v0):normalize3()
      v2:sub(v0):normalize3()
      vn:cross(v1, v2):normalize3()
      tri.normal.x = vn.elem.x
      tri.normal.y = vn.elem.y
      tri.normal.z = vn.elem.z
    end
    for i = 0, 2 do
      tri.verts[i]:copy_farr(V(fidx).position)
      fidx = fidx + 1
    end
    tri.attrib_byte_count = 0
    put_triangle(body + tridx*STL_TRI_SIZE, tri)
  end

  if dump_bytes then 
    return buff, bytecount
  else
    return ffi.string(buff, bytecount)
  end
end

function m.save_geo(filename, geo)
  local bytes, bytecount = m.dump_geo(geo, true)
  truss.C.save_data(filename, bytes, bytecount)
end

return m
