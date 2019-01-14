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

function Queue:push_left(value)
  local first = self.first - 1
  self.first = first
  self[first] = value
end

function Queue:push_right(value)
  local last = self.last + 1
  self.last = last
  self[last] = value
end
Queue.push = Queue.push_right

function Queue:pop_left()
  local first = self.first
  if first > self.last then truss.error("Queue is empty") end
  local value = self[first]
  self[first] = nil        -- to allow garbage collection
  self.first = first + 1
  return value
end
Queue.pop = Queue.pop_left

function Queue:pop_right()
  local last = self.last
  if self.first > last then truss.error("Queue is empty") end
  local value = self[last]
  self[last] = nil         -- to allow garbage collection
  self.last = last - 1
  return value
end

function Queue:peek_left()
  return self[self.first]
end
Queue.peek = Queue.peek_left

function Queue:peek_right()
  return self[self.last]
end

function Queue:length()
  return self.last - self.first + 1
end
Queue.size = Queue.length

-- 1-indexed idx to be consistent with rest of lua
function Queue:get(idx)
  return self[self.first + idx - 1]
end

m.Queue = Queue
return m
