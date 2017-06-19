-- devtools/test_tests.t
--
-- tests the testing framework

local testlib = require("devtools/test.t")
local test = testlib.test

function run_tests()
  local passed = 0
  local failed = 0
  local clock = 0

  -- test(function(event, testfunc, msg)
  --     if event == 'begin' then
  --         print('Started test', testfunc)
  --         passed = 0
  --         failed = 0
  --         clock = os.clock()
  --     elseif event == 'end' then
  --         print('Finished test', testfunc, passed, failed, os.clock() - clock)
  --     elseif event == 'pass' then
  --         passed = passed + 1
  --     elseif event == 'fail' then
  --         print('FAIL', testfunc, msg)
  --         failed = failed + 1
  --     elseif event == 'except' then
  --         print('ERROR', testfunc, msg)
  --     end
  -- end)

  -- Simple synchronous test
  test('This should fail', function(t)
    t.ok(2+2 == 5, 'two plus two equals five')
  end)
  test('This should succeed', function(t)
    t.ok("foo" == "foo", 'foo is foo')
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
end

function test_list_dir()
  local dlist = truss.list_directory("scripts/gfx")
  for _, fn in ipairs(dlist) do
    print(fn)
  end
end

function init()
  testlib.run_tests("")
  --test_list_dir()
  --run_tests()
end

function update()
  truss.quit()
end