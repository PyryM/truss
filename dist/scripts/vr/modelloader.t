-- vr/modelloader.t
--
-- handles openvr model loading

local m = {}
local openvr_c = nil
local parent = nil

function m.init(parent_)
    openvr_c = parent_.c_api
    parent = parent_

    local addonfuncs = raw_addons.openvr.functions
    local addonptr   = raw_addons.openvr.pointer

    m.rendermodelsptr = addonfuncs.truss_openvr_get_rendermodels(addonptr)

    -- if we need to pass a pointer to something, it's simpler to make an
    -- array and then index array[0] in lua
    m.modelLoadQueue = {}
    m.modelTarget = terralib.new(&openvr_c.RenderModel_t[2])
end

function m.loadDeviceModel(device, callbackSuccess, callbackFailure)
    if device.modelData then
        callbackSuccess(device)
    else
        device.onModelLoad = callbackSuccess
        device.onModelLoadFail = callbackFailure
        device.renderModelName = parent.getTrackableStringProp(device.deviceIndex,
            openvr_c.ETrackedDeviceProperty_Prop_RenderModelName_String)
        table.insert(m.modelLoadQueue, device)
    end
end

function m.update()
    if #(m.modelLoadQueue) == 0 then return end
    local loadingModel = m.modelLoadQueue[1]
    local loaderr = openvr_c.tr_ovw_LoadRenderModel_Async(m.rendermodelsptr,
        loadingModel.renderModelName, m.modelTarget)
    if loaderr == openvr_c.EVRRenderModelError_VRRenderModelError_None then
        -- loaded
        m.openVRModelToData_(loadingModel, m.modelTarget[0])
        table.remove(m.modelLoadQueue, 1)
        if loadingModel.onModelLoad then
            loadingModel.onModelLoad(loadingModel)
        end
    elseif loaderr == openvr_c.EVRRenderModelError_VRRenderModelError_Loading then
        -- still loading (nothing to do but wait)
        return
    else
        -- an actual error
        log.error("Error loading model " .. tostring(m.renderModelName) ..
                  ": " .. tostring(loaderr))
        table.remove(m.modelLoadQueue, 1)
        if loadingModel.onModelLoadFail then
            loadingModel.onModelLoadFail(loadingModel, loaderr)
        end
    end
end

function m.openVRModelToData_(target, rawdata)
    -- todo
end


return m
