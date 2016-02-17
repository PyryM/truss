-- scenegraph.t
--
-- scenegraph functionality

local class = require("class")
local Matrix4 = require("math/matrix.t").Matrix4

local m = {}

local SceneGraph = class("SceneGraph")

function SceneGraph:init()
    self.children = {}
    self.parent = nil
    self.sg = self
    self.matrix = Matrix4():identity()
    self.matrixWorld = Matrix4():identity()
    self.eyemat = Matrix4():identity()
    self.objects = nil -- this will be automatically refreshed after changes
end

m.MAX_TREE_DEPTH = 200

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
            return true
        end
        depth = depth + 1
        if depth > MAXD then
            return true
        end
    end
    return false
end

function SceneGraph:addChild(parent, child)
    if wouldCauseCycle(parent, child) then return false end

    if not parent.children then parent.children = {} end

    -- remove child from its previous parent
    if child.parent then
        child.sg.objects = nil -- whatever sg it was in is dirty
        child.parent.children[child.id] = nil
    end

    parent.children[child.id] = child
    child.parent = parent

    self.objects = nil -- object list needs to be refreshed

    return true
end

function SceneGraph:removeChild(parent, child)
    if parent.children then 
        parent.children[child.id] = nil
        parent.sg.objects = nil 
    end
    child.parent = nil
    child.sg = nil
end

function SceneGraph:add(child)
    return self:addChild(self, child)
end

function SceneGraph:remove(child)
    if child.parent then
        self:removeChild(child.parent, child)
    end
end

local function recursiveApply(object, f)
    f(object)

    if object.children then
        for k,v in pairs(object.children) do
            recursiveApply(v, f)
        end
    end
end

-- calls function f on object and all its children recursively
function SceneGraph:map(object, f)
    recursiveApply(object, f)
end

function SceneGraph:updateObjectList()
    local objlist = {}
    local f = function(obj)
        objlist[obj.id] = obj
    end
    self:map(self, f)
    self.objects = objlist
end

function SceneGraph:iteritems()
    if not self.objects then self:updateObjectList() end
    return pairs(self.objects)
end

local function recursiveUpdateMatrix(object, parentMatrix)
    if not object.active then return end

    if object.matrixWorld == nil then
        object.matrixWorld = Matrix4()
    end
    -- object.matrixWorld = parentMatrix * object.matrixLocal
    object.matrixWorld:multiplyInto(parentMatrix, object.matrix)

    if object.children then
        local newmat = object.matrixWorld
        for k,v in pairs(object.children) do
            recursiveUpdateMatrix(v, newmat)
        end
    end
end

function SceneGraph:updateMatrices()
    recursiveUpdateMatrix(self, self.eyemat)
end

m.SceneGraph = SceneGraph
return m