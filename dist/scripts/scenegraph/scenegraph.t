-- scenegraph/scenegraph.t
--
-- mixins for scenegraph stuff

local m = {}
local math = require("math")

-- misc utility functions -------------------------------------------
---------------------------------------------------------------------

-- apply function f to object and all of object's descendents
local function recursive_apply(object, f, arg)
  f(object, arg)

  for _,child in pairs(object.children) do
    recursive_apply(child, f, arg)
  end
end
m.recursive_apply = recursive_apply

-- mixins -----------------------------------------------------------
---------------------------------------------------------------------

-- how deep a scenegraph tree can be
m.MAX_TREE_DEPTH = 200

-- mixin functions for having a transform (pos+scale+quat -> matrix)
local TransformableMixin = {}
m.TransformableMixin = TransformableMixin

function TransformableMixin:tf_init()
  self.position = math.Vector(0.0, 0.0, 0.0, 0.0)
  self.scale = math.Vector(1.0, 1.0, 1.0, 0.0)
  self.quaternion = math.Quaternion():identity()
  self.matrix = math.Matrix4():identity()
end

function TransformableMixin:update_matrix()
  self.matrix:compose(self.position, self.quaternion, self.scale)
end

-- recursively calculate world matrices from local transforms for
-- object and all its children
function TransformableMixin:recursive_update_world_mat(parentmat)
  if self.enabled == false or (not self.matrix) then return end

  local worldmat = self.matrix_world or math.Matrix4():identity()
  self.matrix_world = worldmat
  worldmat:multiply(parentmat, self.matrix)

  for _,child in pairs(self.children) do
    child:recursive_update_world_mat(worldmat)
  end
end

-- mixin for having a tree of children
local ScenegraphMixin = {}
m.ScenegraphMixin = ScenegraphMixin

function ScenegraphMixin:sg_init()
  self.children = {}
  self.enabled = true
end

-- check whether adding a prospective child to a parent
-- would cause a cycle (i.e., that our scene tree would
-- no longer be a tree)
local function would_cause_cycle(parent, prospectiveChild)
  -- we would have a cycle if tracing the parent up
  -- to root would encounter the child or itself
  local depth = 0
  local curnode = parent
  local MAXD = m.MAX_TREE_DEPTH
  while curnode ~= nil do
    curnode = curnode.parent
    if curnode == parent or curnode == prospectiveChild then
      log.error("Adding child would have caused cycle!")
      return true
    end
    depth = depth + 1
    if depth > MAXD then
      log.error("Adding child would exceed max tree depth!")
      return true
    end
  end
  return false
end

function ScenegraphMixin:add(child)
  if would_cause_cycle(self, child) then return false end

  -- remove child from its previous parent
  if child.parent then
    child.parent:remove(child)
  end

  self.children[child] = child
  child.parent = self

  if child._sg_root ~= self._sg_root then
    child:configure_recursive(self._sg_root)
  end

  return true
end

-- call a function on this node and its descendents
function ScenegraphMixin:call_recursive(func_name, ...)
  if self[func_name] then self[func_name](self, ...) end
  for _, child in pairs(self.children) do
    child:call_recursive(func_name, ...)
  end
end

function ScenegraphMixin:configure_recursive(sg_root)
  self._sg_root = sg_root
  if self.configure then self:configure(sg_root) end
  for _,child in pairs(self.children) do child:configure_recursive(sg_root) end
end

function ScenegraphMixin:remove(child)
  if not self.children[child] then return end
  self.children[child] = nil
  child.parent = nil
end

return m
