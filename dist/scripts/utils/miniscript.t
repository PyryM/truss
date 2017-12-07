-- utils/miniscript.t
--
-- some co-routine trickery

local class = require("class")
local queue = require("util/queue.t")
local m = {}

local ScriptContext

local Miniscript = class("Miniscript")
m.Miniscript = Miniscript
function Miniscript:init(f, ...)
  self._f = f
  self._events = queue.Queue()
  self._in_update = false
  self._co = coroutine.create(f)
  self:_dispatch_event{ScriptContext(self), ...}
end

function Miniscript:is_running()
  return self._co and coroutine.status(self._co) ~= "dead"
end

function Miniscript:event(evttype, ...)
  -- we can't resume the coroutine if we're already in the coroutine,
  -- so instead queue up the event
  if self._in_update then
    self._events:push_right{evttype, ...}
  else
    self:_dispatch_event{evttype, ...}
  end
end

function Miniscript:_dispatch_event(evtargs)
  self._in_update = true
  local happy, errmsg = coroutine.resume(self._co, unpack(evtargs))
  self._in_update = false
  if not happy then
    self._co = nil
    log.error("Script error: " .. tostring(errmsg))
  end
  return happy
end

function Miniscript:update(t)
  if self:is_running() then

    self:_dispatch_event{"tick", t or self._frame}

    while self._events:length() > 0 do
      if not self:_dispatch_event(self._events:pop_left()) then 
        return false 
      end
    end

    self._frame = self._frame + 1
    return true
  else
    return false
  end
end

ScriptContext = class("ScriptContext")
function ScriptContext:init(parent)
  self._parent = parent
end

-- wait a n_frames, *ignoring* any events that happen
function ScriptContext:wait(n_frames)
  n_frames = n_frames or 1
  while n_frames > 0 do
    local evtname = coroutine.yield()
    if evtname == "tick" then n_frames = n_frames - 1 end
  end
  return "timeout"
end

-- wait for an event, up to n_frames, returning "timeout"
-- if no non-tick event was received
function ScriptContext:wait_event(n_frames)
  n_frames = n_frames or 1
  while n_frames > 0 do
    local evt = {coroutine.yield()}
    if evt[1] ~= "tick" then return unpack(evt) end 
    n_frames = n_frames - 1 end
  end
  return "timeout"
end

-- return a function that will dispatch an event
function ScriptContext:make_callback(evtname)
  return function(...)
    self._parent:event(evtname, ...)
  end
end

return m