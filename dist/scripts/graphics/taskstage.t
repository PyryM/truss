-- graphics/taskstage.t
--
-- a stage to execute one-time/infrequent rendering tasks

local class = require("class")
local Queue = require("utils/queue.t").Queue
local functable = require("utils/functable.t")
local renderer = require("graphics/renderer.t")
local gfx = require("gfx")
local bgfx = require("gfx/bgfx.t")
local ring = require("utils/ring.t")
local m = {}

local TaskRunnerStage = class("TaskRunnerStage")
m.TaskRunnerStage = TaskRunnerStage
function TaskRunnerStage:init(options)
  options = options or {}
  self._num_workers = options.num_views or options.num_workers or 1
  self._num_views = self._num_workers + 1 -- reserve one view for blit
  self._queue = Queue()
  self._contexts = {}
  self._extra_blit_view = gfx.View{clear = false}
  self._blits = nil
  self._scratch_buffer = self:_create_scratch(options)

  local function dont_run_this()
    truss.error("The TaskRunnerStage renderop should never actually be called!")
  end
  self._dummy_op = functable(dont_run_this, {task_runner = self})
end

function TaskRunnerStage:num_views()
  return self._num_views
end

function TaskRunnerStage:_create_scratch(options)
  local scratch = options.scratch or 
                  gfx.ColorDepthTarget{width = options.scratch_width or 1024,
                                       height = options.scratch_height or 1024}
  if self._num_workers > 1 then
    return ring.RingBuffer({scratch, scratch:clone()})
  else
    return ring.RingBuffer({scratch})
  end
end

function TaskRunnerStage:bind_view_ids(view_ids)
  if #view_ids < 2 then truss.error("Not enough views: got " .. #view_ids) end
  self._contexts = {}
  for idx = 1, (#view_ids - 1) do
    self._contexts[idx] = {
      viewid = view_ids[idx],
      view = gfx.View():bind(view_ids[idx])
    }
  end
  self._extra_blit_view:bind(view_ids[#view_ids]) -- reserve last id for blit
end

function TaskRunnerStage:bind()
  -- clear out render ops to avoid potential double-execution when
  -- switching pipelines
  self._queue = Queue()
  for _, ctx in ipairs(self._contexts) do ctx.view:bind() end
  self._extra_blit_view:bind()
end

function TaskRunnerStage:update_begin()
  -- hmmm
end

function TaskRunnerStage:update_end()
  self:render()
end

function TaskRunnerStage:match(tags, oplist)
  if not tags.is_task_submitter then return oplist end
  -- abuse the render op system a bit
  table.insert(oplist, self._dummy_op)
  return oplist
end

function TaskRunnerStage:add_task(task)
  self._queue:push(task)
end

function TaskRunnerStage:_dispatch_blits(view)
  if not self._blits then return end
  for _, blit in ipairs(self._blits) do
    bgfx.blit(view._viewid,
          blit.dest._handle, 0, 0, 0, 0,
          blit.src.raw_tex, 0, 0, 0, 0,
          blit.size[1], blit.size[2], 0)
  end
  self._blits = nil
end

function TaskRunnerStage:_scratch_render(context, task)
  -- we are going to overwrite scratch, so blits need to be dispatched
  -- first to copy out anything important
  self:_dispatch_blits(context.view)

  local scratch = self._scratch_buffer:next()
  local tex = task.tex
  if not tex:is_blittable() then 
    truss.error("task.target_tex must be blit dest!")
  end
  local tw, th = tex.width, tex.height
  local sw = scratch.width 
  local sh = scratch.height
  if tw > sw or th > sh then
    truss.error("Task requested render operation larger than scratch: " ..
                "req=(" .. tw .. " x" .. th .. ") " ..
                "scratch=(" .. sw .. " x " .. sh .. ")")
  end
  context.view:set_render_target(scratch)
  -- set a viewport to the exact size of the target texture
  context.view:set_viewport({0, 0, tw, th})
  task:execute(self, context)
  if not self._blits then self._blits = {} end
  table.insert(self._blits, {src = scratch, dest = tex, size = {tw, th}})
end

function TaskRunnerStage:render()
  self._scratch_buffer:reset()
  for _, context in ipairs(self._contexts) do
    if self._queue:length() <= 0 then break end
    local task = self._queue:pop()
    if task.tex then -- task needs to render to scratch
      self:_scratch_render(context, task)
    else             -- task will manage its own render target
      task:execute(self, context)
    end
  end
  if self._blits then
    self:_dispatch_blits(self._extra_blit_view)
    self._extra_blit_view:touch()
  end
end

local Task = class("Task")
function Task:init(submitter, options)
  if not (options.tex or options.render_target) then
    truss.error("Task options must have either a .tex or .render_target")
  end
  self.submitter = submitter
  self.func = options.func
  self.tex = options.tex
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

function TaskSubmitter:submit(options)
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
  local task = Task(self, options)
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
