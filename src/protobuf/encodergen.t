-- protobuf/encodergen.t
--
-- generates encoders

local wf = require("./wireformat.t")

local m = {}

local function encode_varnum(T, converter, tag)
  local ret = nil
  if converter then 
    ret = terra(buff: &wf.encode_state_t, src: &T): int64
      return buff:write_varint_u64(converter(@src))
    end
  else
    ret = terra(buff: &wf.encode_state_t, src: &T): int64
      return buff:write_varint_u64([uint64](@src))
    end
  end
  ret:setname("encode_varnum_" .. (tag or "") .. T.name)
  return ret
end

-- this could cause endianness issues but nobody uses big-endian anyway!
local function encode_punned(T)
  local num_bytes = terralib.sizeof(T)
  local struct pun {
    union {
      bytes: uint8[num_bytes]
      v: T
    }
  }
  local ret = terra(buff: &wf.encode_state_t, src: &T): int64
    var p: pun
    p.v = @src
    return buff:write_raw_bytes(&(p.bytes[0]), num_bytes)
  end
  ret:setname("encode_punned_" .. T.name)
  return ret
end

local terra encode_bytes(buff: &wf.encode_state_t, src: &wf.slice_t): int64
  var total: int64 = buff:write_varint_u64(src.len)
  total = total + buff:write_raw_bytes(src.data, src.len)
  return total
end

local terra from_bool(val: bool): uint64
  if val then return 1 else return 0 end
end

local BASE_ENCODERS = {}
BASE_ENCODERS["double"] = encode_punned(double)
BASE_ENCODERS["float"] = encode_punned(float)
BASE_ENCODERS["fixed32"] = encode_punned(uint32)
BASE_ENCODERS["sfixed32"] = encode_punned(int32)
BASE_ENCODERS["fixed64"] = encode_punned(uint64)
BASE_ENCODERS["sfixed64"] = encode_punned(int64)

-- TODO: refactor this w/ equivalent struct in decodergen.t
local FLATPACKABLE = {}
for k, _ in pairs(BASE_ENCODERS) do FLATPACKABLE[k] = true end

BASE_ENCODERS["uint32"] = encode_varnum(uint32)
BASE_ENCODERS["int32"] = encode_varnum(int32)
BASE_ENCODERS["sint32"] = encode_varnum(int32, wf.encode_sint32, "s_")

BASE_ENCODERS["enum"] = encode_varnum(int32)

BASE_ENCODERS["int64"] = encode_varnum(int64)
BASE_ENCODERS["uint64"] = encode_varnum(uint64)
BASE_ENCODERS["sint64"] = encode_varnum(int64, wf.encode_sint64, "s_")

local CHECK_NON_DEFAULT = {}
local function check_nonzero(val)
  return `val ~= 0
end
for k, _ in pairs(BASE_ENCODERS) do CHECK_NON_DEFAULT[k] = check_nonzero end

BASE_ENCODERS["bool"] = encode_varnum(bool, from_bool)

local PACKABLE = {} -- all the base numeric types above can be packed
for k, _ in pairs(BASE_ENCODERS) do PACKABLE[k] = true end

BASE_ENCODERS["string"] = encode_bytes
BASE_ENCODERS["bytes"] = encode_bytes

CHECK_NON_DEFAULT["bool"] = function(val) return val end
CHECK_NON_DEFAULT["string"] = function(val)
  return `(val.data ~= nil) and (val.len > 0)
end
CHECK_NON_DEFAULT["bytes"] = CHECK_NON_DEFAULT["string"]

