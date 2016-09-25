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

function m.splitLines(str)
  return m.split("\n", str)
end

-- base64 conversion
local b64lut_ = nil
function m.createB64LUT_()
    if b64lut_ ~= nil then return b64lut_ end

    local letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
    local ret = terralib.new(uint8[128])
    for i = 0,127 do
        ret[i] = 0
    end
    for i = 1,letters:len() do
        ret[string.byte(letters,i)] = i-1
    end
    return ret
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

function m.b64decodeRaw(src, srclen, dest, destlen)
    if b64lut_ == nil then
        b64lut_ = m.createB64LUT_()
    end
    return m.b64decode_terra(src, srclen, dest, destlen, b64lut_)
end

local ByteBuffer = class("ByteBuffer")
function ByteBuffer:init(maxsize)
    self.data_ = terralib.new(uint8[maxsize])
    self.maxbuffsize_ = maxsize
    self.cursize_ = 0
end

terra m.helperFileWrite_(fn: &int8, data: &uint8, datalen: uint32)
    var temp_ptr: &int8 = [&int8](data)
    truss.C.save_data(fn, temp_ptr, datalen)
end

terra m.helperBuffAppend_(src: &uint8, srclen: uint32,
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

terra m.helperBuffAppendStr_(src: &int8, srclen: uint32,
                    dest: &uint8, destpos: uint32, destsize: uint32) : uint32
    var usrc: &uint8 = [&uint8](src)
    return m.helperBuffAppend_(usrc, srclen, dest, destpos, destsize)
end

function ByteBuffer:append(s)
    self.cursize_ = m.helperBuffAppendStr_(s, s:len(),
                        self.data_, self.cursize_, self.maxbuffsize_)
    return self
end

function ByteBuffer:appendBytes(b, nbytes)
    self.cursize_ = m.helperBuffAppend_(b, nbytes,
                        self.data_, self.cursize_, self.maxbuffsize_)
    return self
end

function ByteBuffer:appendStruct(obj, objsize)
    local data = terralib.cast(&uint8, obj)
    self.cursize_ = m.helperBuffAppend_(data, objsize,
                        self.data_, self.cursize_, self.maxbuffsize_)
    return self
end

function ByteBuffer:__tostring()
    return ffi.string(self.data_, self.cursize_)
end

function ByteBuffer:length()
    return self.cursize_
end

function ByteBuffer:clear()
    self.cursize_ = 0
end

function ByteBuffer:writeToFile(filename)
    truss.C.save_data(filename, self.data_, self.cursize_)
end

m.ByteBuffer = ByteBuffer
return m
