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
  self._identity_mat = math.Matrix4():identity()
end

function RenderSystem:match_component(component, ret)
  return self._pipeline:match_render_ops(component, ret)
end

function RenderSystem:set_pipeline(p)
  self.pipeline = p
  self.pipeline:bind()
  return self
end

function RenderSystem:_clear_op_cache()
  self._op_cache = {}
end

function RenderSystem:_match(renderable)
  local ops = self._op_cache[renderable.tags.hash]
  if not ops then
    ops = self.pipeline:match(renderable.tags)
    self._op_cache[renderable.tags.hash] = ops
  end
  return ops
end

function RenderSystem:_tree_render(entity, parentmat)
  if not entity.visible then return end
  if not entity.matrix then return end

  local mw = entity.matrix_world
  mw:multiply(parentmat, entity.matrix)

  local renderable = entity.renderable
  if renderable then
    local ops = self:_match(renderable)
    local nops = #ops
    for i = 1, nops do
      ops[i](renderable, mw)
    end
  end
  for _, child in pairs(entity.children) do
    self:_tree_render(child, mw)
  end
end

function RenderSystem:update()
  if not self.pipeline then return end
  self.pipeline:pre_render()
  --self.ecs.scene:recursive_update_world_mat(self._identity_mat)
  self.ecs:insert_timing_event("render_sg")
  self:_clear_op_cache()
  self:_tree_render(self.ecs.scene, self._identity_mat)
  self.ecs:insert_timing_event("render_traverse")
  self.pipeline:post_render()
  self.ecs:insert_timing_event("render_post")

  if self.auto_frame_advance ~= false then
    gfx.frame()
  end
end

local RenderComponent = ecs.Component:extend("RenderComponent")
m.RenderComponent = RenderComponent
function RenderComponent:init()
  self.tags = gfx.tagset{}
end

function RenderComponent:mount()
  RenderComponent.super.mount(self)
  if self.ent.renderable and self.ent.renderable ~= self then
    truss.error("One entity cannot have two renderables!")
  end
  self.ent.renderable = self
end

local MeshComponent = RenderComponent:extend("MeshComponent")
m.MeshComponent = MeshComponent

function MeshComponent:init(geo, mat)
  self.tags = gfx.tagset{compiled = true}
  self.tags:extend(mat.tags or {})
  self.tags:extend(geo.tags or {})
  self.mount_name = "mesh"
  self.drawcall = gfx.Drawcall(geo, mat)
end

function MeshComponent:set_geometry(geo)
  if not geo then truss.error("No geo provided to set_geometry!") end
  self.drawcall:set_geometry(geo)
end

function MeshComponent:set_material(mat)
  if not mat then truss.error("No mat provided to set_material!") end
  self.drawcall:set_material(mat)
  self.tags:extend(mat.tags or {})
end

local DummyMeshComponent = ecs.Component:extend("DummyMeshComponent")
function DummyMeshComponent:init(geo, mat)
  self.geo, self.mat = geo, mat
  self.mount_name = "mesh"
end

-- convenience Mesh entity
m.Mesh = ecs.promote("Mesh", MeshComponent)
m.DummyMesh = ecs.promote("DummyMesh", DummyMeshComponent)

return m
