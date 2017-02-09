local class = require("class")
local gfx = require("gfx")
local m = {}

local Pipeline = class("Pipeline")
m.Pipeline = Pipeline

function Pipeline:init(options)
  options = options or {}
  self._ordered_stages = {}
  self._next_view = 0
  self.stages = {}
  self.verbose = options.verbose
  self.auto_frame_advance = options.auto_frame_advance
  self.mount_name = "graphics" -- allow direct use of a pipeline as a system
  self.update_priority = 100 -- try to always update last
end

function Pipeline:add_stage(stage, stage_name)
  table.insert(self._ordered_stages, stage)
  if stage_name then self.stages[stage_name] = stage end
  local nviews = stage.num_views or 1
  local views = {}
  if self.verbose then
    log.debug("Giving stage [" .. tostring(stage) .. "] views " ..
              self._next_view .. " to " .. (self._next_view + nviews - 1))
  end
  for i = 1,nviews do
    local v = gfx.View(self._next_view)
    views[i] = v
    self._next_view = self._next_view + 1
  end
  stage:set_views(views)
  return stage
end

function Pipeline:bind()
  for _,stage in ipairs(self._ordered_stages) do
    stage:bind()
  end
end

function Pipeline:get_render_ops(component, target_list)
  target_list = target_list or {}
  for _,stage in ipairs(self._ordered_stages) do
    stage:get_render_ops(component, target_list)
  end
  return target_list
end

function Pipeline:update_begin()
  for _,stage in ipairs(self._ordered_stages) do
    if stage.update then stage:update() end
  end
end

function Pipeline:update_end()
  if self.auto_frame_advance ~= false then
    gfx.frame()
  end
end

function Pipeline:update()
  self:update_begin()
end

local Stage = class("Stage")
m.Stage = Stage

-- initoptions should contain e.g. input render targets (for post-processing),
-- output render targets, uniform values.
function Stage:init(globals, render_ops)
  self.num_views = 1
  self._render_ops = render_ops or {}
  self.filter = globals.filter
  self.globals = globals or {}
end

function Stage:__tostring()
  return self.globals.name or "Stage"
end

-- copies a table value by value, using val:duplicate() when present
local function duplicate_copy(t, strict)
  local ret = {}
  for k,v in pairs(t) do
    if type(v) == "table" and v.duplicate then
      ret[k] = v:duplicate()
    else
      if strict then truss.error("Value did not support duplicate!") end
      ret[k] = v
    end
  end
  return ret

end

function Stage:duplicate()
  local ret = Stage(duplicate_copy(self.globals),
                    duplicate_copy(self._render_ops, true))
  ret.filter = self.filter
  ret.num_views = self.num_views
  return ret
end

function Stage:bind()
  self.view:set(self.globals)
  for _,op in ipairs(self._render_ops) do
    op:set_stage(self)
  end
end

function Stage:set_views(views)
  self.view = views[1]
  self:bind()
end

function Stage:add_render_op(op)
  table.insert(self._render_ops, op)
  op:set_stage(self)
end

function Stage:get_render_ops(component, target)
  target = target or {}

  if self.filter and not (self.filter(component)) then return target end

  for _, op in ipairs(self._render_ops) do
    if op:matches(component) then
      table.insert(target, op)
      if self._exclusive then return target end
    end
  end
  return target
end

local RenderOperation = class("RenderOperation")
m.RenderOperation = RenderOperation

function RenderOperation:init()
  -- nothing in particular to do
end

function RenderOperation:set_stage(stage)
  self.stage = stage
end

function RenderOperation:duplicate()
  return self.class()
end

function RenderOperation:matches(component)
  log.warn("Base RenderOperation shouldn't actually be added to a stage!")
  log.warn("Did you forget to implement op:matches()?")
  return false
end

local GenericRenderOp = RenderOperation:extend("GenericRenderOp")
m.GenericRenderOp = GenericRenderOp

function GenericRenderOp:init()
  -- nothing to do
end

function GenericRenderOp:matches(component)
  return (component.geo ~= nil and component.mat ~= nil)
end

function GenericRenderOp:draw(component)
  if not component.geo or not component.mat then return end
  if not component.mat.program then return end
  gfx.set_transform(component._entity.matrix_world)
  component.geo:bind()
  if component.mat.state then gfx.set_state(component.mat.state) end
  if component.mat.uniforms then component.mat.uniforms:bind() end
  if component.mat.globals then
    local g = self.stage.globals
    for _,v in ipairs(component.mat.globals) do
      if g[v] then g[v]:bind() end
    end
  end
  gfx.submit(self.stage.view, component.mat.program)
end

local Component = require("ecs/component.t").Component

local DrawableComponent = Component:extend("DrawableComponent")
m.DrawableComponent = DrawableComponent
function DrawableComponent:init()
  self._render_ops = {}
end

function DrawableComponent:configure(ecs_root)
  if not ecs_root.systems.graphics then
    log.warn("No 'graphics' system present in ecs!")
    return
  end
  self._render_ops = ecs_root.systems.graphics:get_render_ops(self)
end

function DrawableComponent:draw()
  for _, op in ipairs(self._render_ops) do
    op:draw(self)
  end
end

local MeshShaderComponent = DrawableComponent:extend("MeshShaderComponent")
m.MeshShaderComponent = MeshShaderComponent

function MeshShaderComponent:init(geo, mat)
  self.geo = geo
  self.mat = mat
  self._render_ops = {}
end

MeshShaderComponent.on_update = DrawableComponent.draw

return m
