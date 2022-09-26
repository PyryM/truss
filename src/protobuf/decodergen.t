-- protobuf/decodergen.t
--
-- generates decoders

local wf = require("./wireformat.t")
local m = {}

local function decode_varnum(T, converter, tag)
  local ret = nil
  if converter then 
    ret = terra(buff: &wf.buffer_t, target: &T): bool
      @target = converter(buff:read_varint_u64())
      return buff:check_status()
    end
  else
    ret = terra(buff: &wf.buffer_t, target: &T): bool
      @target = [T](buff:read_varint_u64())
      return buff:check_status()
    end
  end
  ret:setname("decode_varnum_" .. (tag or "") .. T.name)
  return ret
end

-- this could cause endianness issues but nobody uses big-endian anyway!
local function decode_punned(T)
  local num_bytes = terralib.sizeof(T)
  local struct pun {
    union {
      bytes: uint8[num_bytes]
      v: T
    }
  }
  local ret = terra(buff: &wf.buffer_t, target: &T): bool
    var p: pun
    buff:read_raw_bytes(&(p.bytes[0]), num_bytes)
    @target = p.v
    return buff:check_status()
  end
  ret:setname("decode_punned_" .. T.name)
  return ret
end

local terra decode_bytes(buff: &wf.buffer_t, target: &wf.slice_t): bool
  @target = buff:read_blob()
  return buff:check_status()
end

local terra to_bool(val: uint64): bool
  return val > 0
end

local BASE_DECODERS = {}
BASE_DECODERS["double"] = decode_punned(double)
BASE_DECODERS["float"] = decode_punned(float)
BASE_DECODERS["fixed32"] = decode_punned(uint32)
BASE_DECODERS["sfixed32"] = decode_punned(int32)
BASE_DECODERS["fixed64"] = decode_punned(uint64)
BASE_DECODERS["sfixed64"] = decode_punned(int64)

local FLATPACKABLE = {} -- all the fixed-size types above can be flat-packed
for k, _ in pairs(BASE_DECODERS) do FLATPACKABLE[k] = true end

BASE_DECODERS["uint32"] = decode_varnum(uint32)
BASE_DECODERS["int32"] = decode_varnum(int32)
BASE_DECODERS["sint32"] = decode_varnum(int32, wf.decode_sint32, "s_")

BASE_DECODERS["enum"] = decode_varnum(int32)

BASE_DECODERS["int64"] = decode_varnum(int64)
BASE_DECODERS["uint64"] = decode_varnum(uint64)
BASE_DECODERS["sint64"] = decode_varnum(int64, wf.decode_sint64, "s_")

BASE_DECODERS["bool"] = decode_varnum(bool, to_bool)

local PACKABLE = {} -- all the base numeric types above can be packed
for k, _ in pairs(BASE_DECODERS) do PACKABLE[k] = true end

BASE_DECODERS["string"] = decode_bytes
BASE_DECODERS["bytes"] = decode_bytes

function m.prep_ctx(ctx)
  ctx.noop = function(...) 
    return quote end 
  end

  ctx.log = ctx.log or ctx.noop

  ctx.err = ctx.err or function(...)
    local logged = ctx.log(...)
    return quote
      [logged]
      return false
    end
  end

  ctx.unknown_field = ctx.noop
  if ctx.strict or ctx.verbose then
    local action = (ctx.strict and err) or log
    ctx.unknown_field = function(fnum)
      return quote
        [action("Unknown field index [%d]!\n", fnum)]
      end
    end
  end

  ctx.resolve_field = function(target, fieldinfo)
    local name = fieldinfo.name
    if fieldinfo.boxed then
      return `target.[name]:get_ref()
    else
      return `&(target.[name])
    end
  end

  ctx.decoders = ctx.decoders or {}
end

