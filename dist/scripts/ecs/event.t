-- ecs/event.t
--
-- an event emitter style thing

local class = require("class")
local m = {}

local EventEmitter = class("EventEmitter")
m.EventEmitter = EventEmitter

function EventEmitter:init()
  -- TODO
  self._listeners = {}
end

local function create_weak_table()
  return setmetatable({}, {__mode="k"})
end

-- Note that we weak key by the 'receiver' so that if it
-- is garbage collected its event callbacks won't keep it alive
--
-- Note that you can safely do e.g.
--  event:on("blah", my_comp, my_comp.funcname)

function EventEmitter:emit(evtname, evt)
  local ll = self._listeners[evtname]
  if not ll then return end
  for receiver, callback in pairs(ll) do
    if receiver._dead then
      ll[receiver] = nil
    else
      callback(receiver, evtname, evt)
    end
  end
end

function EventEmitter:on(evtname, receiver, callback)
  if not self._listeners[evtname] then
    self._listeners[evtname] = create_weak_table()
  end
  self._listeners[evtname][receiver] = callback
end

return m
