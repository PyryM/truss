-- native/utf8.t
--
-- utf8 handling functions

local m = {}

local SPACE = (" "):byte(1)

local get_tail = macro(function(src, pos, shift)
  return `[uint32](src[pos] and 0x3f) << (shift*6) -- assume << 0 will be optimized out
end)

-- returns {bytes_read, value}
terra m.decode_codepoint(src: &uint8, srclen: uint64, pos: uint64): {uint32, uint32}
  -- assumes pos < srclen, src ~= nil
  var b0 = [uint32](src[pos])
  if (b0 and 0x80) == 0 then
    return {1, b0 and 0x7f}
  elseif b0 >> 5 == 0x6 then -- 2 bytes
    if pos+2 > srclen then return {1, 0} end
    var val = ((b0 and 0x1f) << 6)
            or get_tail(src, pos+1, 0)
    return {2, val}
  elseif (b0 >> 4) == 0xe then
    if pos+3 > srclen then return {1, 0} end
    var val = ((b0 and 0xf) << 12)
            or get_tail(src, pos+1, 1)
            or get_tail(src, pos+2, 0)
    return {3, val}
  elseif (b0 >> 3) == 0x1e then
    if pos+4 > srclen then return {1, 0} end
    var val = ((b0 and 0x7) << 18)
            or get_tail(src, pos+1, 2)
            or get_tail(src, pos+2, 1)
            or get_tail(src, pos+3, 0)
    return {4, val}
  else
    return {1, 0}
  end
end

terra m.codepoint_count(src: &uint8, srclen: uint64): uint32
  var count: uint32 = 0
  var srcpos: uint32 = 0
  while srcpos < srclen do
    var nbytes, uc = m.decode_codepoint(src, srclen, srcpos)
    if uc == 0 then break end -- invalid utf8 encountered
    srcpos = srcpos + nbytes
    count = count + 1
  end
  return count
end

terra m.codepoint_byte_index(src: &uint8, srclen: uint64, idx: uint32): int32
  var count: uint32 = 0
  var srcpos: uint32 = 0
  while count < idx and srcpos < srclen do
    var nbytes, uc = m.decode_codepoint(src, srclen, srcpos)
    if uc == 0 then break end -- invalid utf8 encountered
    srcpos = srcpos + nbytes
    count = count + 1
  end
  if count ~= idx then return -1 end
  return srcpos
end

terra m.wordstart_byte_index(src: &uint8, srclen: uint32, startpos: uint32): {int32, int32}
  var spacelength: int32 = 0
  while startpos < srclen do
    var nbytes, uc = m.decode_codepoint(src, srclen, startpos)
    if uc == 0 then return -1, 0 end
    if uc ~= SPACE then break end
    startpos = startpos + nbytes
    spacelength = spacelength + 1
  end 
  return startpos, spacelength
end

terra m.wordbreak_byte_index(src: &uint8, srclen: uint32, startpos: uint32): {int32, int32}
  var wordlength: int32 = 0
  while startpos < srclen do
    var nbytes, uc = m.decode_codepoint(src, srclen, startpos)
    if uc == 0 then return -1, 0 end
    if uc == SPACE then break end
    startpos = startpos + nbytes
    wordlength = wordlength + 1
  end 
  return startpos, wordlength
end

terra m.linebreak_byte_index(src: &uint8, srclen: uint32, linelen: uint32, startpos: uint32): {int32, int32}
  var start_idx, _ = m.wordstart_byte_index(src, srclen, startpos)
  if start_idx < 0 then 
    return -1, -1 
  end
  var total_chars: int32 = 0
  var stop_idx = start_idx
  while stop_idx < srclen do
    var cand_len: uint32 = total_chars
    var space_end, spacelen = m.wordstart_byte_index(src, srclen, stop_idx)
    if space_end < 0 then return -1, -1 end
    cand_len = cand_len + spacelen
    if cand_len > linelen then break end
    var word_end, wordlen = m.wordbreak_byte_index(src, srclen, space_end)
    if word_end < 0 then return -1, -1 end
    cand_len = cand_len + wordlen
    if cand_len > linelen then break end
    total_chars = cand_len
    stop_idx = word_end
  end
 
  return start_idx, stop_idx
end

return m