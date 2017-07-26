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
  self.stage_name = options.name or "Stage"
  self.options = options
  self._always_clear = options.always_clear
end

function Stage:__tostring()
  return self.stage_name or "Stage"
end

function Stage:num_views()
  return self._num_views
end

function Stage:bind()
  self.view:set(self.options)
end

function Stage:set_views(views)
  self.view = views[1]
  self:bind()
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