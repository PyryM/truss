-- utils/queue.t
--
-- a basic queue
-- (adapted from https://www.lua.org/pil/11.4.html)

local class = require("class")
local m = {}

local Queue = class("Queue")
function Queue:init()
    self.first = 0
    self.last = -1
    self.data = {}
end

function Queue:pushLeft(value)
    local first = self.first - 1
    self.first = first
    self[first] = value
end

function Queue:pushRight(value)
    local last = self.last + 1
    self.last = last
    self[last] = value
end
Queue.push = Queue.pushRight

function Queue:popLeft()
    local first = self.first
    if first > self.last then error("Queue is empty") end
    local value = self[first]
    self[first] = nil        -- to allow garbage collection
    self.first = first + 1
    return value
end
Queue.pop = Queue.popLeft

function Queue:popRight()
    local last = self.last
    if self.first > last then error("Queue is empty") end
    local value = self[last]
    self[last] = nil         -- to allow garbage collection
    self.last = last - 1
    return value
end

function Queue:peekLeft()
    return self[self.first]
end
Queue.peek = Queue.peekLeft

function Queue:peekRight()
    return self[self.last]
end

function Queue:length()
    return self.last - self.first + 1
end

-- 1-indexed idx to be consistent with rest of lua
function Queue:get(idx)
    return self[self.first + idx - 1]
end

m.Queue = Queue
return m
