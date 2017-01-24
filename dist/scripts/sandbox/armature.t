local class = require("class")
local math = require("math")
local Object3D = require("gfx/object3d.t").Object3D

local m = {}
local Armature = class("Armature")

function Armature:init()
    self.joints = {}
    self.links = {}
    self.root = Object3D()
    self.rotationOrder = 'ZYX'
    self.warnings = {}
end

function Armature:build(srcdata, rootname)
    self.srcdata = srcdata
    self:buildFrom(rootname)
end

function Armature:setJointRotation(jointname, rotation)
    local joint = self.joints[jointname]
    if joint then
        joint.knode.quaternion:fromAxisAngle(joint.vaxis, rotation)
        joint.knode:updateMatrix()
    elseif not self.warnings[jointname] then
        self.warnings[jointname] = true
        log.warn("Joint " .. jointname .. " doesn't exist!")
    end
end

function Armature:setJoints(jointdict)
    for jointname, rotation in pairs(jointdict) do
        self:setJointRotation(jointname, rotation)
    end
end

-- function Armature:trajToJointPositions(traj) {
--     local ret = {}
--     local tlength
--     for(local jname in traj) {
--         tlength = traj[jname].length
--         break
--     }
--     for(local t = 0 t < tlength ++t) {
--         local curj = {}
--         for(local jname in traj) {
--             curj[jname] = traj[jname][t]
--         }
--         this.setJoints(curj)
--         this.getJointWorldPositions(ret)
--     }
--     return ret
-- end

-- function Armature:getJointWorldPositions(target) {
--     local ret = target || {}
--     this.root.updateMatrixWorld()
--     for(local jname in this.joints) {
--         local vpos = new THREE.Vector3()
--         vpos.setFromMatrixPosition(this.joints[jname].knode.matrixWorld)
--         if(!(jname in ret)) {
--             ret[jname] = []
--         }
--         ret[jname].push(vpos)
--     }
--     return ret
-- end

function Armature:buildFrom(nodename)
    -- first, build a tree of parents
    local tempdata = {}
    --console.log(this.srcdata)
    --console.log(l)

    for linkname, templink in pairs(self.srcdata.links) do
        --console.log(linkname)
        tempdata[linkname] = {name = linkname, vdata = templink, 
                              children = {}, kdata = nil, parent = nil,
                              parent_joint = nil}
    end
    for jointname, tj in pairs(self.srcdata.joints) do
        --console.log(jointname)
        local parent = tj.parent and tempdata[tj.parent]
        local child  = tj.child and tempdata[tj.child]
        if child and parent then
            table.insert(parent.children, child)
            child.kdata = tj
            child.parent = parent
            child.parent_joint = jointname
        else
            log.warn("P: " .. tj.parent .. "/C: " .. tj.child + " missing!")
        end
    end
    self.fulldata = tempdata
    --console.log(self.fulldata)

    self.joints["root"] = {knode = self.root, axis = math.Vector(1,0,0)}
    self:recursiveBuild(self.joints["root"], self.fulldata[nodename])
end

function Armature:buildLink(parent, linkdata)
    local bknode = Object3D()
    local knode = Object3D()
    parent.knode:add(bknode)
    bknode:add(knode)
    local vnode = Object3D()
    knode:add(vnode)

    local axis = {1,0,0}
    if linkdata.kdata then
        axis = linkdata.kdata.axis
        bknode.position:fromArray(linkdata.kdata.vpos)
        bknode.quaternion:fromEuler(linkdata.kdata.vrot, self.rotationOrder)
        bknode:updateMatrix()
    end

    --local s = linkdata.vdata.vscale
    vnode.position:fromArray(linkdata.vdata.vpos)
    vnode.quaternion:fromEuler(linkdata.vdata.vrot, self.rotationOrder)
    vnode:updateMatrix()
    self:loadModel("meshes/" .. linkdata.vdata.meshname, vnode, linkdata.vdata.color)

    local vaxis = math.Vector():fromArray(axis)
    vaxis:normalize()
    return {knode = knode, vnode = vnode, axis = axis, vaxis = vaxis}
end

function Armature:recursiveBuild(parent, cn)
    log.debug("Building " .. cn.name)
    local newnode = self:buildLink(parent, cn)
    self.links[cn.name] = newnode
    if cn.parent_joint then
        self.joints[cn.parent_joint] = newnode
    end

    for _, child in ipairs(cn.children) do
        self:recursiveBuild(newnode, child)
    end
end

function Armature:loadModel(filename, dest, color)
    if self.modelGetter then
        self.modelGetter(filename, dest, self)
    end
end

m.Armature = Armature
return m