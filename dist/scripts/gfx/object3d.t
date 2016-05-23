-- object3d.t
--
-- base class for 3d objects
-- also implements basic scenegraph functionality

local class = require("class")
local Matrix4 = require("math/matrix.t").Matrix4
local Quaternion = require("math/quat.t").Quaternion
local Vector = require("math/vec.t").Vector

local m = {}
m.MAX_TREE_DEPTH = 200

local nextid = 1

local Object3D = class("Object3D")
function Object3D:init(geo, mat)
    self.matrix = Matrix4():identity()
    self.quaternion = Quaternion():identity()
    self.position = Vector(0.0, 0.0, 0.0, 0.0)
    self.scale = Vector(1.0, 1.0, 1.0, 0.0)
    self.id = nextid
    nextid = nextid + 1

    self.children = {}
    self.geo = geo
    self.mat = mat
    self.material = mat

    self.active = true
end

function Object3D:setGeometry(newgeo)
    self.geo = geo
end

function Object3D:setMaterial(newmat)
    self.mat = newmat
    self.material = newmat
end

function Object3D:updateMatrix()
    self.matrix:compose(self.position, self.quaternion, self.scale)
end

-- check whether adding a prospective child to a parent
-- would cause a cycle (i.e., that our scene tree would
-- no longer be a tree)
local function wouldCauseCycle(parent, prospectiveChild)
    -- we would have a cycle if tracing the parent up
    -- to root would encounter the child or itself
    local depth = 0
    local curnode = parent
    local MAXD = m.MAX_TREE_DEPTH
    while curnode ~= nil do
        curnode = curnode.parent
        if curnode == parent or curnode == prospectiveChild then
            log.error("Adding child would have caused cycle!")
            return true
        end
        depth = depth + 1
        if depth > MAXD then
            log.error("Adding child would exceed max tree depth!")
            return true
        end
    end
    return false
end

function Object3D:add(child)
    if wouldCauseCycle(self, child) then return false end

    -- remove child from its previous parent
    if child.parent then
        child.parent:remove(child)
    end

    self.children[child] = child
    child.parent = self

    return true
end

function Object3D:remove(child)
    self.children[child] = nil
    child.parent = nil
end

local function _recursive_apply(object, f, arg)
    f(object, arg)

    for _,child in pairs(object.children) do
        _recursive_apply(child, f, arg)
    end
end

-- calls function f on target and all its children recursively
function Object3D:map(f, arg)
    _recursive_apply(self, f, arg)
end

local function _accumulate(obj, destlist)
    table.insert(destlist, obj)
end

function Object3D:items()
    local ret = {}
    self:map(_accumulate, ret)
    return ret
end

local function _recursive_update_world_mat(object, parentMatrix)
    if not object.active then return end

    local worldmat = object.matrixWorld
    if worldmat == nil then
        worldmat = Matrix4():identity()
        object.matrixWorld = worldmat
    end

    worldmat:multiplyInto(parentMatrix, object.matrix)

    for _,child in pairs(object.children) do
        _recursive_update_world_mat(child, worldmat)
    end
end

local EYE_MAT = Matrix4():identity()
function Object3D:updateMatrices()
    _recursive_update_world_mat(self, EYE_MAT)
end

m.Object3D = Object3D

return m
