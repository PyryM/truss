-- util/ring.t
--
-- a buffer that rotates among options

local class = require("class")
local m = {}

local RingBuffer = class("RingBuffer")
m.RingBuffer = RingBuffer

function RingBuffer:init(options)
  self._options = options or {}
  self._pos = 0
end

function RingBuffer:add(option)
  table.insert(self._options, option)
  self._pos = 0
end

function RingBuffer:reset()
  self._pos = 0
end

function RingBuffer:next()
  local ret = self._options[self._pos + 1]
  self._pos = (self._pos + 1) % #(self._options)
  return ret
end

return m