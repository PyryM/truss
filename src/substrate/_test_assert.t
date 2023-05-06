local m = {}

local function test_asserts(jape)
  local substrate = require("substrate")
  local cfg = substrate.configure()
  local test, expect = jape.test, jape.expect

  local terra assert_positive(x: int32)
    [cfg.ASSERT(`x > 0, "X must be positive!")]
    return true
  end

  test("assert doesn't crash", function()
    expect(assert_positive(10)):to_be_truthy()
  end)

  -- TODO: subprocess for failing asserts
  test.skip("failed assert works", function()
    expect(function()
      assert_positive(-10)
    end):to_terminate()
  end)
end

function m.init(jape)
  (jape or require("dev/jape.t")).describe("asserts", test_asserts)
end

return m