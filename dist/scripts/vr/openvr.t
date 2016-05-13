-- vr/openvr.t
--
-- wrapper for the openvr api

local m = {}
local class = require("class")
local math = require("math")

function m.init()
    if raw_addons.openvr ~= nil then
        m.openvr_c = terralib.includec("include/openvr_c.h")
        local addonfuncs = raw_addons.openvr.functions
        local addonptr   = raw_addons.openvr.pointer
        local success = addonfuncs.truss_openvr_init(addonptr, 0)
        if success > 0 then
            m.sysptr = terralib.cast(addonfuncs.truss_openvr_get_system(addonptr),
                                     &[m.openvr_c.IVRSystem])
            m.compositorptr = terralib.cast(addonfuncs.truss_openvr_get_compositor(addonptr),
                                            &[m.openvr_c.IVRCompositor])
            m.addonfuncs = addonfuncs
            m.addonptr = addonptr

            m.eyePoses = {math.Matrix4():identity(), math.Matrix4():identity()}
            m.eyeOffsets = {math.Matrix4():identity(), math.Matrix4():identity()}
            m.eyeProjections = {math.Matrix4():identity(), math.Matrix4():identity()}

            m.hmd = {
                pose = math.Matrix4():identity(),
                velocity = math.Vector():zero(),
                connected = false,
                poseValid = false
            }
            m.eyeIDs = {m.openvr_c.EVREye_Eye_Left, m.openvr_c.EVREye_Eye_Right}

            m.maxTrackables = m.openvr_c.k_unMaxTrackedDeviceCount
            m.trackables = terralib.new(m.openvr_c.TrackedDevicePose_t[m.maxTrackables])

            m.controllers = {}
            m.referencePoints = {}
            for i = 1,m.maxTrackables do
                m.controllers[i] = {}
                m.referencePoints[i] = {}
            end

            return true, ""
        else
            local errorstr = "OpenVR init error: " .. ffi.string(addonfuncs.truss_openvr_get_last_error(addonptr))
            log.error(errorstr)
            return false, errorstr
        end
    else
        local estr = "vr/openvr.t: interpreter does not have openvr attached!"
        log.error(estr)
        return false, estr
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
        target.rawstate = terralib.new(m.openvr_c.VRControllerState_t)
    end
    m.openvr_c.tr_ovw_GetControllerState(m.sysptr, controlleridx, target.rawstate)
end

function m.updateTrackables()
    local controllerIdx = 0
    local referenceIdx = 0
    local hmdIdx = 0

    for i = 0,m.maxTrackables do
        local trackable = m.trackables[i]
        if trackable.bPoseIsValid > 0 then
            local ttype = m.openvr_c.tr_ovw_GetTrackedDeviceClass(m.sysptr, i)
            local target = nil
            if ttype == m.openvr_c.ETrackedDeviceClass_TrackedDeviceClass_Controller then
                controllerIdx = controllerIdx + 1
                target = m.controllers[controllerIdx]
                m.controllerIdxToTable(i, target)
            elseif ttype == m.openvr_c.ETrackedDeviceClass_TrackedDeviceClass_TrackingReference then
                referenceIdx = referenceIdx + 1
                target = m.referencePoints[referenceIdx]
            elseif ttype == m.openvr_c.ETrackedDeviceClass_TrackedDeviceClass_HMD then
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
    local api = m.openvr_c.EGraphicsAPIConvention_API_DirectX
    for i, eyeID in ipairs(self.eyeIDs) do
        local m44 = m.openvr_c.tr_ovw_GetProjectionMatrix(m.sysptr, eyeID, near, far, api)
        m.openvrMatrix4x4ToMatrix(m44, m.eyeProjections[i])
    end
end

function m.updateOffsets_()
    for i, eyeID in ipairs(self.eyeIDs) do
        local m34 = m.openvr_c.tr_ovw_GetEyeToHeadTransform(m.sysptr, eyeID)
        m.openvrMatrix3x4ToMatrix(m34, m.eyeOffsets[i])
    end
end

function m.getEyePoses()
    m.updateOffsets_()
    for i = 1,2 do
        m.eyePoses[i]:identity()
        m.eyePoses[i]:multiply(m.eyeOffsets[i], m.hmd.pose)
    end
    return m.eyePoses
end

function m.getEyeProjectionMatrices()
    -- todo
end

function m.getRecommendedTargetSize()
    local w = terralib.new(uint32)
    local h = terralib.new(uint32)
    m.openvr_c.tr_ovw_GetRecommendedRenderTargetSize(m.sysptr, w, h)
    log.info("W: " .. w, "H: " .. h)
    return tonumber(w), tonumber(h)
end
