-- orbitcam.t
--
-- a yaw/pitch orbiting camera

local class = truss_import("core/30log.lua")
local Matrix4 = truss_import("math/matrix.t").Matrix4
local Quaternion = truss_import("math/quat.t").Quaternion

local OrbitCam = class("OrbitCam")

function OrbitCam:init()
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

    self.lastMouseX = 0 
    self.lastMouseY = 0
    self.mousebutton = 1 -- 1 = left
                         -- 2 = middle
                         -- 4 = right
    self.minrad = 0.1
    self.maxrad = 10.0
    self.orbitpoint = {x = 0, y = 0, z = 0}

    self.mat = Matrix4():identity()
    self.viewmat = Matrix4():identity()
    self.quat = Quaternion():identity()
    self.pos = {x = 0, y = 0, z = 0}
    self.dirty = false
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

function OrbitCam:moveTheta(dv)
    self.thetaTarget = self.thetaTarget + (dv * self.thetaRate)
end

function OrbitCam:movePhi(dv)
    self.phiTarget = self.phiTarget + (dv * self.phiRate)
    self.phiTarget = math.max(-math.pi/2, math.min(math.pi/2, self.phiTarget))
end

function OrbitCam:moveRad(dv)
    self.radTarget = self.radTarget + (dv * self.radRate)
    self.radTarget = math.max(self.minrad, math.min(self.maxrad, self.radTarget))
end

function OrbitCam:updateSDLZoom(evt)
    local dwheel = evt.y
    self:moveRad(-dwheel)
end

function OrbitCam:updateFromSDL(evt)
    if evt.event_type == sdl.TRSS_SDL_EVENT_MOUSEWHEEL then
        self:updateSDLZoom(evt)
        return
    end
    if evt.event_type ~= sdl.TRSS_SDL_EVENT_MOUSEMOVE then return end

    local x, y = evt.x, evt.y
    local buttons = evt.flags
    if bit.band(buttons, self.mousebutton) > 0 then
        local dx = x - self.lastMouseX
        local dy = y - self.lastMouseY
        self:moveTheta(dx)
        self:movePhi(-dy)
    end

    self.lastMouseX, self.lastMouseY = x, y
end

function OrbitCam:update(dt)
    local alpha, tolerance = self.alpha, self.tolerance
    self.phi = tweenTo(self.phi, self.phiTarget, alpha, tolerance, dt)
    self.theta = tweenTo(self.theta, self.thetaTarget, alpha, tolerance, dt)
    self.rad = tweenTo(self.rad, self.radTarget, alpha, tolerance, dt)

    self:updateMatrix_()
end

-- updates the actual matrix from theta/phi/rad
function OrbitCam:updateMatrix_()
    local rr = self.rad * math.cos(self.phi)
    local y = -self.rad * math.sin(self.phi)
    local x = rr * math.cos(self.theta)
    local z = rr * math.sin(self.theta)
    local scale = {x=1, y=1, z=1}

    local pos = self.pos
    local quat = self.quat
    local op = self.orbitpoint

    pos.x, pos.y, pos.z = x + op.x, y + op.y, z + op.z
    quat:fromEuler({x=self.phi,
                    y=-self.theta+math.pi/2.0,
                    z=0}, 'ZYX')
    self.mat:compose(self.quat, scale, pos)
end

function OrbitCam:getViewMat()
    self.viewmat:invert(self.mat)
    return self.viewmat
end

return OrbitCam