local class = require("class")
local gfx = require("gfx")
local ecs = require("ecs")
local m = {}

local RenderSystem = ecs.System:extend("RenderSystem")
m.RenderSystem = RenderSystem

function RenderSystem:init()
  RenderSystem.super.init(self)
  self.auto_frame_advance = options.auto_frame_advance
  self.mount_name = "render" -- allow direct use of a RenderSystem as a system
end

function RenderSystem:get_render_ops(component, ret)
  return self._pipeline:get_render_ops(component, ret)
end

function RenderSystem:set_pipeline(p)
  self._pipeline = p
  self._pipeline:bind()
  self:call_on_components("configure")
  return self
end

function RenderSystem:update()
  if not self._pipeline then return end

  self._pipeline:pre_render()
  self:call_on_components("render")
  self._pipeline:post_render()

  if self.auto_frame_advance ~= false then
    gfx.frame()
  end
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
  return self.globals.name or self.name or "Stage"
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

local RenderComponent = Component:extend("RenderComponent")
m.RenderComponent = RenderComponent
function RenderComponent:init()
  self._render_ops = {}
end

function RenderComponent:mount()
  RenderComponent.super.mount(self)
  self:add_to_systems({"render"})
  self:wake()
  self:configure()
end

function RenderComponent:configure()
  local render = self.ecs.systems.render
  if not render then
    log.warn("No 'render' system present in ecs!")
    return
  end
  self._render_ops = render:get_render_ops(self)
end

function RenderComponent:render()
  if self.visible == false then return end
  for _, op in ipairs(self._render_ops) do
    op:render(self)
  end
end

local MeshRenderComponent = RenderComponent:extend("MeshRenderComponent")
m.MeshRenderComponent = MeshRenderComponent

function MeshRenderComponent:init(geo, mat)
  self.geo = geo
  self.mat = mat
  self._render_ops = {}
  self.mount_name = "mesh"
end

-- convenience function to create an Entity3d that just renders a mesh
function m.Mesh(ecs, name, geo, mat)
  local entity = require("ecs/entity.t")
  return entity.Entity3d(ecs, name, MeshRenderComponent(geo, mat))
end

return m
