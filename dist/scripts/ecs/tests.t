-- ecs/tests.t
--
-- tests for the entity-component-system framework

local class = require("class")
local ecs = require("ecs")
local testlib = require("devtools/test.t")
local test = testlib.test
local m = {}

-- test that adding to system during iteration/update works
-- test that removing an entity during update works
-- test self:destroy()

local function make_test_ecs()
  local ECS = ecs.ECS()
  ECS:add_system(ecs.ScenegraphSystem())
  ECS:add_system(ecs.System("update", "update"))
  return ECS
end

local function test_events(t)
  local evt = ecs.EventEmitter()
  local receiver = {_dead = false}
  local callcount = 0
  local f = function(recv, evtname, evt)
    recv.evtname = evtname
    recv.evt = evt
    callcount = callcount + 1
  end
  evt:emit("ping") -- just make sure this doesn't crash
  evt:on("ping", receiver, f)
  evt:emit("ping", 12)
  t.ok(callcount == 1, "receiver had function called")
  t.ok(receiver.evtname == "ping", "receiever was called with 'ping'")
  t.ok(receiver.evt == 12, "receiver was called with correct arg")
  callcount = 0
  evt:emit("pong")
  t.ok(callcount == 0, "receiver was not called for pong")
  evt:remove_all(receiver)
  callcount = 0
  evt:emit("ping")
  t.ok(callcount == 0, "removed receiver was not called")
  evt:on("pingping", receiver, f)
  evt:emit("pingping")
  t.ok(callcount == 1, "pingping was called")
  receiver._dead = true
  callcount = 0
  evt:emit("pingping")
  t.ok(callcount == 0, "_dead receiver was not called")
  receiver._dead = false
  callcount = 0
  evt:on("ping2", receiver, f)
  evt:emit("ping2")
  t.ok(callcount == 1, "ping2 was called")

  -- test using an entity as an emitter
  local ECS = make_test_ecs()
  local e = ECS:create(ecs.Entity3d)
  callcount = 0
  e:on("blurgh", receiver, f)
  e:emit("blurgh")
  t.ok(callcount == 1, "entity used for events")

  -- test removing callbacks on gc
  receiver = nil
  callcount = 0
  collectgarbage("collect") -- receiver should be garbage collected
  evt:emit("ping2")
  t.ok(callcount == 0, "gc'ed receiver was not called")

  -- test using a class as a receiver
  local Foo = class("Foo")
  function Foo:update(evtname, evt)
    self.was_called = true
  end
  local myfoo = Foo()
  evt:on("mupdate", myfoo, myfoo.update)
  evt:emit("mupdate")
  t.ok(myfoo.was_called, "class :update was called")
end

