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
  self.phi = options.phi or 0.0
  self.theta = options.theta or 0.0

  self.phi_target = self.phi
  self.theta_target = self.theta

  self.alpha = options.alpha or 0.15
  self.tolerance = options.tolerance or 0.001

  self.phi_rate = options.phi_rate or 0.01
  self.theta_rate = options.theta_rate or 0.01
  self.pan_rate = options.pan_rate or 0.01

  self.input = options.input

  -- mouse buttons: 1 = left, 2 = middle, 3 = right
  self.rotate_button = 1
  self.pan_button = 2

  self.rad = options.rad
  self:set_zoom_limits(options.min_rad or 0.1, options.max_rad or 10.0, options.rad_steps or 10)

  self.orbitpoint = math.Vector(0, 0, 0)

  self.mount_name = "orbit_control"
end

function OrbitControl:mount()
  OrbitControl.super.mount(self)
  self:add_to_systems({"update"})
  self.input = self.input or self.ecs.systems.input
  if self.input then
    self.input:on("mousewheel", self, self.mousewheel)
    self.input:on("mousemove", self, self.mousemove)
  end
  self:wake()
end

function OrbitControl:set_zoom_limits(minrad, maxrad, steps)
  self.minrad = minrad
  self.maxrad = maxrad
  if self.minrad <= 0.0 then
    truss.error("min_rad must be positive: " .. self.minrad)
  end
  if not self.rad then
    self.rad = (self.minrad + self.maxrad) / 2.0
  end
  self.rad = math.max(self.minrad, math.min(self.maxrad, self.rad))
  self.rad_target = self.rad

  self.rad_steps = steps or self.rad_steps
  self.rad_ratio = (self.maxrad / self.minrad)^(1.0 / self.rad_steps)

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
  --self.rad_target = self.rad_target + (dv * self.rad_rate)
  if dv > 0.0 then
    self.rad_target = self.rad_target * self.rad_ratio
  elseif dv < 0.0 then
    self.rad_target = self.rad_target / self.rad_ratio
  end
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
  local rdx, rdy = evt.dx, evt.dy
  local button = evt.flags
  if button == self.rotate_button then
    self:move_theta(rdx)
    self:move_phi(-rdy)
  elseif button == self.pan_button then
    -- scale pan_rate to rad so that it's reasonable at all zooms
    self:pan_orbit_point(-rdx * self.pan_rate * self.rad, 
                          rdy * self.pan_rate * self.rad)
  end
end

function OrbitControl:update()
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
