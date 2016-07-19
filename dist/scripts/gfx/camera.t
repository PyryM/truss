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
    self.invProjMat = math.Matrix4():identity()
    self.viewProjMat = math.Matrix4():identity()
end

function Camera:makeProjection(fovDegrees, aspect, near, far)
    self.projMat:makeProjection(fovDegrees, aspect, near, far)
    self.invProjMat:invert(self.projMat)
    return self
end

function Camera:makeOrthographic(left, right, bottom, top, near, far)
    self.projMat:makeOrthographicProjection(left, right,
                                            bottom, top,
                                            near, far)
    self.invProjMat:invert(self.projMat)
    return self
end

function Camera:setProjection(newProjMat)
    self.projMat:copy(newProjMat)
    self.invProjMat:invert(self.projMat)
end

function Camera:setViewMatrices(viewid)
    self.viewMat:invert(self.matrixWorld or self.matrix)
    bgfx.bgfx_set_view_transform(viewid, self.viewMat.data, self.projMat.data)
end

function Camera:getViewMatrices()
    self.viewMat:invert(self.matrixWorld or self.matrix)
    return self.viewMat, self.projMat
end

function Camera:getViewProjMat(target)
    local view, proj = self:getViewMatrices()
    target = target or self.viewProjMat
    return target:multiply(proj, view)
end

-- "unproject" an image coordinate (in NDC, so [-1,1] w/ (0,0) center) to a ray
-- returns origin, direction (as new Vectors if none are provided; otherwise,
-- modifies the provided vectors in-place)
local tempVec = math.Vector()
function Camera:unproject(ndcX, ndcY, origin, direction)
    local p = origin or math.Vector()
    local d = direction or math.Vector()

    local worldPose = self.matrixWorld or self.matrix
    worldPose:getColumn(4, p)
    d:set(ndcX, ndcY, 0.0, 1.0)
    self.invProjMat:multiplyVector(d)
    d:perspectiveDivide():normalize3d()
    d.elem.w = 0.0              -- only apply the rotation component of the
    worldPose:multiplyVector(d) -- world pose

    return p, d
end

m.Camera = Camera
return m
