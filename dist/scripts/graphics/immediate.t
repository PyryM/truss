local class = require("class")
local async = require("async")
local gfx = require("gfx")

local m = {}

local ImmediateStage = class("ImmediateStage")
m.ImmediateStage = ImmediateStage

function ImmediateStage:init(options)
  self._num_views = assert(options.num_views)
  self._views = {}
  self.ctx = options.ctx or gfx.ImmediateContext()
  if options.func then
    self:run(options.func)
  end
  self.enabled = options.enabled ~= false
end

function ImmediateStage:bind(start_id, num_views)
  for idx = 1, num_views do
    if not self._views[idx] then
      self._views[idx] = gfx.View()
    end
    self._views[idx]:bind(start_id + (idx - 1))
  end
  for idx = num_views+1, #self._views do
    self._views[idx] = nil
  end
end

function ImmediateStage:run(f, next, err)
  return async.run(function()
    self.ctx:await_frame()
    f(self.ctx)
  end):next(next or print, err or print)
end

function ImmediateStage:pre_render()
  if not self.enabled then return end
  self.ctx:begin_frame(self._views)
end

function ImmediateStage:match(tags, oplist)
  -- doesn't match anything
  return oplist
end

function ImmediateStage:num_views()
  return self._num_views
end

function ImmediateStage:post_render()
  self.ctx:finish_frame()
end

return m