-- moonscript/_test_moonscript.t
--
-- moonscript tests

local testlib = require("devtools/test.t")
local test = testlib.test
local m = {}

local function test_loading(t)
  local ms = require("moonscript")
  t.ok(ms.moonscript ~= nil, "moonscript loaded")

  local src = [[
MY_CONSTANT = "hello"

my_function = -> print "the function"
my_second_function = -> print "another function"

{ :my_function, :my_second_function, :MY_CONSTANT}
  ]]
  local f, linetable = ms.transpile(src)
  t.ok(f ~= nil, "moonscript transpiled something")

  local res = ms.loadstring(src, "@some_function")
  t.ok(res ~= nil, "loadstring worked")
  res = res()
  t.expect(res.MY_CONSTANT, "hello", "transpiled lua did something")

  local some_module = require("moonscript/test.moon")
  local v = some_module.rand_vector()
  print(v)
  t.ok(v ~= nil, "called a function")
end

function m.run()
  test("moonscript loading", test_loading)
end

return m