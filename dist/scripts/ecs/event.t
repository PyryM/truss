-- ecs/event.t
--
-- 'eventemitter' style events

local m = {}

-- mixins -----------------------------------------------------------
---------------------------------------------------------------------

local EventMixin = {}
m.EventMixin = EventMixin

function EventMixin:event_init()
	self._event_handlers = {}
end

function EventMixin:add_handler(evtname, handler)
end

function EventMixin:remove_handler(evtname, handler)
end

return m
