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

  ECS:update()
  ECS:update()
  t.ok(t.eq(f.call_order, {1, 2, 3, 1, 2, 3}), "Sys updates correctly ordered")
  t.ok(#(f2.call_order) == 6, "Multiple components to same system")
  f.call_order = {}
  e:sleep()
  ECS:update()
  t.ok(#(f.call_order) == 0, "Sleeping entity not updated")
  f.call_order = {}
  e:wake()
  ECS:update()
  t.ok(#(f.call_order) == 3, "Woken entity updated again.")
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
  test("ECS events", test_events)
  test("ECS systems", test_systems)
end

return m
