-- gfx/taskstage.t
--
-- a stage to execute one-time/infrequent rendering tasks

local class = require("class")
local Queue = require("utils/queue.t").Queue
local functable = require("utils/functable.t")
local m = {}

local TaskRunnerStage = class("TaskRunnerStage")
function TaskRunnerStage:init(options)
  options = options or {}
  self._num_views = options.num_views or options.num_workers or 1
  self._queue = Queue()
  self._completed = {}
  self._view_ids = {}
end

function TaskRunnerStage:num_views()
  return self._num_views
end

function TaskRunnerStage:bind_view_ids(view_ids)
  self._view_ids = view_ids
end

function TaskRunnerStage:bind()
  -- clear out render ops to avoid potential double-execution when
  -- switching pipelines
  self._queue = Queue()
end

function TaskRunnerStage:update_begin()
  -- hmmm
end

function TaskRunnerStage:update_end()
  self:render()
end

local function dont_run_this()
  truss.error("The TaskRunnerStage renderop should never actually be called!")
end

function TaskRunnerStage:match_render_ops(component, oplist)
  if not component.is_task_submitter then return oplist end

  -- abuse the render op system a bit
  local rop = functable(dont_run_this, {task_runner = self})
  table.insert(oplist, rop)
  return oplist
end

function TaskRunnerStage:add_task(task)
  self._queue:push(task)
end

function TaskRunnerStage:render()
  -- indicate to tasks run last frame that they have executed
  for _, task in ipairs(self._completed) do
    task:after_execute() end
  end
  self._completed = {}

  for _, viewid in ipairs(self._view_ids) do
    if self._queue:length() <= 0 then return end
    local task = self._queue:pop()
    if task.execute then task:execute(self, viewid) end
    if task.after_execute then table.insert(self._completed, task) end
  end
end

m.TaskRunnerStage = TaskRunnerStage
return m
