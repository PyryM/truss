local entity = require("ecs/entity.t")
local class = require("class")

local function recursive_event_handlers(root, evt_name, arg)
  root:event_handlers(evt_name, arg)
  for _,child in pairs(root.children) do
    recursive_event_handlers(child, evt_name, arg)
  end
end

local function recursive_event_raw(root, evt_name, arg)
  root:event_raw(evt_name, arg)
  for _,child in pairs(root.children) do
    recursive_event_raw(child, evt_name, arg)
  end
end

local CompFoo = class("CompFoo")
function CompFoo:init()
  self.foo = 1
end

function CompFoo:on_foo()
  self.foo = self.foo + 1
end

function CompFoo:mount(entity, compname)
  entity:_auto_add_handlers(self)
end

local CompBar = class("CompBar")
function CompBar:init()
  self.bar = 1
end

function CompBar:on_bar()
  self.bar = self.bar + 1
end

function CompBar:on_update()
  print("yaya")
end

function CompBar:do_thing()
  print("the original!")
end

function CompBar:mount(entity, compname)
  entity:_auto_add_handlers(self)
end

local CompBaz = CompBar:extend("CompBaz")
function CompBaz:on_baz()
  print("shelmon bazgo!")
end

-- function CompBaz:do_thing()
--   print("bleh!")
-- end

function CompBar:do_thing()
  print("the update!")
end

local function map_class_members(obj, f, shadow)
  local c = obj.class or obj
  shadow = shadow or {}
  for k,v in pairs(c) do
    f(k,v,c.name,shadow[k])
    shadow[k] = c.name or "?"
  end
  if c.super and c.super ~= c then map_class_members(c.super, f, shadow) end
end

math.randomseed(os.time())
for i = 1,100 do math.random() end -- mersenne twister has a warmup time

local comptypes = {CompFoo, CompBar, CompBar, CompBar, CompBar}
local function rand_choice(options)
  local idx = math.random(1, #options)
  return options[idx]
end

local entity_idx = 0
local function make_tree(depth, nchildren, ncomps)
  local ret = entity.Entity("entity_" .. entity_idx)
  entity_idx = entity_idx + 1

  for i = 1,ncomps do
    local comp = rand_choice(comptypes)()
    ret:add_component(comp, "comp_" .. i)
  end

  if depth <= 0 then return ret end

  for i = 1,nchildren do
    local c = make_tree(depth-1, nchildren, ncomps)
    ret:add(c)
  end

  return ret
end

function init()
  -- nothign special to do
end

local Fruit = class("Fruit")
function Fruit:print_thing()
  print("Original function!")
end

local Apple = Fruit:extend("Apple")

Fruit.print_thing = function()
  print("Replaced function!")
end

Fruit.new_thing = function()
  print("A function added after extend!")
end

local a_fruit = Fruit()
local an_apple = Apple()
a_fruit:print_thing()  -- Replaced function! [ok]
an_apple:print_thing() -- Original function! [bad]
an_apple:new_thing()   -- A function added after extend! [ok]

function update()
  local tree = make_tree(1, 10, 4)
  print("made " .. entity_idx .. " entities.")
  local t0 = truss.tic()
  recursive_event_handlers(tree, "on_foo", {})
  local dt = truss.toc(t0)
  print("handlers took " .. dt*1000.0 .. " ms")

  t0 = truss.tic()
  recursive_event_raw(tree, "on_foo", {})
  dt = truss.toc(t0)
  print("raw took " .. dt*1000.0 .. " ms")

  t0 = truss.tic()
  recursive_event_handlers(tree, "on_foo", {})
  dt = truss.toc(t0)
  print("handlers took " .. dt*1000.0 .. " ms")

  t0 = truss.tic()
  recursive_event_raw(tree, "on_foo", {})
  dt = truss.toc(t0)
  print("raw took " .. dt*1000.0 .. " ms")
  truss.quit()

  local bazgo = CompBaz()
  map_class_members(bazgo, function(k,v,c,o)
    print(tostring(c) .. "." .. k .. ": " .. tostring(v))
  end)

  for k,v in pairs(bazgo) do
    print(k)
  end

  bazgo:do_thing()
end
