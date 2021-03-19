-- async/async.t
--
-- async event loop

local class = require("class")
local promise = require("./promise.t")
local queue = require("util/queue.t")
local scheduler = require("./scheduler.t")
local m = {}

local Async = class("Async")
m.Async = Async

local _instance

function Async:init()
  self:clear()
end

function Async:clear()
  self._procs = {}
  self._yield_queue = queue.Queue()
  self._resolve_queue = queue.Queue()
  self._schedule = scheduler.FrameScheduler()
end

function m.clear()
  _instance:clear()
end

function Async:_step(proc, args, succeeded)
  local happy, ret, immediate
  if succeeded == nil then
    happy, ret, immediate = coroutine.resume(proc.co, unpack(args))
  else
    happy, ret, immediate = coroutine.resume(proc.co, succeeded, args)
  end
  if not happy then
    self._procs[proc] = nil -- kill proc?
    proc.promise:reject(ret)
    return
  end
  if coroutine.status(proc.co) == "dead" then
    self._procs[proc] = nil
    proc.promise:resolve(ret)
  elseif ret then
    if immediate then
      ret:next(function(...)
        self:_resolve_immediate(proc, ...)
      end,
      function(err)
        self:_reject_immediate(proc, err)
      end)
    else
      ret:next(function(...)
        self:_resolve(proc, ...)
      end,
      function(err)
        self:_reject(proc, err)
      end)
    end
  else
    -- yielding nothing indicates delay for a frame
    self._yield_queue:push(proc)
  end
end

function Async:schedule(n, f)
  return self._schedule:schedule(n, f)
end

function m.schedule(n, f)
  return _instance:schedule(n, f)
end

function Async:run(f, ...)
  local proc = {
    co = coroutine.create(f),
    promise = promise.Promise()
  }
  self._procs[proc] = proc
  self:_step(proc, {...})
  return proc.promise
end

function m.run(f, ...)
  return _instance:run(f, ...)
end

function Async:_resolve(proc, ...)
  self._resolve_queue:push({proc, true, {...}})
end

function Async:_reject(proc, err)
  self._resolve_queue:push({proc, false, err})
end

function Async:_resolve_immediate(proc, ...)
  self:_step(proc, {...}, true)
end

function Async:_reject_immediate(proj, ...)
  self:_step(proc, {...}, false)
end

function Async:update(maxtime)
  -- TODO: deal with maxtime

  self._schedule:update(1)

  -- only process the current number of items in the queue
  -- because processes might yield again when resumed
  local nyield = self._yield_queue:length()
  for i = 1, nyield do
    local proc = self._yield_queue:pop()
    self:_step(proc, {}, true)
  end

  -- handle resolves
  while self._resolve_queue:length() > 0 do
    local proc, happy, args = unpack(self._resolve_queue:pop())
    self:_step(proc, args, happy)
  end
end

function m.update(maxtime)
  return _instance:update(maxtime)
end

function m.await(p, immediate)
  -- we could check if we're actually in a coroutine with
  -- coroutine.running(), and perhaps throw a more useful
  -- error message
  local happy, ret = coroutine.yield(p, immediate)
  if not happy then truss.error(ret) end
  return unpack(ret)
end

function m.await_immediate(p)
  return m.await(p, true)
end

-- protected await
function m.pawait(p, immediate)
  return coroutine.yield(p, immediate)
end

function m.yield()
  coroutine.yield()
end

function m.await_frames(n)
  if n == nil or n <= 1 then
    coroutine.yield()
    return 1
  else
    return m.await(m.schedule(n))
  end
end

function m.await_condition(cond, timeout)
  local f = 0
  while not cond() do
    f = f + 1
    if timeout and f >= timeout then 
      return false 
    end
    m.yield()
  end
  return true
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

-- wrap a function so it is async.run'd when called  
function m.async_function(f)
  return function(...)
    return m.run(f, ...)
  end
end
m.afunc = m.async_function -- shorter alias

-- An ECS System that'll call update on the async event pump every frame
local AsyncSystem = class("AsyncSystem")
m.AsyncSystem = AsyncSystem

function AsyncSystem:init(maxtime)
  self.maxtime = maxtime
  self.mount_name = "async"
end

function AsyncSystem:update(ecs)
  m.update(self.maxtime)
end

-- create the default instance
_instance = Async()

return m