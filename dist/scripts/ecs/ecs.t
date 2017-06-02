-- ecs/ecs.t
--
-- the ecs root object

local class = require("class")
local entity = require("ecs/entity.t")
local math = require("math")
local queue = require("utils/queue.t")

local m = {}

local ECS = class("ECS")
m.ECS = ECS
function ECS:init()
  self.systems = {}
  self._ordered_systems = {}
  self.scene = entity.Entity3d(self, "ROOT")
  self._identity_mat = math.Matrix4():identity()
  self._configuration_dirty = false
  self.timings = {}
  self._current_timings = {}
  self._t0 = truss.tic()
  self._lastdt = 0
  self._global_events = {on_update = {}, on_preupdate = {}}
  self._sg_updates = queue.Queue()
end

function ECS:move_entity(entity, newparent)
  self._sg_updates:push_right({entity, newparent})
end

function ECS:resolve_graph_changes()
  local q = self._sg_updates
  while q:length() > 0 do
    local op = q:pop_left()
    op[1]:_set_parent(op[2])
  end
end

function ECS:add_global_event(evt_name)
  if not self._global_events[evt_name] then
    self._global_events[evt_name] = {}
  end
  self._configuration_dirty = true
end

function ECS:add_system(system, name, priority)
  name = name or system.mount_name
  system.mount_name = name
  system.ecs = self
  if self.systems[name] then truss.error("System name " .. name .. "taken!") end
  self.systems[name] = system
  if priority then system.update_priority = priority end
  self._configuration_dirty = true
  table.insert(self._ordered_systems, system)
  table.sort(self._ordered_systems, function(a,b)
    return (a.update_priority or 0) < (b.update_priority or 0)
  end)
  return system
end

function ECS:reconfigure()
  self.scene:call_recursive("reconfigure")
  self._configuration_dirty = false
  return self
end

function ECS:event(evt_name, evt)
  local targets = self._global_events[evt_name]
  if not targets then
    truss.error("ECS has no global event named " .. evt_name
                 .. "; global events must be pre-registered"
                 .. " with ECS:add_global_event()")
    return
  end
  for entity, _ in pairs(targets) do
    entity:event(evt_name, evt)
  end
end

function ECS:_register_for_global_event(evt_name, entity)
  local targets = self._global_events[evt_name]
  if targets then
    targets[entity] = true
  end
end

function ECS:_remove_from_global_events(entity)
  for _, targets in pairs(self._global_events) do
    targets[entity] = nil
  end
end

function ECS:_start_timing()
  if self.timing_enabled == false then return end

  self._t0 = truss.tic()
  self.timings = self._current_timings
  self._current_timings = {}
  self._lastdt = 0
end

function ECS:insert_timing_event(evt_type, evt_info)
  if self.timing_enabled == false then return end

  local cumulative_dt = truss.toc(self._t0)
  local dt = cumulative_dt - self._lastdt
  self._lastdt = cumulative_dt
  table.insert(self._current_timings, {name = evt_type, info = evt_info,
                                       dt = dt, cdt = cumulative_dt})
end

function ECS:update()
  self:insert_timing_event("frame_start")

  -- reconfigure if dirty
  if self._configuration_dirty then self:reconfigure() end

  -- update systems first
  self:insert_timing_event("configure")
  for _, system in ipairs(self._ordered_systems) do
    if system.update_begin then
      system:update_begin()
      self:insert_timing_event("subsystem_update_begin", system.mount_name)
    end
  end

  -- preupdate
  self:event("on_preupdate")
  self:insert_timing_event("preupdate")
  -- scenegraph transform update
  self.scene:recursive_update_world_mat(self._identity_mat)
  self:insert_timing_event("scenegraph")
  -- update
  self:event("on_update")
  self:insert_timing_event("update")

  -- update systems first
  for _, system in ipairs(self._ordered_systems) do
    if system.update_end then
      system:update_end()
      self:insert_timing_event("subsystem_update_end", system.mount_name)
    end
  end

  self:insert_timing_event("frame_end")
  self:_start_timing()
end

return m
