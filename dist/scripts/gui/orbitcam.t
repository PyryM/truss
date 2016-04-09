-- orbitcam.t
--
-- a yaw/pitch orbiting camera

local class = require("class")
local math = require("math")

local OrbitCameraRig = class("OrbitCameraRig")
local sdl = addons.sdl

function OrbitCameraRig:init(target)
    self.target = target

    self.phi = 0.0
    self.theta = 0.0
    self.rad = 3.0

    self.phiTarget = self.phi
    self.thetaTarget = self.theta
    self.radTarget = self.rad

    self.alpha = 0.15
    self.tolerance = 0.001

    self.phiRate = 0.01
    self.thetaRate = 0.01
    self.radRate = 0.4
    self.panRate = 0.01

    self.lastMouseX = 0 
    self.lastMouseY = 0
    
    -- mouse buttons: 1 = left, 2 = middle, 4 = right
    self.rotateMouseButton = 1                               
    self.panMouseButton = 2

    self.minrad = 0.1
    self.maxrad = 10.0
    self.orbitpoint = math.Vector(0, 0, 0)
end

-- currently just uses a simple exponential approach
local function tweenTo(val, target, alpha, tolerance, dt)
    local dval = target - val
    if math.abs(dval) < tolerance then
        return target
    else
        val = val + (dval * alpha)
        return val
    end
end

function OrbitCameraRig:moveTheta(dv)
    self.thetaTarget = self.thetaTarget + (dv * self.thetaRate)
end

function OrbitCameraRig:movePhi(dv)
    self.phiTarget = self.phiTarget + (dv * self.phiRate)
    self.phiTarget = math.max(-math.pi/2, math.min(math.pi/2, self.phiTarget))
end

function OrbitCameraRig:moveRad(dv)
    self.radTarget = self.radTarget + (dv * self.radRate)
    self.radTarget = math.max(self.minrad, math.min(self.maxrad, self.radTarget))
end

function OrbitCameraRig:panOrbitPoint(dx, dy)
    self:updateMatrix_()
    -- pan using basis vectors from rotation matrix
    -- Note that Matrix4:getColumn is 1-indexed
    local basisX = target.matrix:getColumn(1)
    local basisY = target.matrix:getColumn(2)

    -- orbitpoint += (bx*dx + by*dy)
    basisX:multiplyScalar(dx)
    basisY:multiplyScalar(dy)
    self.orbitpoint:add(basisX)
    self.orbitpoint:add(basisY)
end

function OrbitCameraRig:updateSDLZoom(evt)
    local dwheel = evt.y
    self:moveRad(-dwheel)
end

function OrbitCameraRig:updateFromSDL(evt)
    if evt.event_type == sdl.TRSS_SDL_EVENT_MOUSEWHEEL then
        self:updateSDLZoom(evt)
        return
    end
    if evt.event_type ~= sdl.TRSS_SDL_EVENT_MOUSEMOVE then return end

    local x, y = evt.x, evt.y
    local buttons = evt.flags
    if bit.band(buttons, self.rotateMouseButton) > 0 then
        local dx = x - self.lastMouseX
        local dy = y - self.lastMouseY
        self:moveTheta(dx)
        self:movePhi(-dy)
    elseif bit.band(buttons, self.panMouseButton) > 0 then
        -- scale panrate to rad so that it's reasonable at all zooms
        local dx = (x - self.lastMouseX) * self.panRate * self.rad
        local dy = (y - self.lastMouseY) * self.panRate * self.rad
        self:panOrbitPoint(-dx, dy)
    end

    self.lastMouseX, self.lastMouseY = x, y
end

function OrbitCameraRig:update(dt)
    local alpha, tolerance = self.alpha, self.tolerance
    self.phi = tweenTo(self.phi, self.phiTarget, alpha, tolerance, dt)
    self.theta = tweenTo(self.theta, self.thetaTarget, alpha, tolerance, dt)
    self.rad = tweenTo(self.rad, self.radTarget, alpha, tolerance, dt)

    self:updateMatrix_()
end

-- updates the actual matrix from theta/phi/rad
function OrbitCameraRig:updateMatrix_()
    local rr = self.rad * math.cos(self.phi)
    local y = -self.rad * math.sin(self.phi)
    local x = rr * math.cos(self.theta)
    local z = rr * math.sin(self.theta)
    local scale = self.scale

    local pos = target.pos
    local quat = target.quaternion

    pos:set(x, y, z)
    pos:add(self.orbitpoint)
    quat:fromEuler({x=self.phi,
                    y=-self.theta+math.pi/2.0,
                    z=0}, 'ZYX')
    target:updateMatrix()
end

return {OrbitCameraRig = OrbitCameraRig}