-- orbitcam.t
--
-- a yaw/pitch orbiting camera component

local class = require("class")
local math = require("math")
local ecs = require("ecs")

local m = {}

local OrbitControl = ecs.Component:extend("OrbitControl")
m.OrbitControl = OrbitControl
function OrbitControl:init(options)
  options = options or {}
  self.phi = 0.0
  self.theta = 0.0

  self.phi_target = self.phi
  self.theta_target = self.theta

  self.alpha = 0.15
  self.tolerance = 0.001

  self.phi_rate = 0.01
  self.theta_rate = 0.01
  self.rad_rate = 0.4
  self.pan_rate = 0.01

  self.last_mouse_x = 0
  self.last_mouse_y = 0

  self.input = options.input

  -- mouse buttons: 1 = left, 2 = middle, 4 = right
  self.rotate_button = 1
  self.pan_button = 2

  self.minrad = options.min_rad or 0.1
  self.maxrad = options.max_rad or 10.0
  self.rad = (self.minrad + self.maxrad) / 2.0
  self.rad_target = self.rad

  self.orbitpoint = math.Vector(0, 0, 0)

  self.mount_name = "orbit_control"
end

function OrbitControl:mount()
  OrbitControl.super.mount(self)
  self:add_to_systems({"preupdate"})
  self.input = self.input or self.ecs.systems.input
  if self.input then
    self.input:on("mousewheel", self, self.mousewheel)
    self.input:on("mousemove", self, self.mousemove)
  end
  self:wake()
end

function OrbitControl:set_zoom_limits(minrad, maxrad)
  self.minrad = minrad
  self.maxrad = maxrad
  return self
end

function OrbitControl:set(theta, phi, rad)
  self.phi = phi
  self.theta = theta
  self.rad = rad
  self.phi_target = phi
  self.theta_target = theta
  self.rad_target = rad
  return self
end

-- currently just uses a simple exponential approach
local function tween_to(val, target, alpha, tolerance, dt)
  local dval = target - val
  if math.abs(dval) < tolerance then
    return target
  else
    val = val + (dval * alpha)
    return val
  end
end

function OrbitControl:move_theta(dv)
  self.theta_target = self.theta_target + (dv * self.theta_rate)
end

function OrbitControl:move_phi(dv)
  self.phi_target = self.phi_target + (dv * self.phi_rate)
  self.phi_target = math.max(-math.pi/2, math.min(math.pi/2, self.phi_target))
end

function OrbitControl:move_rad(dv)
  self.rad_target = self.rad_target + (dv * self.rad_rate)
  self.rad_target = math.max(self.minrad, math.min(self.maxrad, self.rad_target))
end

function OrbitControl:pan_orbit_point(dx, dy)
  self:_update_matrix()
  local target = self.ent
  -- pan using basis vectors from rotation matrix
  -- Note that Matrix4:getColumn is 1-indexed
  local basisX = target.matrix:get_column(1)
  local basisY = target.matrix:get_column(2)

  -- orbitpoint += (bx*dx + by*dy)
  basisX:multiply(dx)
  basisY:multiply(dy)
  self.orbitpoint:add(basisX)
  self.orbitpoint:add(basisY)
end

function OrbitControl:mousewheel(evtname, evt)
  local dwheel = evt.y
  self:move_rad(-dwheel)
end

function OrbitControl:mousemove(evtname, evt)
  local x, y = evt.x, evt.y
  local buttons = evt.flags
  if bit.band(buttons, self.rotate_button) > 0 then
    local dx = x - self.last_mouse_x
    local dy = y - self.last_mouse_y
    self:move_theta(dx)
    self:move_phi(-dy)
  elseif bit.band(buttons, self.pan_button) > 0 then
    -- scale pan_rate to rad so that it's reasonable at all zooms
    local dx = (x - self.last_mouse_x) * self.pan_rate * self.rad
    local dy = (y - self.last_mouse_y) * self.pan_rate * self.rad
    self:pan_orbit_point(-dx, dy)
  end

  self.last_mouse_x, self.last_mouse_y = x, y
end

-- use the preupdate system to update camera position before scenegraph
function OrbitControl:preupdate()
  local dt = 1.0 / 60.0
  local alpha, tolerance = self.alpha, self.tolerance
  self.phi = tween_to(self.phi, self.phi_target, alpha, tolerance, dt)
  self.theta = tween_to(self.theta, self.theta_target, alpha, tolerance, dt)
  self.rad = tween_to(self.rad, self.rad_target, alpha, tolerance, dt)

  self:_update_matrix()
end

-- updates the actual matrix from theta/phi/rad
function OrbitControl:_update_matrix()
  local rr = self.rad * math.cos(self.phi)
  local y = -self.rad * math.sin(self.phi)
  local x = rr * math.cos(self.theta)
  local z = rr * math.sin(self.theta)
  local ent = self.ent

  local pos = ent.position
  local quat = ent.quaternion

  pos:set(x, y, z)
  pos:add(self.orbitpoint)
  quat:euler({x = self.phi, y = -self.theta + math.pi / 2.0, z = 0}, 'ZYX')
  ent:update_matrix()
end

return m
