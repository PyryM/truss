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
  self._pending = {}
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
  if self._pending[evtname] then 
    truss.error("Cannot recursively emit [" .. tostring(evtname) .. "]")
  end
  self._pending[evtname] = {}
  for receiver, callback in pairs(ll) do
    if receiver._dead then
      ll[receiver] = nil
    else
      callback(receiver, evtname, evt)
    end
  end
  -- have to do this to avoid infinite loops/undefined iteration behavior
  -- when listeners are added for an event from a callback for that event
  local additions = self._pending[evtname]
  self._pending[evtname] = nil
  if #additions > 0 then
    for _, addition in ipairs(additions) do
      self:on(unpack(addition))
    end
  end
end

function EventEmitter:on(evtname, receiver, callback)
  if not receiver then truss.error("nil receiver!") end
  if callback == nil then 
    truss.error("nil callback! (use false to remove)")
  elseif callback == false then
    return self:remove(evtname, receiver)
  end
  if self._pending[evtname] then
    table.insert(self._pending[evtname], {evtname, receiver, callback})
    return
  end
  if not self._listeners[evtname] then
    self._listeners[evtname] = create_weak_table()
  end
  self._listeners[evtname][receiver] = callback
end

function EventEmitter:remove(evtname, receiver)
  if not self._listeners[evtname] then return end
  self._listeners[evtname][receiver] = nil
end

function EventEmitter:remove_all(receiver)
  for _, ll in pairs(self._listeners) do
    ll[receiver] = nil
  end
end

return m
