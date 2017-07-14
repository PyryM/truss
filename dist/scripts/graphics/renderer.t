local class = require("class")
local gfx = require("gfx")
local ecs = require("ecs")
local math = require("math")
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

function GenericRenderOp:render(component)
  local geo, mat = component.geo, component.mat
  if (not geo) or (not mat) then return end
  if not mat.program then return end
  gfx.set_transform(component.ent.matrix_world)
  geo:bind()
  if mat.state then gfx.set_state(mat.state) end
  if mat.uniforms then mat.uniforms:bind() end
  if mat.globals then
    local g = self.stage.globals
    for _, v in ipairs(mat.globals) do
      if g[v] then g[v]:bind() end
    end
  end
  gfx.submit(self.stage.view, mat.program)
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
