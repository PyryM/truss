local component = require("ecs/component.t")
local queue = require("util/queue.t")
local class = require("class")
local m = {}

local ScriptContext = class("ScriptContext")
function ScriptContext:init(parent)
  self.par = parent
end

function ScriptContext:wait(nframes)
  if self.par._timeout then
    log.warn("Script tried to wait while already in timeout?")
    return
  end
  self.par._timeout = self.par._t + nframes
  coroutine.yield()
end

local ScriptComponent = component.UpdateComponent:extend("ScriptComponent")
function ScriptComponent:init(f)
  if f then self.run = f end
  self._script_ctx = ScriptContext(self)
  self:restart()
end

-- send an event *to* this script
function Script:event(evttype, evtdata, evtsource)
  self._events:push_right({evttype, evtdata, evtsource})
end

function Script:restart()
  self._t = 0
  self._events = queue.Queue()
  self._timeout = nil
  self._events:push_right({self, self._script_ctx})
  self._co = coroutine.create(self.run)
end

-- dispatch a single event or timeout
function Script:_dispatch_event(t)
  local evtargs
  if self._events:length() > 0 then
    evtargs = self._events:pop_left()
  elseif self._timeout and t > self._timeout
    evtargs = {"timeout"}
  else
    return false
  end
  self._timeout = nil

  local happy, errmsg = coroutine.resume(self._co, unpack(evtargs))
  if not happy then
    self._co = nil
    log.error("Script error: " .. tostring(errmsg))
    return false
  end

  return true
end

function Script:is_running()
  return self._co and coroutine.status(self._co) ~= "dead"
end

function ScriptComponent:update()
  if self:is_running() then
    local more_events = self:_dispatch_event(self._t)
    while more_events do
      more_events = self:_dispatch_event(self._t)
    end
  end
  self._t = self._t + 1
end

function ScriptComponent:run()
  -- bleh
end

return m