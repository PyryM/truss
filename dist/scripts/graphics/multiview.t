-- graphics/multiview.t
--
-- a stage which can render to multiple views

local m = {}
local class = require("class")
local gfx = require("gfx")
local stage = require("./stage.t")

local MultiviewStage = stage.Stage:extend("MultiviewStage")
m.MultiviewStage = MultiviewStage

function MultiviewStage:init(options)
  options = options or {}
  MultiviewStage.super.init(self, options)
  self._num_views = #(options.views)
  self.stage_name = options.name or "MultiviewStage"
  self.options = options
  self._always_clear = options.always_clear
  self.views = {}
  self.named_views = {}
  for idx, view in ipairs(options.views) do
    if not view.bind then view = gfx.View(view) end
    self.views[idx] = view
    self.named_views[view.name] = view
  end
  self.view = nil -- so we'll throw errors if an op tries to use .view
end

function MultiviewStage:bind()
  for _, view in ipairs(self.views) do view:bind() end
end

function MultiviewStage:bind_view_ids(start_id, num_views)
  if num_views ~= self._num_views then 
    truss.error("Wrong number of views!") 
  end
  self._start_view_id = start_id
  for idx = 1, num_views do
    self.views[idx]:bind(start_id + idx - 1)
  end
end

function MultiviewStage:update_begin()
  if self._always_clear then
    for _, view in ipairs(self.views) do view:touch() end
  end
end

return m