function m.prep_ctx(ctx)
  ctx.resolve_field = function(src, fieldinfo)
    local name = fieldinfo.name
    if fieldinfo.boxed then
      return `src.[name]:get_or_allocate()
    else
      return `&(src.[name])
    end
  end

  ctx.value_present = function(src, fieldinfo)
    local name = fieldinfo.name
    if fieldinfo.boxed then
      return `src.[name]:is_filled()
    elseif CHECK_NON_DEFAULT[fieldinfo.kind] then
      return CHECK_NON_DEFAULT[fieldinfo.kind](`src.[name])
    else
      return `true
    end
  end

  ctx.encoders = ctx.encoders or {}
end

local function _encode_single_field(ctx, fieldinfo, totalsize, buff, val)
  local idx, name, kind = fieldinfo.idx, fieldinfo.name, fieldinfo.kind
  local encoder = ctx.encoders[kind] or BASE_ENCODERS[kind]
  if not encoder then
    error("No encoder for [" .. kind .. "]!")
  end
  local wire_type = wf.WIRE_TYPES[kind] or wf.WIRE_TYPES.__message
  return quote
    totalsize = totalsize + buff:write_key(idx, wire_type)
    totalsize = totalsize + encoder(buff, val)
  end
end

local function _encode_repeated(ctx, fieldinfo, totalsize, buff, src)
  if FLATPACKABLE[fieldinfo.kind] then
    return quote
      var count = src.[fieldinfo.name].size
      if count > 0 then
        var bytes = src.[fieldinfo.name]:as_bytes()
        totalsize = totalsize + buff:write_key([fieldinfo.idx], wf.WIRE_TYPES.__packed)
        totalsize = totalsize + buff:write_varint_u64(bytes.size)
        totalsize = totalsize + buff:write_raw_bytes(bytes.data, bytes.size)
      end
    end
  elseif PACKABLE[fieldinfo.kind] then
    local encoder = BASE_ENCODERS[fieldinfo.kind]
    return quote
      var count = src.[fieldinfo.name].size
      if count > 0 then
        totalsize = totalsize + buff:write_key([fieldinfo.idx], wf.WIRE_TYPES.__packed)
        var length_marker_idx = buff:place_size_marker()
        var subsize: uint64 = 0
        for idx = 0, count do
          var val = src.[fieldinfo.name]:get_ref(idx)
          subsize = subsize + encoder(buff, val)
        end
        var length_marker = buff:get_size_marker(length_marker_idx)
        length_marker.val = subsize
        totalsize = totalsize + subsize + length_marker:byte_len()
      end
    end
  else
    return quote
      var count = src.[fieldinfo.name].size
      for idx = 0, count do
        var val = src.[fieldinfo.name]:get_ref(idx)
        [_encode_single_field(ctx, fieldinfo, totalsize, buff, val)]
      end
    end
  end
end

local function _encode_fields(ctx, schema, totalsize, buff, src)
  local statements = {}
  for _, fieldinfo in ipairs(schema.fields) do
    if fieldinfo.repeated then
      table.insert(statements, _encode_repeated(ctx, fieldinfo, totalsize, buff, src))
    elseif not fieldinfo.ignored then
      table.insert(statements, quote
        if [ctx.value_present(src, fieldinfo)] then
          var val = [ctx.resolve_field(src, fieldinfo)]
          [_encode_single_field(ctx, fieldinfo, totalsize, buff, val)]
        end
      end)
    end
  end 
  return statements
end

function m.generate_encoder(ctx, schema, T)
  local terra encode(buff: &wf.encode_state_t, src: &T): int64
    var totalsize: int64 = 0
    [_encode_fields(ctx, schema, totalsize, buff, src)]
    return totalsize
  end
  encode:setname("encode_" .. (schema.name or T.name):lower())
  return encode
end

function m.wrap_message_encoder(ctx, schema, T, encoder)
  local terra encode_message(buff: &wf.encode_state_t, src: &T): int64
    var length_marker_idx = buff:place_size_marker()
    var subsize = encoder(buff, src)
    if subsize < 0 then return subsize end
    var length_marker = buff:get_size_marker(length_marker_idx)
    length_marker.val = subsize
    return subsize + length_marker:byte_len()
  end
  encode_message:setname("encode_message_" .. (schema.name or T.name):lower())
  return encode_message
end

return m