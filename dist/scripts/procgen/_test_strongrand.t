-- strongrand tests

local m = {}

local function test_srand(t)
  local srand = require("procgen/strongrand.t")
  local gen = srand.StrongRandom("some test seed")

  -- test byte generation
  local maxval = 0
  local minval = 1000
  for _ = 1, 10000 do
    local b = gen:rand_uint8()
    maxval = math.max(maxval, b)
    minval = math.min(minval, b)
  end
  t.ok(maxval == 255, "saw byte 255")
  t.ok(minval == 0, "saw byte 0")

  -- test range-limited generation
  local maxval = 0
  for _ = 1, 10000 do
    local b = gen:rand_unsigned(257)
    maxval = math.max(maxval, b)
  end
  t.ok(maxval == 256, "saw byte 256")

  -- test degenerate cases
  t.expect(gen:rand_unsigned(1), 0, "rand [0,1) returns 0")
  t.expect(gen:rand_unsigned(0), 0, "rand [0,0) returns 0")

  -- test big value generation
  local val = gen:rand_unsigned(100000)
  t.ok(val < 100000, "generated a big value?")

  -- test uniformity
  local counts = {0, 0, 0, 0}
  for _ = 1, 40000 do
    local b = gen:rand_unsigned(4) + 1
    counts[b] = counts[b] + 1
  end
  for idx = 1, 4 do
    t.ok(counts[idx] > 8000 and counts[idx] < 12000, "bucket seems uniform")
  end
end

function m.run(test)
  test("strong random", test_srand)
end

return m