local function _decode_repeated(ctx, fieldinfo, buff, target, wire_type)
  local idx, name, kind = fieldinfo.idx, fieldinfo.name, fieldinfo.kind
  local decoder = assert(BASE_DECODERS[kind] or ctx.decoders[kind])
  local expected_wire_type = wf.WIRE_TYPES[kind] or wf.WIRE_TYPES.__message

  local non_packed_decode = quote
    if wire_type ~= expected_wire_type then
      [ctx.err("Wire-type mismatch for %d [%s]: expected %d, found %d!\n", 
                idx, name, expected_wire_type, wire_type)]
      return false
    end
    var temp_target = target.[name]:push_new()
    if not decoder(buff, temp_target) then return false end
  end

  if FLATPACKABLE[kind] then
    -- optimization: repeated fixed-sized can be decoded by just memcpy'ing
    return quote
      if wire_type == wf.WIRE_TYPES.__packed then
        var sub_slice = buff:read_blob()
        target.[name]:push_bytes(sub_slice.data, sub_slice.len)
        if not buff:check_status() then return false end
      else
        [non_packed_decode]
      end
    end
  elseif PACKABLE[kind] then
    return quote
      if wire_type == wf.WIRE_TYPES.__packed then
        var sub_buf = buff:read_blob():as_buffer()
        while sub_buf:has_more() do
          if not decoder(&sub_buf, target.[name]:push_new()) then 
            return false 
          end
        end
        if not buff:check_status() then return false end
      else
        [non_packed_decode]
      end
    end
  else
    return non_packed_decode
  end
end

local function _decode_field(ctx, fieldinfo, buff, target, wire_type)
  local idx, name, kind = fieldinfo.idx, fieldinfo.name, fieldinfo.kind
  local decoder = assert(BASE_DECODERS[kind] or ctx.decoders[kind])
  local expected_wire_type = wf.WIRE_TYPES[kind] or wf.WIRE_TYPES.__message

  return quote
    if wire_type ~= expected_wire_type then
      [ctx.err("Wire-type mismatch for %d [%s]: expected %d, found %d!\n", 
                idx, name, expected_wire_type, wire_type)]
      return false
    end
    var target_field = [ctx.resolve_field(target, fieldinfo)]
    if not decoder(buff, target_field) then return false end
  end
end

function m._gen_cases(ctx, schema, buff, target, wire_type)
  local res = {}
  for _, fieldinfo in ipairs(schema.fields) do
    local body = nil
    if fieldinfo.ignored then
      body = quote buff:discard_value() end
    elseif fieldinfo.repeated then
      body = _decode_repeated(ctx, fieldinfo, buff, target, wire_type)
    else -- basic case: non-repeated, non-ignored field
      body = _decode_field(ctx, fieldinfo, buff, target, wire_type)
    end
    table.insert(res, quote
      case [fieldinfo.idx] then
        [body]
      end
    end)
  end
  return res
end

function m.generate_decoder(ctx, schema, T)
  local terra decode(buff: &wf.buffer_t, target: &T): bool
    while buff:has_more() do
      var key = buff:read_key()
      switch key.field_number do
        [m._gen_cases(ctx, schema, `buff, `target, `key.wire_type)]
      else
        buff:discard_value(key.wire_type)
        [ctx.unknown_field(`key.field_number)]
      end
      if buff.flags == wf.FLAG_ERROR then
        return false
      end
    end
    return true
  end
  decode:setname("decode_" .. (schema.name or T.name):lower())
  return decode
end

function m.wrap_message_decoder(ctx, schema, T, decoder)
  local terra decode_message(buff: &wf.buffer_t, target: &T): bool
    var sub_buf = buff:read_blob():as_buffer()
    if not buff:check_status() then return false end
    if not decoder(&sub_buf, target) then return false end
    return true
    -- TODO MAYBE: actually check all of value was consumed
  end
  decode_message:setname("decode_message_" .. (schema.name or T.name):lower())
  return decode_message
end

return m