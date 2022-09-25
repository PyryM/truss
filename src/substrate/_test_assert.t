local m = {}

local function test_asserts(t)
  local substrate = require("substrate")
  local cfg = substrate.configure()

  local terra assert_positive(x: int32)
    [cfg.ASSERT(`x > 0, "X must be positive!")]
    return true
  end

  t.ok(assert_positive(10), "assert doesn't crash")
  
  -- TODO: subprocess for failing asserts
  --assert_positive(-10)
end

function m.run(test)
  test("asserts", test_asserts)
end

return m