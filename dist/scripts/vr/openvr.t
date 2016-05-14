-- vr/openvr.t
--
-- wrapper for the openvr api

local m = {}
local class = require("class")
local math = require("math")
local openvr_c = nil
local const = require("vr/constants.t")

if raw_addons.openvr ~= nil then
    log.info("OpenVR support is available.")
    openvr_c = terralib.includec("include/openvr_c.h")
    m.c_api = openvr_c
    m.available = true
else
    log.info("openvr.t: not built with openvr, or addon not attached.")
    m.available = false
    return m
end

struct m.TargetSize {
    w: uint32;
    h: uint32;
}

function m.init()
    if not m.available then
        return false, "OpenVR support not built."
    end

    local addonfuncs = raw_addons.openvr.functions
    local addonptr   = raw_addons.openvr.pointer
    log.info("Initting...")
    local success = addonfuncs.truss_openvr_init(addonptr, 0)
    if success > 0 then
        log.info("VR Init succeeded...")
        m.sysptr = addonfuncs.truss_openvr_get_system(addonptr)
        m.compositorptr = addonfuncs.truss_openvr_get_compositor(addonptr)
        log.info("sysptr: " .. tostring(m.sysptr))
        log.info("compositor: " .. tostring(m.compositorptr))
        m.addonfuncs = addonfuncs
        m.addonptr = addonptr

        m.eyePoses = {math.Matrix4():identity(), math.Matrix4():identity()}
        m.eyeOffsets = {math.Matrix4():identity(), math.Matrix4():identity()}
        m.eyeProjections = {math.Matrix4():identity(), math.Matrix4():identity()}

        m.targetSize = terralib.new(m.TargetSize)

        m.hmd = {
            pose = math.Matrix4():identity(),
            velocity = math.Vector():zero(),
            connected = false,
            poseValid = false
        }
        m.eyeIDs = {openvr_c.EVREye_Eye_Left, openvr_c.EVREye_Eye_Right}

        m.maxTrackables = const.k_unMaxTrackedDeviceCount
        m.trackables = terralib.new(openvr_c.TrackedDevicePose_t[m.maxTrackables])

        m.controllers = {}
        m.referencePoints = {}
        for i = 1,m.maxTrackables do
            m.controllers[i] = {}
            m.referencePoints[i] = {}
        end

        log.info("Finished Vr init")
        return true, ""
    else
        local errorstr = "OpenVR init error: " .. ffi.string(addonfuncs.truss_openvr_get_last_error(addonptr))
        log.error(errorstr)
        return false, errorstr
    end
end

function m.trackableToTable(trackable, target)
    if target.pose == nil then target.pose = math.Matrix4():identity() end
    if target.velocity == nil then target.velocity = math.Vector():zero() end
    m.openvrMatrix3x4ToMatrix(trackable.mDeviceToAbsoluteTracking,
                              target.pose)
    m.openvrV3ToVector(trackable.vVelocity, target.velocity)
    target.connected = (trackable.bDeviceIsConnected > 0)
    target.poseValid = (trackable.bPoseIsValid > 0)
end

function m.controllerIdxToTable(controlleridx, target)
    if target.rawstate == nil then
        target.rawstate = terralib.new(openvr_c.VRControllerState_t)
    end
    openvr_c.tr_ovw_GetControllerState(m.sysptr, controlleridx, target.rawstate)
end

function m.updateTrackables()
    local controllerIdx = 0
    local referenceIdx = 0
    local hmdIdx = 0

    for i = 0,m.maxTrackables do
        local trackable = m.trackables[i]
        if trackable.bPoseIsValid > 0 then
            local ttype = openvr_c.tr_ovw_GetTrackedDeviceClass(m.sysptr, i)
            local target = nil
            if ttype == openvr_c.ETrackedDeviceClass_TrackedDeviceClass_Controller then
                controllerIdx = controllerIdx + 1
                target = m.controllers[controllerIdx]
                m.controllerIdxToTable(i, target)
            elseif ttype == openvr_c.ETrackedDeviceClass_TrackedDeviceClass_TrackingReference then
                referenceIdx = referenceIdx + 1
                target = m.referencePoints[referenceIdx]
            elseif ttype == openvr_c.ETrackedDeviceClass_TrackedDeviceClass_HMD then
                hmdIdx = hmdIdx + 1
                target = m.hmd
            end

            if target then m.trackableToTable(trackable, target) end
        end
    end

    m.nControllers = controllerIdx
    m.nReferences = referenceIdx
    m.nHMDs = hmdIdx
