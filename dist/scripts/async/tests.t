-- async/tests.t
--

local testlib = require("devtools/test.t")
local test = testlib.test
local m = {}

function m.run()
  test("async", m.test_async)
end

function m.test_async(t)
  local async = require("async")

  -- test running a function which returns immediately
  local p = async.run(function()
    return "I ran"
  end)
  t.ok(p.value == "I ran", "async: immediate function return")

  -- test async yielding
  async.clear()
  local holdup = async.Promise()
  local p = async.run(function()
    return async.await(holdup)
  end)
  t.ok(p.value == nil, "async: function has yielded")
  holdup:resolve("I also ran")
  async.update()
  t.ok(p.value == "I also ran", "async: function continued")

  -- test yielding from event callbacks
  local event = require("ecs/event.t")
  local e = event.EventEmitter()
  async.clear()
  local p = async.run(function()
    local e_name, e_val = unpack(async.await_event(e, "button"))
    return e_val
  end)
  t.ok(p.value == nil, "async event: function has yielded")
  e:emit("button", 55)
  async.update()
  t.ok(p.value == 55, "async event: returned")

  -- test nested async
  async.clear()
  local function f_inner(e_name)
    local _, e_val = unpack(async.await_event(e, e_name))
    return e_val
  end

  ---- test without inner await
  local p = async.run(function()
    return f_inner("loaded")
  end)

  ---- test with inner await
  local p2 = async.run(function()
    return async.await_run(f_inner, "loaded")
  end)

  e:emit("loaded", 66)
  async.update()
  async.update()
  t.ok(p.value == 66, "async nested: returned")
  t.ok(p2.value == 66, "async nested await: returned")
end

return m