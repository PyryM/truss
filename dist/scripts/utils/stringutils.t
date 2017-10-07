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

-- base64 conversion
local _b64_lut = nil
function m._create_b64_lut()
  if _b64_lut then return _b64_lut end

  local letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
  _b64_lut = terralib.new(uint8[128])
  for i = 0,127 do
    _b64_lut[i] = 0
  end
  for i = 1,letters:len() do
    _b64_lut[string.byte(letters,i)] = i-1
  end
  return _b64_lut
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

function m.b64decode_raw(src, srclen, dest, destlen)
  local lut = m._create_b64_lut()
  return m.b64decode_terra(src, srclen, dest, destlen, lut)
end

local ByteBuffer = class("ByteBuffer")
function ByteBuffer:init(maxsize)
  self._data = terralib.new(uint8[maxsize])
  self._max_buffer_size = maxsize
  self._cur_size = 0
end

terra m.helperFileWrite_(fn: &int8, data: &uint8, datalen: uint32)
    var temp_ptr: &int8 = [&int8](data)
    truss.C.save_data(fn, temp_ptr, datalen)
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
  truss.C.save_data(filename, self._data, self._cur_size)
end

m.ByteBuffer = ByteBuffer
return m
