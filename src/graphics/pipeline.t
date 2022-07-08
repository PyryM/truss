-- graphics/pipeline.t
--
-- defines a pipeline

local m = {}
local class = require("class")
local gfx = require("gfx")

local CallbackStage = class("CallbackStage")
m.CallbackStage = CallbackStage

function CallbackStage:init(f)
  self.enabled = true
  self.f = f
end

function CallbackStage:match()
  -- NOOP
end

function CallbackStage:pre_render()
  if self.enabled then self.f() end
end

function CallbackStage:num_views()
  return 0
end

function CallbackStage:bind()
  -- NOOP
end

local Pipeline = class("Pipeline")
m.Pipeline = Pipeline

function Pipeline:init(options)
  options = options or {}
  self.stages = {}
  self._ordered_stages = {}
  self.verbose = options.verbose
  self.globals = options.globals or gfx.CompiledGlobals()
  self.dirty = false -- zero stages are vacuously bound
end

local function _match_tags(stages, tags, target)
  target = target or {}
  for _, stage in ipairs(stages) do
    stage:match(tags, target)
  end
  return target
end

function Pipeline:match(tags, target)
  return _match_tags(self._ordered_stages, tags, target)
end

function Pipeline:match_scene(scene, target)
  target = target or {match = _match_tags}
  scene = scene or "default"
  for _, stage in ipairs(self._ordered_stages) do
    if stage.scene == scene then
      table.insert(target, stage)
    end
  end
  return target
end

function Pipeline:pre_render()
  for _, stage in ipairs(self._ordered_stages) do
    if stage.pre_render then stage:pre_render() end
  end
end

function Pipeline:post_render()
  for _, stage in ipairs(self._ordered_stages) do
    if stage.post_render then stage:post_render() end
  end
end

function Pipeline:bind(start_view_id, num_views)
  local viewid = start_view_id or 0
  local views_left = num_views or 0xffff
  if (not self.dirty) and (viewid == self.start_view) and (views_left >= self.num_views) then
    return
  end
  self.start_view = viewid
  self.num_views = views_left
  log.info(("Pipeline change: reassigning views %d -> %d"):format(viewid, viewid+views_left))

  for _, stage in ipairs(self._ordered_stages) do
    local nviews = stage:num_views() or 1
    if nviews > views_left then
      truss.error("Not enough views: " .. views_left .. " vs. " .. nviews)
    end
    if self.verbose then
      log.debug("Giving stage [" .. tostring(stage) .. "] views " ..
                viewid .. " to " .. (viewid + nviews - 1))
    end
    stage:bind(viewid, nviews)
    viewid = viewid + nviews
    views_left = views_left - nviews
  end
  self.dirty = false
end

function Pipeline:insert_stage(position, stage, stage_name)
  self.dirty = true
  table.insert(self._ordered_stages, position or (#self._ordered_stages + 1), stage)
  stage_name = stage_name or stage.stage_name
  if stage_name then 
    self.stages[stage_name] = stage 
    stage._bound_name = stage_name
  end
  if stage.scene == nil then stage.scene = "default" end
  return stage
end

function Pipeline:add_stage(stage, stage_name)
  return self:insert_stage(nil, stage, stage_name)
end

function Pipeline:add_callback(f)
  return self:insert_stage(nil, CallbackStage(f))
end

function Pipeline:find_stage_index(stage_name)
  if not stage_name then truss.error("stage_name was not provided or is false") end
  for idx, stage in ipairs(self._ordered_stages) do
    if stage._bound_name == stage_name then return idx end
  end
  return nil
end

function Pipeline:insert_after(insert_point, stage, stage_name)
  local idx = truss.assert(self:find_stage_index(insert_point))
  return self:insert_stage(idx+1, stage, stage_name)
end

function Pipeline:insert_before(insert_point, stage, stage_name)
  local idx = truss.assert(self:find_stage_index(insert_point))
  return self:insert_stage(idx, stage, stage_name)
end

local SubPipeline = class("SubPipeline")
m.SubPipeline = SubPipeline
function SubPipeline:init(options)
  options = options or {}
  self._num_views = options.num_views or 10
  self.filter = options.filter
  self.stage_name = options.name or options.stage_name or "SubPipeline"
  self.enabled = (options.enabled ~= false)
  self.options = options
  self.globals = options.globals
  self.scene = options.scene

  if options.pipeline then self._pipeline = options.pipeline end
end

function SubPipeline:num_views()
  return self._num_views
end

function SubPipeline:bind(start_view, num_views)
  self._start_view = start_view
  if num_views ~= self._num_views then
    truss.error("View # mismatch: " .. num_views .. " vs. " .. self._num_views)
  end
  if self._pipeline then self._pipeline:bind(start_view, num_views) end
end

function SubPipeline:set_pipeline(p)
  self._pipeline = p
  if self._start_view and self._pipeline then
    self._pipeline:bind(self._start_view, self._num_views)
  end
end

function SubPipeline:__tostring()
  return self.stage_name or "SubPipeline"
  -- TODO: print out substages?
end

function SubPipeline:match(tags, target)
  target = target or {}
  if (not self.enabled) or (not self._pipeline) then return target end
  if self.filter and not self.filter(tags) then return target end
  return self._pipeline:match(tags, target)
end

function SubPipeline:pre_render()
  if self.enabled and self._pipeline then 
    self._pipeline:pre_render() 
  end
end

function SubPipeline:post_render()
  if self.enabled and self._pipeline then
    self._pipeline:post_render()
  end
end

return m
