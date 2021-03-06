-- dev/test_tests.t
--
-- tests the testing framework

local testlib = require("dev/test.t")
local test = testlib.test

function run_tests()
  local passed = 0
  local failed = 0
  local clock = 0

  -- Simple synchronous test
  test('This should fail', function(t)
    t.ok(2+2 == 5, 'two plus two equals five')
  end)
  test('This should succeed', function(t)
    t.ok("foo" == "foo", 'foo is foo')
  end)
  test('This should succeed by having an error', function(t)
    t.err(function()
      truss.error("bleh")
    end)
  end)
  test('This should fail by not having an error', function(t)
    t.err(function()
      return 12
    end)
  end)
  test('Spies', function(t)
    local f = t.spy(function(s) return #s end)
    t.ok(f('hello') == 5)
    t.ok(f('foo') == 3)
    t.ok(#f.called == 2)
    t.ok(t.eq(f.called[1], {'hello'}))
    t.ok(t.eq(f.called[2], {'foo'}))
    f(nil)
    t.ok(f.errors[3] ~= nil)
  end)
  test('Memory spy', function(t)
    local retained = {bla = 12}
    local collected = {bla = 13}
    local h_ret = t.mem_spy(retained)
    local h_col = t.mem_spy(collected)
    collected = nil
    collectgarbage("collect")
    t.ok(h_ret:exists(), 'retained table is retained')
    t.ok(not h_col:exists(), 'collected table was collected')
  end)
end

function test_list_dir()
  local dlist = truss.list_directory("scripts/gfx")
  for _, fn in ipairs(dlist) do
    print(fn)
  end
end

function init()
  run_tests()
end

function update()
  truss.quit()
end
