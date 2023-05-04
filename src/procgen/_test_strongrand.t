-- strongrand tests

local m = {}

local function test_srand(jape)
  local srand = require("procgen/strongrand.t")
  local test, expect = jape.test, jape.expect

  local gen
  jape.before_each(function()
    log.warn("Creating new strongrand!")
    gen = srand.StrongRandom("some test seed")
  end)

  test("byte generation", function()
    local maxval = 0
    local minval = 1000
    for _ = 1, 10000 do
      local b = gen:rand_uint8()
      maxval = math.max(maxval, b)
      minval = math.min(minval, b)
    end
    expect(maxval):toBe(255)
    expect(minval):toBe(0)
  end)

  test("range-limited generation", function()
    local maxval = 0
    for _ = 1, 10000 do
      local b = gen:rand_unsigned(257)
      maxval = math.max(maxval, b)
    end
    expect(maxval):toBe(256)
  end)

  test("degenerate cases", function()
    expect(gen:rand_unsigned(1)):toBe(0)
    expect(gen:rand_unsigned(0)):toBe(0)
  end)

  test("big value generation", function()
    local val = gen:rand_unsigned(100000)
    expect(val):toBeLessThan(100000)
  end)

  test("uniformity", function()
    local counts = {0, 0, 0, 0}
    for _ = 1, 40000 do
      local b = gen:rand_unsigned(4) + 1
      counts[b] = counts[b] + 1
    end
    for idx = 1, 4 do
      expect(counts[idx]):toBeInRange(8000, 12000)
    end
  end)
end

function m.init(jape)
  jape = jape or require("dev/jape.t")
  jape.describe("strong random", test_srand)
end

return m