-- async/async.t
--
-- async event loop

local class = require("class")
local promise = require("async/promise.t")
local queue = require("utils/queue.t")
local m = {}

function m.clear()
  m._procs = {}
  m._resolve_queue = queue.Queue()
end
m.clear()

local function _step(proc, args, succeeded)
  local happy, ret
  if succeeded == nil then
    happy, ret = coroutine.resume(proc.co, unpack(args))
  else
    happy, ret = coroutine.resume(proc.co, succeeded, args)
  end
  if not happy then
    m._procs[proc] = nil -- kill proc?
    proc.promise:reject(ret)
    return
  end
  if coroutine.status(proc.co) == "dead" then
    m._procs[proc] = nil
    proc.promise:resolve(ret)
  elseif ret then
    ret:next(function(...)
      m._resolve(proc, ...)
    end,
    function(err)
      m._reject(proc, err)
    end)
  else
    truss.error("async function did not yield a promise")
  end
end

function m.run(f, ...)
  local proc = {
    co = coroutine.create(f),
    promise = promise.Promise()
  }
  m._procs[proc] = proc
  _step(proc, {...})
  return proc.promise
end

function m._resolve(proc, ...)
  m._resolve_queue:push({proc, true, {...}})
end

function m._reject(proc, err)
  m._resolve_queue:push({proc, false, err})
end

function m.update(maxtime)
  -- TODO: deal with maxtime
  while m._resolve_queue:length() > 0 do
    local proc, happy, args = unpack(m._resolve_queue:pop())
    _step(proc, args, happy)
  end
end

function m.await(p)
  -- we could check if we're actually in a coroutine with
  -- coroutine.running(), and perhaps throw a more useful
  -- error message
  local happy, ret = coroutine.yield(p)
  if not happy then truss.error(ret) end
  return unpack(ret)
end

-- protected await
function m.pawait(p)
  return coroutine.yield(p)
end

-- convenience for async.await(async.run(f, ...))
function m.await_run(f, ...)
  return m.await(m.run(f, ...))
end

function m.event_promise(target, event_name)
  local receiver = {}
  local p = promise.Promise(function(d)
    target:on(event_name, receiver, function(_, ename, evt)
      receiver._dead = true
      d:resolve({ename, evt}) -- TODO: fix promise to deal with multiple values?
    end)
  end)
  p.receiver = receiver -- put this somewhere so callback doesn't get GC'ed
  return p
end

-- convenience method for interacting with the callback-based event system
function m.await_event(target, event_name)
  return m.await(m.event_promise(target, event_name))
end

-- An ECS System that'll call update on the async event pump every frame
local AsyncSystem = class("AsyncSystem")
m.AsyncSystem = AsyncSystem

function AsyncSystem:init(maxtime)
  self.maxtime = maxtime
end

function AsyncSystem:update(ecs)
  m.update(self.maxtime)
end

return m