local m = {}

local _b64_dec_lut, _b64_enc_lut = nil, nil
do
  local letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
  local lut = {}
  for i = 0,127 do
    lut[i+1] = 0
  end
  for i = 1, letters:len() do
    lut[string.byte(letters,i) + 1] = i-1
  end
  _b64_dec_lut = terralib.constant(`arrayof(uint8, [lut]))

  local lut = {}
  for i = 1, 64 do
    lut[i] = string.byte(letters, i)
  end
  _b64_enc_lut = terralib.constant(`arrayof(uint8, [lut]))
end

terra m.decode_raw(ssrc: &int8, srclen: uint32,
                        dest: &uint8, destlen: uint32) : uint32
  var src: &uint8 = [&uint8](ssrc)
  var i: uint32 = 0
  var d: uint32 = 0
  while (i + 3 < srclen) and (d + 2 < destlen) do
    var accum: uint32 = 0
    -- note: this first or is necessary to force lut[...] into a uint32
    accum = (accum or _b64_dec_lut[src[i+0]]) << 6
    accum = (accum or _b64_dec_lut[src[i+1]]) << 6
    accum = (accum or _b64_dec_lut[src[i+2]]) << 6
    accum =  accum or _b64_dec_lut[src[i+3]]
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

terra m.encoded_length(srclen: uint32): uint32
  -- every three bytes turns into four
  var nblocks = srclen / 3
  if srclen % 3 > 0 then nblocks = nblocks + 1 end
  return nblocks*4
end

terra m.encode_raw(src: &uint8, srclen: uint32,
                   dest: &uint8, destlen: uint32): uint32
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
        dest[destpos] = _b64_enc_lut[buf[ii]]
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
      dest[destpos] = _b64_enc_lut[buf[j]]
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
  -- dest[destpos] = 0

  return destpos
end

--[[
terra m.b64_decode(src: SizedString, dest: &ByteBuffer)
  -- todo
end

terra m.b64_encode(src: &ByteBuffer, dest: &ByteBuffer)
  -- todo
end
]]

return m