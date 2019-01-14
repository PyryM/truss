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
  self.auto_frame_advance = (options.auto_frame_advance ~= false)
  self.mount_name = "render" -- allow direct use of a RenderSystem as a system
  self._identity_mat = math.Matrix4():identity()
  if not options.roots then 
    log.warning("Render system created without any scene roots")
  end
  self._roots = options.roots or {}
  self._tasks = options.tasks or require("utils/queue.t").Queue()
end

function RenderSystem:set_scene_root(scene, root)
  if not root then 
    -- allow calling with root as single argument
    root, scene = scene, "default"
  end
  self._roots[scene] = root
end

function RenderSystem:_find_task_stages()
  local ret = {}
  for _, stage in ipairs(self.pipeline._ordered_stages) do
    if stage.dispatch_task then
      table.insert(ret, stage)
    end
  end
  return ret
end

function RenderSystem:queue_task(task)
  self._tasks:push(task)
end

function RenderSystem:set_pipeline(p)
  self.pipeline = p
  self.pipeline:bind(0, 255)
  self._task_stages = self:_find_task_stages()
  return self
end

function RenderSystem:_clear_op_cache()
  self._op_cache = {}
end

function RenderSystem:_match(renderable)
  local ops = self._op_cache[renderable.tags.hash]
  if not ops then
    ops = self._scene_stages:match(renderable.tags)
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
  self.ecs:insert_timing_event("render_sg")
  if not self._roots.default then
    log.warning("Default scene had no root; setting to ecs.scene")
    log.warning("(This behavior will change in the future, please provide a root)")
    self._roots.default = self.ecs.scene
  end
  for scene_name, scene_root in pairs(self._roots) do
    self:_clear_op_cache()
    self._scene_stages = self.pipeline:match_scene(scene_name)
    self:_tree_render(scene_root, self._identity_mat)
  end
  self.ecs:insert_timing_event("render_traverse")

  -- handle tasks
  --for _, task_stage in ipairs(self:_task_stages or {}) do
  for _, task_stage in ipairs(self:_find_task_stages()) do
    while self._tasks:size() > 0 and task_stage:capacity() > 0 do
      task_stage:dispatch_task(self._tasks:pop())
    end
  end

  self.pipeline:post_render()
  self.ecs:insert_timing_event("render_post")

  if self.auto_frame_advance then
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
