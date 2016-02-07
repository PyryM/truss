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
    self.matrix = Matrix4():identity()
    self.matrixWorld = Matrix4():identity()
    self.eyemat = Matrix4():identity()
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

local function addChild(parent, child)
    if wouldCauseCycle(parent, child) then return false end

    -- remove child from its previous parent
    if child.parent then
        child.parent.children[child.id_] = nil
    end

    parent.children[child.id_] = child
    child.parent = parent

    return true
end

function SceneGraph:add(parent, child)
    if child.sg and child.sg ~= self then
        log.error("Cannot add child: belongs to different scenegraph!")
        return false
    end
    child.sg = self
    return addChild(parent, child)
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

function SceneGraph:updateAllMatrices()
    recursiveUpdateMatrix(self, self.eyemat)
end

m.SceneGraph = SceneGraph
return m