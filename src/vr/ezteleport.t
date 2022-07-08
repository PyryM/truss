-- ezteleport.t
--
-- basic teleportation

local class = require("class")
local math = require("math")

local m = {}

local EZTeleport = class("EZTeleport")
m.EZTeleport = EZTeleport

function EZTeleport:init(roomroot, marker)
    self.roomroot = roomroot
    self.marker = marker
    self.prepareTeleport = false
    self.a = 20.0
    self.c = 0.5
end

local teleportDir = math.Vector()
local teleportOrigin = math.Vector()

function EZTeleport:update()
    if not self.controller then return end

    self.marker.active = false
    if self.controller.controller.touched.SteamVR_Touchpad then
        self.marker.active = true

        local jumpfrac = (self.controller.controller.trackpad1.y + 1.0) / 2.0
        local jumpDistance = self.a*jumpfrac*jumpfrac + self.c

        -- get forward-Z direction of controller
        self.controller.matrixWorld:getColumn(3, teleportDir)
        self.controller.matrixWorld:getColumn(4, teleportOrigin)

        teleportDir:multiplyScalar(jumpDistance)
        teleportOrigin:sub(teleportDir)

        self.marker.position:copy(teleportOrigin)
        self.marker:updateMatrix()
    end

    if self.controller.controller.pressed.SteamVR_Touchpad then
        self.prepareTeleport = true
    elseif self.prepareTeleport then -- was held down, now released
        self.roomroot.matrix:copy(self.marker.matrixWorld)
        self.prepareTeleport = false
    end
end

return m