end

function m.openvrV3ToVector(v3, target)
    local e = target.elem
    e.x, e.y, e.z, e.w = v3.v[0], v3.v[1], v3.v[2], 0.0
end

function m.openvrV2ToVector(v2, target)
    local e = target.elem
    e.x, e.y, e.z, e.w = v2.v[0], v2.v[1], 0.0, 0.0
end

function m.openvrMatrix4x4ToMatrix(m_4x4, target)
    local d = target.data
    local m = m_4x4.m
    d[0], d[4], d[ 8], d[12] = m[0][0], m[0][1], m[0][2], m[0][3]
    d[1], d[5], d[ 9], d[13] = m[1][0], m[1][1], m[1][2], m[1][3]
    d[2], d[6], d[10], d[14] = m[2][0], m[2][1], m[2][2], m[2][3]
    d[3], d[7], d[11], d[15] = m[3][0], m[3][1], m[3][2], m[3][3]
end

function m.openvrMatrix3x4ToMatrix(m_3x4, target)
    local d = target.data
    local m = m_3x4.m
    d[0], d[4], d[ 8], d[12] = m[0][0], m[0][1], m[0][2], m[0][3]
    d[1], d[5], d[ 9], d[13] = m[1][0], m[1][1], m[1][2], m[1][3]
    d[2], d[6], d[10], d[14] = m[2][0], m[2][1], m[2][2], m[2][3]
    d[3], d[7], d[11], d[15] =     0.0,     0.0,     0.0,     1.0
end

local terra derefInt(x: &uint32) : uint32
    return @x
end

function m.updateProjections_()
    local near = m.nearClip or 0.05
    local far = m.farClip or 100.0
    local api = openvr_c.EGraphicsAPIConvention_API_DirectX
    for i, eyeID in ipairs(m.eyeIDs) do
        local m44 = openvr_c.tr_ovw_GetProjectionMatrix(m.sysptr, eyeID, near, far, api)
        m.openvrMatrix4x4ToMatrix(m44, m.eyeProjections[i])
    end
end

function m.updateOffsets_()
    for i, eyeID in ipairs(m.eyeIDs) do
        local m34 = openvr_c.tr_ovw_GetEyeToHeadTransform(m.sysptr, eyeID)
        m.openvrMatrix3x4ToMatrix(m34, m.eyeOffsets[i])
    end
end

function m.getEyePoses()
    m.updateOffsets_()
    for i = 1,2 do
        m.eyePoses[i]:identity()
        m.eyePoses[i]:multiply(m.hmd.pose, m.eyeOffsets[i])
    end
    return m.eyePoses
end

function m.getEyeProjectionMatrices()
    -- todo
end

terra m.getTargetSize_(sysptr: &openvr_c.IVRSystem, target: &m.TargetSize)
    openvr_c.tr_ovw_GetRecommendedRenderTargetSize(sysptr, &target.w, &target.h)
end

function m.getRecommendedTargetSize()
    m.getTargetSize_(m.sysptr, m.targetSize)
    return m.targetSize.w, m.targetSize.h
end

function m.printDebugInfo()
    m.updateProjections_()
    m.updateOffsets_()
    local w,h = m.getRecommendedTargetSize()
    log.info("--------------openvr.printDebugInfo()--------------")
    log.info("Recommended target size: " .. w .. " x " .. h)
    log.info("ProjectionL: " .. m.eyeProjections[1]:prettystr())
    log.info("ProjectionR: " .. m.eyeProjections[2]:prettystr())
    log.info("OffsetL: " .. m.eyeOffsets[1]:prettystr())
    log.info("OffsetR: " .. m.eyeOffsets[2]:prettystr())
    log.info("---------------------------------------------------")
end

return m
