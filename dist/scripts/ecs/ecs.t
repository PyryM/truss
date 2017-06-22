-- ecs/ecs.t
--
-- the ecs root object

local class = require("class")
local entity = require("ecs/entity.t")

local m = {}

local ECS = class("ECS")
m.ECS = ECS
function ECS:init()
  self.systems = {}
  self._update_order = {}
  self.timings = {}
  self._current_timings = {}
  self._t0 = truss.tic()
  self._lastdt = 0
  self._nextid = 0
  self.scene = entity.Entity3d(self, "ROOT")
end

function ECS:get_unique_name(basename)
  self._nextid = self._nextid + 1
  return (basename or "entity_") .. self._nextid
end

function ECS:create(entity_constructor, ...)
  local ret = entity_constructor(self, ...)
  return ret
end

function ECS:add_system(system, name)
  name = name or system.mount_name
  system.ecs = self
  system.mount_name = name
  if self.systems[name] then truss.error("System name " .. name .. "taken!") end
  self.systems[name] = system
  table.insert(self._update_order, system)
  return system
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

  -- update systems
  for _, system in ipairs(self._update_order) do
    self:insert_timing_event(system.mount_name)
    system:update(self)
  end

  self:insert_timing_event("frame_end")
  self:_start_timing()
end

return m
