-- native/commontypes.t
--
-- utility types

local m = {}

terra m.cstrlen(str: &int8): uint64
  var len: uint64 = 0
  while str[len] ~= 0 do
    len = len + 1
  end
  return len
end

terra m.bounded_cstrlen(str: &int8, maxlen: uint64): uint64
  var len: uint64 = 0
  while len < maxlen and str[len] ~= 0 do
    len = len + 1
  end
  return len
end

local struct SizedString {
  str: &int8;
  len: uint64;
}

terra SizedString:from_c_string(_str: &int8)
  self.str = _str
  self.len = m.cstrlen(_str)
end

terra SizedString:as_u8(): &uint8
  return [&uint8](self.str)
end

terra SizedString:equals(str: &int8): bool
  var srclen = 0
  for i = 0, self.len do
    if str[i] == 0 then break end
    if self.str[i] ~= str[i] then return false end
    srclen = srclen + 1
  end
  return srclen == self.len
end

m.SizedString = SizedString

terra m.wrap_c_str(str: &int8): SizedString
  var ret: SizedString
  ret:from_c_string(str)
  return ret
end

function m.wrap_lua_const_str(s)
  local slen = #s
  return `SizedString{s, slen}
end

local struct Rect32 {
  x: int32;
  y: int32;
  w: int32;
  h: int32;
}
m.Rect32 = Rect32

return m