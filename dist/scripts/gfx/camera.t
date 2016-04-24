-- gfx/camera.t
--
-- a basic camera object

local class = require("class")
local math = require("math")
local Object3D = require("gfx/object3d.t").Object3D

local m = {}
local Camera = Object3D:extend("Camera")

function Camera:init()
    Camera.super.init(self)
    self.viewMat = math.Matrix4():identity()
    self.projMat = math.Matrix4():identity()
end

function Camera:makeProjection(fovDegrees, aspect, near, far)
    self.projMat:makeProjection(fovDegrees, aspect, near, far)
    return self
end

function Camera:makeOrthographic(left, right, bottom, top, near, far)
    self.projMat:makeOrthographicProjection(left, right,
                                            bottom, top,
                                            near, far)
    return self
end

function Camera:setViewMatrices(viewid)
    self.viewMat:invert(self.matrixWorld or self.matrix)
    bgfx.bgfx_set_view_transform(viewid, self.viewMat.data, self.projMat.data)
end

m.Camera = Camera
return m
