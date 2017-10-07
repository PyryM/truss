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
  self._render_ops = options.render_ops or {}
  self.filter = options.filter
  self.globals = options.globals or {}
  self._exclusive = options.exclusive
  self.stage_name = options.name or options.stage_name or "Stage"
  self.options = options
  self._always_clear = options.always_clear
  self.view = self:_create_view(options.view, options)
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

function Stage:bind_view_ids(view_ids)
  self.view:bind(view_ids[1])
end

function Stage:add_render_op(op)
  table.insert(self._render_ops, op)
end

function Stage:update_begin()
  if self._always_clear and self.view then
    self.view:touch()
  end
end

function Stage:match_render_ops(component, target)
  target = target or {}

  if self.filter and not (self.filter(component)) then return target end

  for _, op in ipairs(self._render_ops) do
    if op:matches(component) then
      table.insert(target, op:to_function(self))
      if self._exclusive then return target end
    end
  end
  return target
end

return m