-- vr/modelloader.t
--
-- handles openvr model loading
-- loaded by openvr.t, should not be required directly

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

    m.modelCache = {}
    m.loadOptions = {}
end

function m.loadDeviceModel(device, callbackSuccess, callbackFailure)
    device.onModelLoad = callbackSuccess
    device.onModelLoadFail = callbackFailure
    device.renderModelName = parent.getTrackableStringProp(device.deviceIndex,
        openvr_c.ETrackedDeviceProperty_Prop_RenderModelName_String)
    table.insert(m.modelLoadQueue, device)
end

function m.dispatchSuccess_(device)
    device.renderModel = m.modelCache[device.renderModelName]
    if device.onModelLoad then device.onModelLoad(device) end
end

function m.update()
    if #(m.modelLoadQueue) == 0 then return end
    local loadingModel = m.modelLoadQueue[1]

    -- check if the model is already in the cache
    local cacheVal = m.modelCache[loadingModel.renderModelName]
    if cacheVal ~= nil then
        table.remove(m.modelLoadQueue, 1)
        m.dispatchSuccess_(loadingModel)
        return
    end

    -- try loading model
    local loaderr = openvr_c.tr_ovw_LoadRenderModel_Async(m.rendermodelsptr,
        loadingModel.renderModelName, m.modelTarget)
    if loaderr == openvr_c.EVRRenderModelError_VRRenderModelError_None then
        -- loaded
        table.remove(m.modelLoadQueue, 1)
        m.openVRModelPostLoad_(loadingModel, m.modelTarget[0])
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

function m.openVRModelPostLoad_(target, data)
    if m.loadOptions.asData then
        log.error("Loading as data not supported yet!")
        if target.onModelLoadFail then target.onModelLoadFail(target, "") end
    else
        m.openVRModelToGeo_(target, data)
    end
end

function m.openVRModelToGeo_(target, data)
    local StaticGeometry = require("gfx/geometry.t").StaticGeometry
    local vdefs = require("gfx/vertexdefs.t")
    local vertInfo = m.loadOptions.vertInfo or
            vdefs.createStandardVertexType({"position", "normal", "texcoord0"})
    local nverts, nindices = data.unVertexCount, data.unTriangleCount*3
    local geo = StaticGeometry(target.renderModelName)
    geo:allocate(vertInfo, nverts, nindices)

    -- copy over vertex and index data
    local vdest = geo.verts
    local vsrc = data.rVertexData
    for i = 0,nverts-1 do
        for j = 0,2 do
            vdest[i].position[j] = vsrc[i].vPosition.v[j]
            vdest[i].normal[j] = vsrc[i].vNormal.v[j]
        end
        vdest[i].texcoord0[0] = vsrc[i].rfTextureCoord[0]
        vdest[i].texcoord0[1] = vsrc[i].rfTextureCoord[1]
    end
    local idest = geo.indices
    local isrc = data.rIndexData
    for i = 0,nindices-1 do
        idest[i] = isrc[i]
    end

    if m.loadOptions.build == nil or m.loadOptions.build == true then
        geo:build()
    end

    m.modelCache[target.renderModelName] = {geo = geo, rawdata = data,
                                            textureId = tonumber(data.diffuseTextureId)}
    m.dispatchSuccess_(target)
end


return m
