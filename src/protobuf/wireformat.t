-- protobuf/wireformat.t
--
-- low-level functions for dealing with the protobuf wire format

local m = {}

local substrate = require("substrate")

local size_t = substrate.configure().size_t
local ByteArray = substrate.ByteArray
local Vec = substrate.Vec

local struct buffer_t {
  data: &uint8;
  len: size_t;
  pos: size_t;
  flags: size_t;
}
m.buffer_t = buffer_t

local struct key_t {
  field_number: uint32;
  wire_type: uint32;
}
m.key_t = key_t

local struct slice_t {
  data: &uint8;
  len: size_t;
}
m.slice_t = slice_t

terra slice_t:init()
  self:clear()
end

terra slice_t:clear()
  self.data = nil
  self.len = 0
end

terra slice_t:release()
  self:clear()
end

-- WARNING! THIS SHALLOW COPIES SLICES!
terra slice_t:copy(rhs: &slice_t)
  self.data = rhs.data
  self.len = rhs.len
end

terra slice_t:move(src: &slice_t)
  self:copy(src)
end

terra slice_t:as_buffer(): buffer_t
  return buffer_t{self.data, self.len, 0, 0}
end

terra slice_t:from_string(str: &int8, len: size_t)
  self.data = [&uint8](str)
  self.len = len
end

local FLAG_ERROR = -1
local WIRE_TYPES = {
  int32=0, int64=0, uint32=0, uint64=0, sint32=0, sint64=0, bool=0, enum=0,
  fixed64=1, sfixed64=1, double=1,
  string=2, bytes=2, __message=2, __packed=2,
  fixed32=5, sfixed32=5, float=5
}
local C_TYPES = {
  int32=int32, int64=int64, uint32=uint32, uint64=uint64, 
  sint32=int32, sint64=int64, bool=bool, enum=int32,
  fixed64=uint64, sfixed64=int64, double=double,
  fixed32=uint32, sfixed32=int32, float=float,
  string=slice_t, bytes=slice_t
}
m.FLAG_ERROR, m.WIRE_TYPES, m.C_TYPES = FLAG_ERROR, WIRE_TYPES, C_TYPES

function m.ASSERT_BUFF_OK(buff, failure_value)
  return quote
    if buff.flags == FLAG_ERROR then
      return failure_value
    end
    if buff.pos > buff.len then
      return failure_value
    end
  end
end

terra m.encode_sint32(value: int32): uint32
  var ind: uint32 = 0
  if value < 0 then ind = -1 end -- not 0 end
  return ([uint32](value) << 1) ^ ind
end

terra m.decode_sint32(value: uint32): int32
  return (value >> 1) ^ -([int32](value and 0x1))
end

terra m.encode_sint64(value: int64): uint64
  var ind: uint64 = 0
  if value < 0 then ind = -1 end -- not 0 end
  return ([uint64](value) << 1) ^ ind
end

terra m.decode_sint64(value: uint64): int64
  return (value >> 1) ^ -([int64](value and 0x1))
end

terra buffer_t:init()
  self.data = nil
  self.len = 0
  self.pos = 0
  self.flags = 0
end

terra buffer_t:clear()
  self.pos = 0
  self.flags = 0
end

terra buffer_t:view_raw(data: &uint8, datasize: uint32)
  self.data = data
  self.len = datasize
  self.pos = 0
  self.flags = 0
end

terra buffer_t:view(src: &ByteArray)
  -- TODO: CORRECTNESS of using src.capacity and not src.size?
  self:view_raw(src.data, src.capacity)
end

terra buffer_t:read_raw_bytes(dest: &uint8, n_bytes: uint8)
  if self.pos + n_bytes > self.len then
    self.flags = FLAG_ERROR
    return
  end
  var pos = self.pos
  var data = self.data
  for p = 0, n_bytes do
    dest[p] = data[pos + p]
  end
  self.pos = self.pos + n_bytes
end

terra buffer_t:write_raw_bytes(src: &uint8, n_bytes: size_t): int64
  if self.pos + n_bytes > self.len then
    self.flags = FLAG_ERROR
    return -1
  end
  var pos = self.pos
  var data = self.data
  substrate.intrinsics.memcpy(
    [&uint8](self.data + pos), 
    [&uint8](src), 
    n_bytes
  )
  self.pos = self.pos + n_bytes
  return n_bytes
end

