-- test argument parsing

local argparse = require("./argparse.t")
local m = {}

local function test_argparse(t)
  local args = {
    "truss", "examples/something.t", 
    "--v", "--foo", "A", "B", "--bar", "C"
  }
  local p = argparse.parse(args)
  t.expect(p['--v'], true, "correct args")
  t.expect(p['--foo'], {"A", "B"}, "correct args")
  t.expect(p['--bar'], "C", "correct args")
end

function m.run(test)
  test("argparse", test_argparse)
end

return m