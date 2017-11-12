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
  function Foo:update2(evtname, evt)
    self.update2_called = true
  end
  local myfoo = Foo()
  local myfoo2 = Foo()
  -- GOTCHA: if the same receiver is bound twice for the same event,
  --         then the second binding replaces the first
  evt:on("mupdate", myfoo, myfoo.update2) -- this should not get called
  evt:on("mupdate", myfoo, myfoo.update)  -- this replaces the above
  evt:on("mupdate", myfoo2, myfoo2.update) -- different receiver
  evt:emit("mupdate")
  t.ok(myfoo.was_called, "class :update was called")
  t.ok(not myfoo.update2_called, "replaced callback not called")
  t.ok(myfoo2.was_called, "same function w/ 2 receivers was called")
  myfoo.was_called = false
  evt:on("mupdate", myfoo, false) -- this should clear the callback
  evt:emit("mupdate")
  t.ok(not myfoo.was_called, ":on(evt, recv, false) clears callback")
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
    if self.destroy_on_update then 
      self.ent:destroy()
    end
  end
  function FooComp:update3()
    table.insert(self.call_order, 3)
  end
  function FooComp:mark_for_destroy()
    self.destroy_on_update = true
  end

  local e = ECS:create(ecs.Entity3d)
  local f = e:add_component(FooComp())
  local f2 = e:add_component(FooComp(), "bar")
  t.ok(ECS.systems.update1:num_components() == 2, "Sys should have 2 components")
  local e2 = e:create_child(ecs.Entity)
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

  -- test :destroy during a system update
  local e4 = ECS.scene:create_child(ecs.Entity3d)
  local f4 = e4:add_component(FooComp())
  f4:mark_for_destroy()
  ECS:update()
  t.ok(t.eq(f4.call_order, {1, 2}), "Updates after destroy don't happen")
  t.ok(f4._dead, "Component is dead")
  t.ok(e4._dead, "Entity is dead")
  t.ok(not e4:is_in_subtree(ECS.scene), "Destroyed entity not in scene.")
end

local function test_scenegraph(t)
  local Entity3d = ecs.Entity3d
  local ECS = make_test_ecs()
  local parent = ECS.scene:create_child(Entity3d, "blah")
  local child = parent:create_child(Entity3d, "foo")
  local grandchild = child:create_child(Entity3d, "bobby")
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

  -- finding works
  local found_child = parent:find("bobby")
  t.ok(found_child and found_child.name == "bobby", "found bobby (grandchild)")
  grandchild.some_attribute = 23
  found_child = parent:find(function(e) return e.some_attribute == 23 end)
  t.ok(found_child and found_child.name == "bobby", "found bobby by function")
  found_child = nil -- keeping a reference around interferes with later tests
  found_child = parent:find("i don't exist")
  t.ok(found_child == nil, "didn't find nonexistent entity")

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

local function test_components(t)
  local ECS = make_test_ecs()
  local Comp = ecs.Component:extend("Comp")
  function Comp:init()
    self.mount_name = "bleh"
  end
  function Comp:do_thing()
    self.done_thing = true
  end
  function Comp:_hidden_thing()
    self.done_thing = true
  end
  local PromotedComp = ecs.promote("PromotedComp", Comp)
  t.ok(PromotedComp.do_thing ~= nil, "PromotedComp has :do_thing")
  t.ok(PromotedComp._hidden_thing == nil, "PromotedComp does not have :_hidden_thing")
  local instance = ECS.scene:create_child(PromotedComp, "Bleh")
  instance:do_thing()
  t.ok(instance.bleh.done_thing, "Promoted component function called")
end

function m.run()
  test("ECS scenegraph", test_scenegraph)
  test("ECS events", test_events)
  test("ECS systems", test_systems)
  test("ECS components", test_components)
end

return m
