-- a failing test to make sure CI works

local m = {}

local function test_ci_failure(t)
  t.ok(false, "false == true")
end

function m.run(test)
  test("always fails", test_ci_failure)
end

return m