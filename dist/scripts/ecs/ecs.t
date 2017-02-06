-- ecs/ecs.t
--
-- the ecs root object

local class = require("class")
local entity = require("ecs/entity.t")
local math = require("math")

local m = {}

local ECS = class("ECS")
m.ECS = ECS
function ECS:init()
  self.systems = {}
  self._ordered_systems = {}
  self.scene = entity.Entity3d("ROOT")
  self.scene._sg_root = self
  self._identity_mat = math.Matrix4():identity()
  self._configuration_dirty = false
  self.timings = {}
  self._current_timings = {}
  self._t0 = truss.tic()
  self._lastdt = 0
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

function ECS:configure()
  self.scene:configure_recursive(self)
  self._configuration_dirty = false
  return self
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
  self:insert_timing_event("unaccounted")

  -- reconfigure if dirty
  if self._configuration_dirty then self:configure() end

  -- update systems first
  self:insert_timing_event("configure")
  for _, system in ipairs(self._ordered_systems) do
    if system.update_begin then
      system:update_begin()
      self:insert_timing_event("subsystem_update_begin", system.mount_name)
    end
  end

  -- preupdate
  self.scene:event_recursive("on_preupdate")
  self:insert_timing_event("preupdate")
  -- scenegraph transform update
  self.scene:recursive_update_world_mat(self._identity_mat)
  self:insert_timing_event("scenegraph")
  -- update
  self.scene:event_recursive("on_update")
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
