-- async/eventqueue.t
--
-- a queue that accumulates events

local class = require("class")
local queue = require("util/queue.t")
local event = require("ecs/event.t")
local async = require("async/async.t")
local promise = require("async/promise.t")
local m = {}

local EventQueue = class("EventQueue")
m.EventQueue = EventQueue

function EventQueue:init()
  self._events = queue.Queue()
end

function EventQueue:_push_event(src, event_name, evt)
  self._events:push({src, event_name, evt})
  if self._promise then
    local p = self._promise
    self._promise = nil
    p:resolve()
  end
end

function EventQueue:listen(target, event_name)
  target:on(event_name, self, function(self, event_name, evt)
    self:_push_event(target, event_name, evt)
  end)
end

function EventQueue:await_event()
  if self._promise then
    truss.error("Multiple coroutines cannot await event on same EventQueue")
  end
  if self._events:length() == 0 then
    self._promise = promise.Promise()
    async.await(self._promise)
  end
  return unpack(self._events:pop())
end

function EventQueue:await_iterator()
  return function()
    return self:await_event()
  end
end

return m