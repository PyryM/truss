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
    return async.await(async.run(f_inner, "loaded"))
  end)

  e:emit("loaded", 66)
  async.update()
  async.update()
  t.ok(p.value == 66, "async nested: returned")
  t.ok(p2.value == 66, "async nested await: returned")

  -- test errors
  async.clear()
  local holdup = async.Promise()
  local p = async.run(function()
    local happy, err = async.pawait(holdup)
    return (happy and "happy") or err
  end)
  holdup:reject("some error")
  async.update()
  t.ok(p.value == "some error", "async errors: direct rejection")

  async.clear()
  local function inner_error(t)
    truss.error("intentional error")
  end
  local p = async.run(function()
    local happy, err = async.pawait(async.run(inner_error, {x = "b"}))
    print(err)
    return (happy and "happy") or "error"
  end)
  async.update()
  async.update()
  t.ok(p.value == "error", "async errors: throwing an error")

  -- test promise combinations
  async.clear()
  local p = async.run(function()
    local a = async.event_promise(e, "event_a")
    local b = async.event_promise(e, "event_b")
    local k, evt = unpack(async.await(async.any{apple = a, banana = b}))
    return k .. "_" .. evt[2]
  end)
  e:emit("event_b", "x")
  async.update()
  async.update()
  t.expect(p.value, "banana_x", "async any: returned k,v")

  async.clear()
  local p = async.run(function()
    local a = async.event_promise(e, "event_a")
    local b = async.event_promise(e, "event_b")
    local res = async.await(async.all{apple = a, banana = b})
    return res.apple[2] .. "_" .. res.banana[2]
  end)
  e:emit("event_b", "w")
  async.update()
  t.ok(p.value == nil, "async combination: all wait for all")
  e:emit("event_a", "z")
  async.update()
  t.expect(p.value, "z_w", "async combination: returned table of results")

  -- test frame waiting
  async.clear()
  local p = async.run(function()
    async.await_frames(1)
    return "foo"
  end)
  t.ok(p.value == nil, "async has yielded")
  async.update()
  t.ok(p.value == "foo", "async returned after one frame")

  -- test longer scheduling
  async.clear()
  local p = async.run(function()
    async.await(async.schedule(17))
    return "bar"
  end)
  local f = 0
  for i = 1, 20 do
    if p.value == "bar" then break end
    f = f + 1
    async.update()
  end
  t.expect(f, 17, "async schedule waited correct number of frames")

  -- test immediate async
  async.clear()
  local p = async.run(function()
    local vals = {}
    for i = 1,2 do
      local a = async.event_promise(e, "event_a")
      local b = async.event_promise(e, "event_b")
      local k, evt = unpack(async.await_immediate(async.any{apple = a, banana = b}))
      vals[k] = evt[2]
    end
    return vals
  end)
  e:emit("event_b", "x")
  e:emit("event_a", "y")
  async.update()
  t.ok(p.value and p.value.apple and p.value.banana, 
       "async immediate: got both events")

  -- test event queue
  async.clear()
  local p = async.run(function()
    local q = async.EventQueue()
    q:listen(e, "continue")
    q:listen(e, "stop")
    local n = 0
    for src, ename, evt in q:await_iterator() do
      if ename == "continue" then
        n = n + 1
      else
        return n
      end
    end
  end)
  e:emit("continue")
  async.update()
  e:emit("continue")
  e:emit("continue")
  e:emit("stop")
  async.update()
  t.expect(p.value, 3, "event queue recieved correct number of events")
end

return m