local function test_systems(t)
  local ECS = ecs.ECS()
  ECS:add_system(ecs.System("update1"))
  ECS:add_system(ecs.System("update_blah", "update2"))
  ECS:add_system(ecs.System("update3"))

  local FooComp = ecs.Component:extend("FooComp")
  function FooComp:init()
    self.mount_name = "foo"
  end
  function FooComp:mount()
    FooComp.super.mount(self)
    self.call_order = {}
    self:add_to_systems({"update1", "update_blah", "update3"})
    self:wake() -- should this happen automatically?
  end
  function FooComp:update1()
    table.insert(self.call_order, 1)
  end
  function FooComp:update2()
    table.insert(self.call_order, 2)
  end
  function FooComp:update3()
    table.insert(self.call_order, 3)
  end

  local e = ECS:create(ecs.Entity3d)
  local f = e:add_component(FooComp())
  local f2 = e:add_component(FooComp(), "bar")
  t.ok(ECS.systems.update1:num_components() == 2, "Sys should have 2 components")
  local e2 = e:create_child()
  local f3 = e2:add_component(FooComp())
  ECS:update()
  ECS:update()
  t.ok(t.eq(f.call_order, {1, 2, 3, 1, 2, 3}), "Sys updates correctly ordered")
  t.ok(#(f2.call_order) == 6, "Multiple components to same system")
  f.call_order = {}
  f3.call_order = {}
  e:sleep(true) -- recursive
  ECS:update()
  t.ok(#(f.call_order) == 0, "Sleeping entity not updated")
  t.ok(#(f3.call_order) == 0, "Recursive sleep works")
  f.call_order = {}
  f3.call_order = {}
  e:wake(true) -- recursive
  ECS:update()
  t.ok(#(f.call_order) == 3, "Woken entity updated again.")
  t.ok(#(f3.call_order) == 3, "Recursive wake works")

  -- test that a system will not keep an entity/component alive that otherwise
  -- has no references
  local e2_handle = t.mem_spy(e2)
  local f3_handle = t.mem_spy(f3)
  e2:detach() -- otherwise will still live on as child of e
  e2, f3 = nil, nil
  collectgarbage("collect")
  collectgarbage("collect") -- need to do this twice for reasons
  t.ok(not e2_handle:exists(), "Entity was garbage collected")
  t.ok(not f3_handle:exists(), "Component was garbage collected")

  -- test that :destroy() works
  f.call_order = {}
  ECS:update()
  t.ok(#(f.call_order) > 0, "Setup for next test v.")
  f.call_order = {}
  e:destroy()
  ECS:update()
  t.ok(#(f.call_order) == 0, "Destroyed entity's component not updated.")
  t.ok(f._dead, "Destroyed entity's component is marked dead.")
  t.ok(not e:is_in_subtree(ECS.scene), "Destroyed entity not in scene.")
end

local function test_scenegraph(t)
  local Entity3d = ecs.Entity3d
  local ECS = make_test_ecs()
  local parent = ECS.scene:create_child(Entity3d, "blah")
  local child = parent:create_child(Entity3d, "foo")
  local grandchild = child:create_child(Entity3d, "feh")
  local brother = ECS.scene:create_child(Entity3d, "meh")
  local stranger = ECS.scene:create(Entity3d, "stranger")

  -- basic relationships work
  t.ok(child:is_in_subtree(parent), "child is descendant of parent")
  t.ok(grandchild:is_in_subtree(parent), "grandchild is descendant of parent")
  t.ok(not parent:is_in_subtree(child), "parent is not descendant of child")
  t.ok(not brother:is_in_subtree(parent), "parent and brother not descendants")
  t.ok(not parent:is_in_subtree(brother), "parent and brother not descendants")
  t.ok(parent:is_in_subtree(parent), "parent is in its own subtree")
  t.ok(not parent:is_in_subtree(nil), "nothing is in subtree of nil")
  t.ok(not stranger:is_in_subtree(ECS.scene), "stranger is not in tree")

  -- moving entities
  brother:add_child(child)
  t.ok(not child:is_in_subtree(parent), "child moved out of parent")
  t.ok(child:is_in_subtree(brother), "child moved into brother")
  t.ok(grandchild:is_in_subtree(brother), "grandchild moved as well")

  -- removing entities
  child:detach()
  t.ok(not child:is_in_subtree(ECS.scene), "child no longer in tree")
  t.ok(not grandchild:is_in_subtree(ECS.scene), "grandchild no longer in tree")
  t.err(function()
    stranger:remove_child(child)
  end, "trying to remove child from wrong parent throws error")
  -- (to remove child from whatever its parent actually is, use :detach())

  -- adding back entities
  parent:add_child(child)
  parent:add_child(child) -- setting the same parent shouldn't cause an issue
  t.ok(child:is_in_subtree(parent), "child back under parent")
  grandchild:set_parent(parent) -- move grandchild directly under parent
  t.ok(grandchild:is_in_subtree(parent), "grandchild back under parent")
  t.ok(not grandchild:is_in_subtree(child), "grandchild directly under parent")

  -- memory management
  grandchild:set_parent(child)
  local g_handle = t.mem_spy(grandchild)
  grandchild = nil
  collectgarbage("collect")
  collectgarbage("collect")
  t.ok(g_handle:exists(), "grandchild not collected (still in tree)")
  parent:remove_child(child)
  child = nil
  collectgarbage("collect")
  collectgarbage("collect")
  t.ok(not g_handle:exists(), "grandchild collected")

  -- creating a cycle should throw an error
  t.err(function()
    grandchild:add_child(ECS.scene)
  end, "creating a cycle throws an error")
end

function m.run()
  test("ECS scenegraph", test_scenegraph)
  test("ECS events", test_events)
  test("ECS systems", test_systems)
end

return m
