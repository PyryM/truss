-- graphics/stage.t
--
-- defines basic render stage

local m = {}
local class = require("class")
local gfx = require("gfx")

local Stage = class("Stage")
m.Stage = Stage

-- initoptions should contain e.g. input render targets (for post-processing),
-- output render targets, uniform values.
function Stage:init(options)
  options = options or {}
  self._num_views = 1
  self._render_ops = {}
  for _, op in ipairs(options.render_ops or {}) do
    self:add_render_op(op)
  end
  self.enabled = true
  self.filter = options.filter
  self.globals = options.globals or nil
  self._exclusive = options.exclusive
  self.stage_name = options.name or options.stage_name or "Stage"
  self.options = options
  self._always_clear = options.always_clear
  self.view = self:_create_view(options.view, options)
  self._user_update = options.on_run
end

function Stage:_create_view(v, default)
  if v and v.bind then -- an actual gfx.View
    return v
  else -- a table
    return gfx.View(v or default)
  end
end

function Stage:__tostring()
  return self.stage_name or "Stage"
end

function Stage:num_views()
  return self._num_views
end

function Stage:bind()
  self.view:bind()
end

function Stage:bind_view_ids(start_view_id, num_views)
  self._start_view_id = start_view_id
  self.view:bind(start_view_id)
end

function Stage:add_render_op(op)
  table.insert(self._render_ops, op)
  op:bind_stage(self)
end

function Stage:pre_render()
  if self._always_clear and self.view then
    self.view:touch()
  end
  if self._user_update then self:_user_update() end
end

function Stage:match(tags, target)
  target = target or {}
  if not self.enabled then return target end
  if self.filter and not (self.filter(tags)) then return target end
  for _, op in ipairs(self._render_ops) do
    local match = op:matches(tags)
    if match then table.insert(target, match) end
    if self._exclusive then break end
  end
  return target
end

return m