terra buffer_t:read_varint_u64(): uint64
  var result: uint64 = 0
  var shift: uint32 = 0
  var src = self.data
  var pos = self.pos
  var srclen = self.len
  var terminated = false
  while pos < srclen do
    var curbyte = src[pos]
    result = result or ([uint64](curbyte and 0x7f) << shift)
    pos = pos + 1
    shift = shift + 7
    if (curbyte and 0x80) == 0 then 
      terminated = true
      break 
    end
  end
  self.pos = pos
  if not terminated then self.flags = FLAG_ERROR end
  return result
end

terra buffer_t:write_varint_u64(val: uint64): uint32
  var dest = self.data
  var pos = self.pos
  var destlen = self.len
  var terminated = false
  while pos < destlen do
    var encoded: uint8 = val and 0x7f
    val = val >> 7
    if val > 0 then encoded = encoded or 0x80 end
    dest[pos] = encoded
    pos = pos + 1
    if val == 0 then 
      terminated = true
      break 
    end
  end
  var nwritten: uint32 = pos - self.pos
  self.pos = pos
  if not terminated then self.flags = FLAG_ERROR end
  return nwritten
end

terra buffer_t:read_key(): key_t
  var uval = self:read_varint_u64()
  var wire_type = uval and 0x7
  var field_number = uval >> 3
  return m.key_t{field_number, wire_type}
end

terra buffer_t:write_key(field_number: uint32, wire_type: uint32): uint32
  -- warning: don't try to have ridiculous field numbers
  return self:write_varint_u64((field_number << 3) or wire_type)
end

terra buffer_t:read_blob(): slice_t
  var length = self:read_varint_u64()
  var pos = self.pos
  if pos + length > self.len then
    self.flags = FLAG_ERROR
    return slice_t{nil, 0}
  end
  self.pos = self.pos + length
  return slice_t{self.data + pos, length}
end

-- reads and discards any value
terra buffer_t:discard_value(wire_type: uint8): bool
  switch [uint32](wire_type) do
    case 0 then
      -- 0 Varint	int32, int64, uint32, uint64, sint32, sint64, bool, enum
      self:read_varint_u64()
    case 1 then
      -- 1 64-bit	fixed64, sfixed64, double
      self.pos = self.pos + 8
    case 2 then
      -- 2 Length-delimited	string, bytes, embedded messages, packed repeated fields
      self:read_blob()
    case 5 then
      -- 5 32-bit	fixed32, sfixed32, float
      self.pos = self.pos + 4
    end
  else
    return false
  end
  [m.ASSERT_BUFF_OK(`self, false)]
  return true
end

terra buffer_t:has_more(): bool
  return self.pos < self.len
end

terra buffer_t:check_status(): bool
  return (self.pos <= self.len) and (self.flags ~= FLAG_ERROR)
end

local struct marker_t {
  pos: size_t;
  val: uint64;
}

terra marker_t:byte_len(): uint32
  var v = self.val
  if v == 0 then return 1 end
  var nb: uint32 = 0
  while v > 0 do
    v = v >> 7
    nb = nb + 1
  end
  return nb
end

local struct encode_state_t {
  buff: buffer_t;
  markers: Vec(marker_t);
}
m.encode_state_t = encode_state_t

terra encode_state_t:init()
  self.buff:init()
  self.markers:init()
end

terra encode_state_t:clear()
  self.buff:clear()
  self.markers:release()
end

terra encode_state_t:allocate_markers(n: uint32)
  self.markers:resize_capacity(n)
end

terra encode_state_t:place_size_marker(): uint64
  var position = self.buff.pos
  var marker = self.markers:push_new()
  marker.pos = position
  marker.val = 0
  return self.markers.size - 1
end

terra encode_state_t:get_size_marker(idx: uint64): &marker_t
  return self.markers.data + idx
end

terra encode_state_t:compress(target: &buffer_t)
  var datapos = 0
  var markers = self.markers.data
  var nmarkers = self.markers.size
  var data = self.buff.data
  var datalen = self.buff.pos
  for marker_idx = 0, nmarkers do
    var cur_marker = markers[marker_idx]
    if datapos < cur_marker.pos then
      target:write_raw_bytes(data + datapos, cur_marker.pos - datapos)
    end
    target:write_varint_u64(cur_marker.val)
    datapos = cur_marker.pos
  end
  if datapos < datalen then
    target:write_raw_bytes(data + datapos, datalen - datapos)
  end
end

terra encode_state_t:write_raw_bytes(data: &uint8, len: size_t): int64
  return self.buff:write_raw_bytes(data, len)
end

terra encode_state_t:write_key(field_number: uint32, wire_type: uint32): uint32
  return self.buff:write_key(field_number, wire_type)
end

terra encode_state_t:write_varint_u64(val: uint64): uint32
  return self.buff:write_varint_u64(val)
end

return m