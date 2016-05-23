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
    m.loadTaskQueue = {}
    m.modelTarget = terralib.new(&openvr_c.RenderModel_t[2])
    m.textureTarget = terralib.new(&openvr_c.RenderModel_TextureMap_t[2])

    m.loadCache = {}
    m.loadOptions = {}
end

function m.update()
    if #(m.loadTaskQueue) == 0 then return end
    local loadTask = m.loadTaskQueue[1]
    local completed = loadTask:execute()
    if completed then
        table.remove(m.modelLoadQueue, 1)
    end
end

function m.addTask_(task)
    table.insert(m.loadTaskQueue, task)
end

local function loadModelTask(task)
    -- check if the model is already in the cache
    local geoName = "geo_" .. task.renderModelName
    local cacheVal = m.loadCache[geoName]
    if cacheVal ~= nil then
        log.debug("Fetched " .. task.renderModelName .. " from cache.")
        task.model = cacheVal
        m.dispatchSuccess_(task)
        return true
    end

    -- try to load the geometry
    local loaderr = openvr_c.tr_ovw_LoadRenderModel_Async(m.rendermodelsptr, task.renderModelName, m.modelTarget)
    if loaderr == openvr_c.EVRRenderModelError_VRRenderModelError_None then
        -- loaded
        log.debug("Async load returned for model " .. task.renderModelName)
        local geo = m.openVRModelToGeo_(task.renderModelName, m.modelTarget[0])
        local texId = m.modelTarget[0].diffuseTextureId
        task.model = {geo = geo, texId = texId}
        m.loadCache[geoName] = task.model
        m.dispatchSuccess_(task)
        openvr_c.tr_ovw_FreeRenderModel(m.modelTarget[0])
        return true
    elseif loaderr == openvr_c.EVRRenderModelError_VRRenderModelError_Loading then
        -- still loading (nothing to do but wait)
        return false
    else
        -- an actual error
        log.error("Error loading model " .. tostring(m.renderModelName) ..
                  ": " .. tostring(loaderr))
        if task.onModelLoadFail then
            task.onModelLoadFail(task, loaderr)
        end
        return false
    end
end

local function loadTextureTask(task)
    if task.model == nil or task.model.texId == nil then
        log.error("modelloader: Invalid texture id on task!")
        return true
    end
    local texName = "tex_" .. task.model.texId
    local cacheVal = m.loadCache[texName]
    if cacheVal ~= nil then
        log.debug("Fetched texture for " .. task.renderModelName .. " from cache.")
        task.texture = cacheVal
        m.dispatchSuccess_(task)
        return true
    end

    local loaderr = openvr_c.LoadTexture_Async(m.rendermodelsptr, task.model.texId, m.textureTarget)
    if loaderr == openvr_c.EVRRenderModelError_VRRenderModelError_None then
        -- loaded
        log.debug("Async texture returned for model " .. task.renderModelName)
        local tex = m.openVRTexToTex_(task.model.texId, m.textureTarget[0])
        task.texture = tex
        m.loadCache[texName] = tex
        m.dispatchSuccess_(task)
        openvr_c.tr_ovw_FreeTexture(m.textureTarget[0])
        return true
    elseif loaderr == openvr_c.EVRRenderModelError_VRRenderModelError_Loading then
        -- still loading (nothing to do but wait)
        return false
    else
        -- an actual error
        log.error("Error loading texture for " .. tostring(m.renderModelName) ..
                  ": " .. tostring(loaderr))
        if task.onModelLoadFail then
            task.onModelLoadFail(task, loaderr)
        end
        return false
    end
end

function m.dispatchSuccess_(task)
    if not m.loadOptions.loadTextures or task.texture ~= nil then
        task.modelLoaded = true
        if task.onModelLoad then task.onModelLoad(task) end
    else -- loadTextures and task.texture == nil
        task.execute = loadTextureTask
        m.addTask_(task)
    end
end

function m.loadDeviceModel(device, callbackSuccess, callbackFailure)
    if device.modelLoaded then return end

    device.onModelLoad = callbackSuccess
    device.onModelLoadFail = callbackFailure
    if device.deviceIndex == nil then
        log.error("Nil device index???")
        return
    end
    log.debug("Requesting model for " .. device.deviceIndex)
    device.renderModelName = parent.getTrackableStringProp(device.deviceIndex,
        openvr_c.ETrackedDeviceProperty_Prop_RenderModelName_String)
    log.debug("Starting to load device model " .. device.renderModelName)
    local task = device
    task.execute = loadModelTask
    m.addTask_(task)
end

function m.openVRTexToTex_(texId, data)
    local texture = require("gfx/texture.t")
    local flags = 0 -- default texture flags
    local w, h = data.unWidth, data.unHeight
    local datalen = w * h * 4
    return texture.createTextureFromData(w, h, data.rubTextureMapData, datalen, flags)
end

function m.openVRModelToGeo_(targetName, data)
    local StaticGeometry = require("gfx/geometry.t").StaticGeometry
    local vdefs = require("gfx/vertexdefs.t")
    local vertInfo = m.loadOptions.vertInfo or
            vdefs.createStandardVertexType({"position", "normal", "texcoord0"})
    local nverts, nindices = data.unVertexCount, data.unTriangleCount*3
    log.debug("modelloader got " .. nverts .. " vertices, and " ..
              nindices .. " indices.")
    local geo = StaticGeometry(targetName)
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

    return geo
end


return m
