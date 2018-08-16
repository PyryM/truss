-- graphics/multiview.t
--
-- a stage which can render to multiple views
--
-- the subviews can have different view settings and globals,
-- but share renderops

local m = {}
local class = require("class")
local gfx = require("gfx")

local MultiviewStage = class("MultiviewStage")
m.MultiviewStage = MultiviewStage

-- initoptions should contain e.g. input render targets (for post-processing),
-- output render targets, uniform values.
function MultiviewStage:init(options)
  options = options or {}
  self._num_views = #(options.views)
  self._contexts = {}
  self.contexts = {}
  self.enabled = true
  self._render_ops = {}
  for _, op in ipairs(options.render_ops or {}) do
    self:add_render_op(op)
  end
  self.filter = options.filter
  self.globals = options.globals or {}
  self._exclusive = options.exclusive
  self.stage_name = options.name or "MultiviewStage"
  self.options = options
  self._always_clear = options.always_clear
  for idx, ctx in ipairs(options.views) do
    local view = ctx.view or ctx
    if not view.bind then view = gfx.View(view) end
    ctx.view = view
    -- Todo: view-specific globals?
    --[[
    if not ctx.globals then ctx.globals = self.globals end
    self._contexts[idx] = ctx
    self.contexts[ctx.name or ("context_" .. idx)] = ctx
    ]]
  end
end

function MultiviewStage:__tostring()
  return self.stage_name or "MultiviewStage"
end

function MultiviewStage:num_views()
  return self._num_views
end

function MultiviewStage:bind()
  for _, ctx in ipairs(self._contexts) do
    ctx.view:bind()
  end
end

function MultiviewStage:bind_view_ids(view_ids)
  if #view_ids ~= self._num_views then 
    truss.error("Wrong number of views!") 
  end
  self._start_view_id = view_ids[1]
  for idx, view_id in ipairs(view_ids) do
    self._contexts[idx].view:bind(view_id)
  end
end

function MultiviewStage:add_render_op(op)
  table.insert(self._render_ops, op)
  op:bind_to_stage(self)
end

function MultiviewStage:update_begin()
  if self._always_clear then
    for _, ctx in ipairs(self._contexts) do
      if ctx.view then ctx.view:touch() end
    end
  end
end

function MultiviewStage:match(tags, target)
  target = target or {}
  if not self.enabled then return target end
  if self.filter and not (self.filter(tags)) then return target end

  for _, op in ipairs(self._render_ops) do
    local f, multi_f = op:matches(component)
    if multi_f then -- supports multiview
      table.insert(target, multi_f)
    elseif f then -- shove in the same op n times
      for _, ctx in ipairs(self._contexts) do
        table.insert(target, op:bind_to(ctx))
      end
    end
    if (f or multi_f) and self._exclusive then break end
  end
  return target
end

return m