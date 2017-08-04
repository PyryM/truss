-- graphics/taskstage.t
--
-- a stage to execute one-time/infrequent rendering tasks

local class = require("class")
local Queue = require("utils/queue.t").Queue
local functable = require("utils/functable.t")
local renderer = require("graphics/renderer.t")
local gfx = require("gfx")
local m = {}

local TaskRunnerStage = class("TaskRunnerStage")
m.TaskRunnerStage = TaskRunnerStage
function TaskRunnerStage:init(options)
  options = options or {}
  self._num_views = options.num_views or options.num_workers or 1
  self._queue = Queue()
  self._view_ids = {}
  self._contexts = {}

  local function dont_run_this()
    truss.error("The TaskRunnerStage renderop should never actually be called!")
  end
  self._dummy_op = functable(dont_run_this, {task_runner = self})
end

function TaskRunnerStage:num_views()
  return self._num_views
end

function TaskRunnerStage:bind_view_ids(view_ids)
  self._contexts = {}
  for idx, viewid in ipairs(view_ids) do
    self._contexts[idx] = {
      viewid = viewid,
      view = gfx.View():bind(viewid)
    }
  end
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

function TaskRunnerStage:match_render_ops(component, oplist)
  if not component.is_task_submitter then return oplist end
  -- abuse the render op system a bit
  table.insert(oplist, self._dummy_op)
  return oplist
end

function TaskRunnerStage:add_task(task)
  self._queue:push(task)
end

function TaskRunnerStage:render()
  for _, context in ipairs(self._contexts) do
    if self._queue:length() <= 0 then return end
    self._queue:pop():execute(self, context)
  end
end

local Task = class("Task")
function Task:init(submitter, func)
  self.submitter = submitter
  self.func = func
  self.completed = false
end

function Task:execute(stage, context)
  self.func(self, stage, context)
  self.submitter:finish_task(self)
  self.completed = true
end

local TaskSubmitter = renderer.RenderComponent:extend("TaskSubmitter")
m.TaskSubmitter = TaskSubmitter

function TaskSubmitter:init(options)
  self._render_ops = {}
  self.is_task_submitter = true
  self.mount_name = "tasks"
end

function TaskSubmitter:submit(task_function)
  local nops = #(self._render_ops)
  local task_runner = nil
  if nops == 0 then
    truss.error("Cannot submit task: no task runner in pipeline")
    return
  elseif nops == 1 then
    task_runner = self._render_ops[1].task_runner
  else -- randomly choose one for now
    task_runner = self._render_ops[math.random(nops)].task_runner
  end
  local task = Task(self, task_function)
  task_runner:add_task(task)
  return task
end

function TaskSubmitter:finish_task(task)
  -- TODO: probably should be some bookkeeping here
  -- local common = require("gfx/common.t")
  -- log.debug("Finished task " .. tostring(task) .. " on frame " .. common.frame_index)
end

function TaskSubmitter:render()
  -- override RenderComponent:render to avoid it actually calling
  -- our render ops (which are just placeholders)
end

return m
