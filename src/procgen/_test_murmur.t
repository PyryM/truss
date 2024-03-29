-- murmur hash tests

local m = {}

local function test_murmur(jape)
  local function conv_str(s)
    local u8str = terralib.cast(&uint8, s)
    local slen = #s
    return u8str, slen
  end
  
  local function hash_to_string(h)
    local s = ""
    for i = 0, 3 do
      s = s .. ("%08x"):format(h.u32[i])
    end
    return s
  end

  local murmur = require("./murmur.t")
  local test, expect = jape.test, jape.expect
  
  -- unfortunately I don't have any official test vectors to compare to
  -- so these just regression test against hashes generated by 
  -- an earlier version of this same implementation.
  --
  -- TODO: use snapshots?
  test("snapshot1", function()
    local str = "The quick brown fox jumps over the lazy dog"
    local s, l = conv_str(str)
    local h = murmur.murmur_128(s, l, 0)
    expect(hash_to_string(h)):to_be("eac1b5103440c20c03da6d8bb919abfe")
  end)

  test("snapshot2", function()
    local str = "The quick brown fox jumps over the lazy doh"
    local s, l = conv_str(str)
    local h = murmur.murmur_128(s, l, 0)
    expect(hash_to_string(h)):to_be("8c5ef325ff9bd97fe869e4797cf3dcf2")
  end)

  test("empty string hash", function()
    local s, l = conv_str("")
    local h = murmur.murmur_128(s, l, 1) -- note non-zero seed
    expect(hash_to_string(h)):to_be("6eff5cb54610abe578f8358351622daa")
  end)
end

function m.init(jape)
  (jape or require("dev/jape.t")).describe("murmur hash", test_murmur)
end

return m