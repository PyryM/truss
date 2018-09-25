-- graphics/taskstage.t
--
-- a stage to execute one-time/infrequent rendering tasks

local class = require("class")
local renderer = require("./renderer.t")
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
  self._contexts = {}
  self._extra_blit_view = gfx.View{clear = false}
  self._blits = nil
  self._scratch_buffer = self:_create_scratch(options)
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

function TaskRunnerStage:bind(start_id, num_views)
  if num_views < 2 then truss.error("Not enough views: got " .. num_views) end
  self._contexts = {}
  for idx = 0, (num_views - 2) do
    self._contexts[idx+1] = {
      viewid = start_id + idx,
      view = gfx.View():bind(start_id + idx)
    }
  end
  -- reserve last id for blit
  self._extra_blit_view:bind(start_id + num_views - 1) 
end

function TaskRunnerStage:pre_render()
  self._used_contexts = 0
  self._scratch_buffer:reset()
end

function TaskRunnerStage:capacity()
  return #self._contexts - self._used_contexts
end

function TaskRunnerStage:dispatch_task(task)
  self._used_contexts = self._used_contexts + 1
  local context = self._contexts[self._used_contexts]
  if task.tex then -- task needs to render to scratch
    self:_scratch_render(context, task)
  else             -- task will manage its own render target
    task:execute(self, context)
  end
end

function TaskRunnerStage:post_render()
  if self._blits then
    self:_dispatch_blits(self._extra_blit_view)
    self._extra_blit_view:touch()
  end
end

function TaskRunnerStage:match(tags, oplist)
  -- doesn't match anything
  return oplist
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
  task:execute(context)
  if not self._blits then self._blits = {} end
  table.insert(self._blits, {src = scratch, dest = tex, size = {tw, th}})
end

local Task = class("Task")
m.Task = Task

function Task:init(options)
  if not (options.tex or options.render_target) then
    truss.error("Task options must have either a .tex or .render_target")
  end
  self.func = options.func
  self.tex = options.tex
  self.completed = false
end

function Task:execute(context)
  self.func(context)
  self.completed = true
end

local AsyncTask = Task:extend("AsyncTask")
m.AsyncTask = AsyncTask

function AsyncTask:init(options)
  AsyncTask.super.init(self, options)
  self.promise = require("async").Promise()
end

function AsyncTask:execute(context)
  AsyncTask.super.execute(self, context)
  self.promise:resolve()
end

-- allows directly async.await'ing on the task
function AsyncTask:next(...)
  self.promise:next(...)
end

return m
