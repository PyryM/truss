-- murmur hash tests

local m = {}

local function conv_str(s)
  local u8str = terralib.cast(&uint8, s)
  local slen = #s
  return u8str, slen
end

local struct hash {
  union {
    u64: uint64[2];
    u32: uint32[4];
  }
}

local function hash_to_string(h)
  local s = ""
  for i = 0, 3 do
    s = s .. ("%08x"):format(h.u32[i])
  end
  return s
end

local function test_murmur(t)
  local murmur = require("procgen/murmur.t")
  
  -- unfortunately I don't have any real test vectors to compare to
  -- so these tests just sanity check that it's producing *something*
  local dest1 = terralib.new(hash)
  local dest2 = terralib.new(hash)
  local s1, l1 = conv_str("The quick brown fox jumps over the lazy dog")
  local s2, l2 = conv_str("The quick brown fox jumps over the lazy doh")

  murmur.murmur_128(s1, l1, 0, dest1.u64)
  murmur.murmur_128(s2, l2, 0, dest2.u64)

  t.print("hash1: ", hash_to_string(dest1))
  t.print("hash2: ", hash_to_string(dest2))
  t.ok(dest1.u64[0] > 0, "Produced non-zero value")
  t.ok(dest1.u64[1] > 0, "Produced non-zero value")
  t.ok(dest1.u64[0] ~= dest2.u64[0], "Hashes are different")
  t.ok(dest1.u64[1] ~= dest2.u64[1], "Hashes are different")

  local s3, l3 = conv_str("") -- try empty string for laughs
  murmur.murmur_128(s3, l3, 1, dest1.u64) -- note non-zero seed
  t.print("Empty string hash: ", hash_to_string(dest1))
  t.ok(dest1.u64[0] > 0, "Empty string produced non-zero value")
  t.ok(dest1.u64[1] > 0, "Empty string produced non-zero value")
end

function m.run(test)
  test("murmur hash test", test_murmur)
end

return m