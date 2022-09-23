-- utf8 tests

local m = {}

local function conv_str(s)
  local u8str = terralib.cast(&uint8, s)
  local slen = #s
  return u8str, slen
end

local function pretty_byte_string(s)
  local frags = {}
  for idx = 1, #s do
    frags[idx] = ("%02x"):format(s:byte(idx))
  end
  return table.concat(frags)
end

local one_char_tests = {
  {"$", 0x0024, 1, "24"},
  {"¢", 0x00A2, 2, "c2a2"},
  {"ह", 0x0939, 3, "e0a4b9"},
  {"€", 0x20AC, 3, "e282ac"},
  {"한", 0xD55C, 3, "ed959c"},
  {"𐍈", 0x10348, 4, "f0908d88"}
}

local function test_decode(t)
  local utf8 = require("./utf8.t")

  for _, ex in ipairs(one_char_tests) do
    local str, codepoint, nbytes, hex = unpack(ex)
    t.expect(pretty_byte_string(str), hex, "Example itself is well formed")
    local decoded = utf8.decode_codepoint(conv_str(str), #str, 0)
    t.expect(decoded._0, nbytes, "Correct number of bytes read (" .. str .. ")")
    t.expect(decoded._1, codepoint, "Correct codepoint recovered (" .. str .. ")")
  end
end

function m.run(test)
  test("utf8 decode", test_decode)
end

return m