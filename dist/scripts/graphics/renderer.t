local class = require("class")
local gfx = require("gfx")
local ecs = require("ecs")
local math = require("math")
local m = {}

local RenderSystem = ecs.System:extend("RenderSystem")
m.RenderSystem = RenderSystem

function RenderSystem:init(options)
  RenderSystem.super.init(self)
  options = options or {}
  self.auto_frame_advance = options.auto_frame_advance
  self.mount_name = "render" -- allow direct use of a RenderSystem as a system
end

function RenderSystem:match_render_ops(component, ret)
  return self._pipeline:match_render_ops(component, ret)
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

  self.ecs:insert_timing_event("render_submit")

  if self.auto_frame_advance ~= false then
    gfx.frame()
  end
end

local RenderOperation = class("RenderOperation")
m.RenderOperation = RenderOperation

function RenderOperation:init()
  -- nothing in particular to do
end

function RenderOperation:duplicate()
  return self.class()
end

function RenderOperation:matches(component)
  log.warn("Base RenderOperation shouldn't actually be added to a stage!")
  log.warn("Did you forget to implement op:matches()?")
  return false
end

function RenderOperation:render(context, component)
  truss.error("Base RenderOperation should never actually :render!")
end

function RenderOperation:to_function(context)
  return function(component)
    self:render(context, component)
  end
end

function RenderOperation:to_multiview_function(contexts)
  if self.multi_render then
    return function(component)
      self:multi_render(contexts, component)
    end
  else
    return nil
  end
end

local GenericRenderOp = RenderOperation:extend("GenericRenderOp")
m.GenericRenderOp = GenericRenderOp

function GenericRenderOp:init()
  -- nothing to do
end

function GenericRenderOp:matches(component)
  return (component.geo ~= nil and component.mat ~= nil)
end

function GenericRenderOp:render(context, component)
  local geo, mat = component.geo, component.mat
  if (not geo) or (not mat) then return end
  if not mat.program then return end
  gfx.set_transform(component.ent.matrix_world)
  geo:bind()
  mat:bind(context.globals)
  gfx.submit(context.view, mat.program)
end

function GenericRenderOp:to_multiview_function(contexts)
  return function(component)
    self:multi_render(contexts, component)
  end
end

function GenericRenderOp:multi_render(contexts, component)
  -- render to multiple contexts/views, using the 'preserve_state' flag
  -- in bgfx.submit to try to minimize the number of bgfx function calls
  -- (in most cases will greatly reduce the number of uniform set calls)

  local geo, mat = component.geo, component.mat
  if (not geo) or (not mat) then return end
  if not mat.program then return end
  gfx.set_transform(component.ent.matrix_world)
  geo:bind()
  mat:bind()
  local nctx = #contexts
  local last_globals = nil
  for idx, ctx in ipairs(contexts) do
    if ctx.globals ~= last_globals then
      mat:bind_globals(ctx.globals)
    end
    last_globals = ctx.globals
    local preserve_state = (idx ~= nctx)
    gfx.submit(ctx.view, mat.program, nil, preserve_state)
  end
end

local RenderComponent = ecs.Component:extend("RenderComponent")
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
  self._render_ops = render:match_render_ops(self)
end

function RenderComponent:render()
  if self.visible == false then return end
  for _, op in ipairs(self._render_ops) do
    op(self)
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
