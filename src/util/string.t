-- stringutils.t
--
-- useful string manipulation utils

local class = require("class")
local m = {}

-- Split text into a list consisting of the strings in text,
-- separated by strings matching delimiter (which may be a pattern).
-- example: strsplit(",%s*", "Anna, Bob, Charlie,Dolores")
-- (from http://lua-users.org/wiki/SplitJoin)
local strfind = string.find
local tinsert = table.insert
local strsub = string.sub
function m.split(delimiter, text)
  local list = {}
  local pos = 1
  if strfind("", delimiter, 1) then -- this would result in endless loops
    log.error("delimiter matches empty string!")
  end
  while 1 do
    local first, last = strfind(text, delimiter, pos)
    if first then -- found?
      tinsert(list, strsub(text, pos, first-1))
      pos = last+1
    else
      tinsert(list, strsub(text, pos))
      break
    end
  end
  return list
end

-- trims whitespace around a string
-- 'trim5' from: http://lua-users.org/wiki/StringTrim
function m.strip(str)
  return str:match'^%s*(.*%S)' or ''
end

function m.split_lines(str)
  return m.split("\n", str)
end

function m.begins_with(str, prefix)
  return str:sub(1, #prefix) == prefix
end

function m.ends_with(str, suffix)
  return str:sub(-(#suffix)) == suffix
end

-- base64 conversion
local _b64_lut = nil
local letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
function m._create_b64_lut()
  if _b64_lut then return _b64_lut end

  _b64_lut = terralib.new(uint8[128])
  for i = 0,127 do
    _b64_lut[i] = 0
  end
  for i = 1,letters:len() do
    _b64_lut[string.byte(letters,i)] = i-1
  end
  return _b64_lut
end

local _b64_enc_lut = nil
function m._create_b64_enc_lut()
  if _b64_enc_lut then return _b64_enc_lut end
  _b64_enc_lut = terralib.new(uint8[64])
  for i = 0, 63 do
    _b64_enc_lut[i] = string.byte(letters, i+1)
  end
  return _b64_enc_lut
end

terra m.b64decode_terra(src: &uint8, srclen: uint32,
                        dest: &uint8, destlen: uint32,
                        lut: &uint8) : uint32
    var i: uint32 = 0
    var d: uint32 = 0
    while (i + 3 < srclen) and (d + 2 < destlen) do
      var accum: uint32 = 0
      -- note: this first or is necessary to force lut[...] into a uint32
      accum = (accum or lut[src[i+0]]) << 6
      accum = (accum or lut[src[i+1]]) << 6
      accum = (accum or lut[src[i+2]]) << 6
      accum =  accum or lut[src[i+3]]
      dest[d + 2] =  accum        and 0xFF
      dest[d + 1] = (accum >> 8 ) and 0xFF
      dest[d + 0] = (accum >> 16) and 0xFF
      i = i + 4
      d = d + 3
    end
    if srclen >= 2 then
      if src[srclen-1] == 61 then d = d - 1 end
      if src[srclen-2] == 61 then d = d - 1 end
    end
    return d
end

terra m.b64encode_terra(src: &uint8, srclen: uint32,
                        dest: &uint8, destlen: uint32,
                        lut: &uint8): uint32
  var i: uint32 = 0
  var j: uint32 = 0
  var buf: uint8[4]
  var tmp: uint8[3]
  var destpos: uint32 = 0

  -- parse until end of source
  var len: uint32 = srclen
  for srcpos = 0, srclen do
    -- read up to 3 bytes at a time into `tmp'
    tmp[i] = src[srcpos]
    i = i + 1

    -- if 3 bytes read then encode into `buf'
    if i == 3 then
      buf[0] = (tmp[0] and 0xfc) >> 2
      buf[1] = ((tmp[0] and 0x03) << 4) + ((tmp[1] and 0xf0) >> 4)
      buf[2] = ((tmp[1] and 0x0f) << 2) + ((tmp[2] and 0xc0) >> 6)
      buf[3] = tmp[2] and 0x3f

      -- allocate 4 new byts for `enc` and
      -- then translate each encoded buffer
      -- part by index from the base 64 index table
      -- into `enc' unsigned char array
      for ii = 0, 4 do
        dest[destpos] = lut[buf[ii]]
        destpos = destpos + 1
      end

      -- reset index
      i = 0
    end
  end

  -- remainder
  if i > 0 then
    -- fill `tmp' with `\0' at most 3 times
    for j = i, 3 do
      tmp[j] = 0
    end

    -- perform same codec as above
    buf[0] = (tmp[0] and 0xfc) >> 2
    buf[1] = ((tmp[0] and 0x03) << 4) + ((tmp[1] and 0xf0) >> 4)
    buf[2] = ((tmp[1] and 0x0f) << 2) + ((tmp[2] and 0xc0) >> 6)
    buf[3] = tmp[2] and 0x3f

    -- perform same write to `enc` with new allocation
    for j = 0, (i + 1) do
      dest[destpos] = lut[buf[j]]
      destpos = destpos + 1
    end

    -- while there is still a remainder
    -- append `=' to `enc'
    for kk = i, 3 do
      dest[destpos] = [string.byte('=')]
      destpos = destpos + 1
    end
  end

  -- Make sure we have enough space to add '\0' character at end.
  dest[destpos] = 0

  return destpos
end

function m.b64decode_raw(src, srclen, dest, destlen)
  local lut = m._create_b64_lut()
  return m.b64decode_terra(src, srclen, dest, destlen, lut)
end

function m.b64encode_raw(src, srclen, dest, destlen)
  local lut = m._create_b64_enc_lut()
  src = terralib.cast(&uint8, src)
  return m.b64encode_terra(src, srclen, dest, destlen, lut)
end

function m.u8_to_hex(data, datasize)
  local ret = {}
  for i = 0, datasize-1 do
    ret[i+1] = ("%02x"):format(data[i])
  end
  return table.concat(ret, "")
end

function m.hex_to_u8(hex_str, dest, destsize)
  if (#hex_str) % 2 ~= 0 then
    truss.error("Hex string must be a whole number of bytes.")
  end
  local nb = #hex_str / 2
  if dest then
    if (not destsize) or (destsize < nb) then
      truss.error("Provided destination buffer too small!")
    end
  else
    dest = terralib.new(uint8[nb])
    destsize = nb
  end
  local dpos = 0
  for idx = 1, #hex_str, 2 do
    dest[dpos] = tonumber(hex_str:sub(idx, idx+1), 16)
    dpos = dpos+1
  end
  return dest, destsize
end

function m.str_to_u8(s)
  local u8str = terralib.cast(&uint8, s)
  local slen = #s
  return u8str, slen
end

local ByteBuffer = class("ByteBuffer")
function ByteBuffer:init(maxsize)
  self._data = terralib.new(uint8[maxsize])
  self._max_buffer_size = maxsize
  self._cur_size = 0
end

terra m._buff_append(src: &uint8, srclen: uint32,
                          dest: &uint8, destpos: uint32, destsize: uint32) : uint32
  var d: uint32 = destpos
  var s: uint32 = 0
  while (d < destsize) and (s < srclen) do
    dest[d] = src[s]
    s = s + 1
    d = d + 1
  end
  return d
end

terra m._buff_append_str(src: &int8, srclen: uint32,
                    dest: &uint8, destpos: uint32, destsize: uint32) : uint32
  var usrc: &uint8 = [&uint8](src)
  return m._buff_append(usrc, srclen, dest, destpos, destsize)
end

function ByteBuffer:append(s)
  self._cur_size = m._buff_append_str(s, s:len(),
                      self._data, self._cur_size, self._max_buffer_size)
  return self
end

function ByteBuffer:append_bytes(b, nbytes)
  self._cur_size = m._buff_append(b, nbytes,
                      self._data, self._cur_size, self._max_buffer_size)
  return self
end

function ByteBuffer:append_struct(obj, objsize)
  local data = terralib.cast(&uint8, obj)
  self._cur_size = m._buff_append(data, objsize,
                      self._data, self._cur_size, self._max_buffer_size)
  return self
end

function ByteBuffer:__tostring()
  return ffi.string(self._data, self._cur_size)
end

function ByteBuffer:length()
  return self._cur_size
end

function ByteBuffer:clear()
  self._cur_size = 0
end

function ByteBuffer:write_to_file(filename)
  truss.write_buffer(filename, self._data, self._cur_size)
end

m.ByteBuffer = ByteBuffer
return m
