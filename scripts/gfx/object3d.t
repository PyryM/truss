-- object3d.t
--
-- base class for 3d objects

local class = require("class")
local Matrix4 = require("math/matrix.t").Matrix4
local Quaternion = require("math/quat.t").Quaternion
local Vector = require("math/vec.t").Vector

local m = {}

local nextid = 1

local Object3D = class("Object3D")
function Object3D:init(geo, mat)
    self.matrix = Matrix4():identity()
    self.quaternion = Quaternion():identity()
    self.position = Vector(0.0, 0.0, 0.0)
    self.scale = Vector(1.0, 1.0, 1.0)
    self.id = nextid
    nextid = nextid + 1

    self.children = {}
    self.geo = geo
    self.mat = mat
    self.material = mat

    self.active = true
end

function Object3D:updateMatrix()
    self.matrix:compose(self.quaternion, self.scale, self.position)
end

function Object3D:add(child)
    if self.sg then self.sg:addChild(self, child) end
end

function Object3D:remove(child)
    if self.sg then self.sg:removeChild(self, child) end
end

m.Object3D = Object3D

return m