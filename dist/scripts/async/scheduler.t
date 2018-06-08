-- async/scheduler.t
--
-- returns promises that resolve on a schedule

local promise = require("async/promise.t")
local class = require("class")

local m = {}

-- a scheduler that operates on discrete frames
local FrameScheduler = class("FrameScheduler")
m.FrameScheduler = FrameScheduler
function FrameScheduler:init()
  self._frame = 0
  self._tasks = {}
end

function FrameScheduler:schedule(n, f)
  n = n or 1
  if n <= 0 then truss.error("Cannot schedule for <= 0 frames.") end
  local tar_f = self._frame + n
  if not self._tasks[tar_f] then self._tasks[tar_f] = {} end
  local task, p = f, nil
  if not task then
    p = promise.Promise()
    task = function(frame)
      p:resolve(frame)
    end
  end
  table.insert(self._tasks[tar_f], task)
  return p
end

function FrameScheduler:update(frames)
  for i = 1, (frames or 1) do
    self._frame = self._frame + 1
    local tasks = self._tasks[self._frame]
    self._tasks[self._frame] = nil
    if tasks then
      for _, task in ipairs(tasks) do task() end
    end
  end
end

return m