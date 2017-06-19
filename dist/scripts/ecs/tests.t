-- ecs/tests.t
--
-- tests for the entity-component-system framework

local ecs = require("ecs")
local testlib = require("devtools/test.t")
local test = testlib.test
local m = {}

-- test that adding to system during iteration/update works
-- test that removing an entity during update works
-- test self:destroy()
-- test that sleeping works
-- test that waking works
-- test that sleeping an entity applies recursively
-- test that removing (but not sleeping) an entity still gets updates
-- test that creating a cycle throws an error
-- test adding children to a detached subtree
-- test that _in_tree is set in various weird conditions

local function make_test_ecs()
  local ECS = ecs.ECS()
  ECS:add_system(ecs.System("update", "update"))
  return ECS
end

local function test_descent(t)
  local Entity3d = ecs.Entity3d
  local ECS = make_test_ecs()
  local parent = ECS.scene:create_child(Entity3d, "blah")
  local child = parent:create_child(Entity3d, "foo")
  local grandchild = child:create_child(Entity3d, "feh")
  local brother = ECS.scene:create_child(Entity3d, "meh")
  t.ok(child:is_in_subtree(parent), "child is descendant of parent")
  t.ok(grandchild:is_in_subtree(parent), "grandchild is descendant of parent")
  t.ok(not parent:is_in_subtree(child), "parent is not descendant of child")
  t.ok(not brother:is_in_subtree(parent), "parent and brother not descendants")
  t.ok(not parent:is_in_subtree(brother), "parent and brother not descendants")
  t.ok(parent:is_in_subtree(parent), "parent is in its own subtree")
  t.ok(not parent:is_in_subtree(nil), "nothing is in subtree of nil")
end

function m.run()
  test("ECS scenegraph descent", test_descent)
end

return m
