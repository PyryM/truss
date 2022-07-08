-- vr/modelloader.t
--
-- handles openvr model loading
-- loaded by openvr.t, should not be required directly

local m = {}
local openvr_c = nil
local openvr = nil
local Queue = require("util/queue.t").Queue
local gfx = require("gfx")
local math = require("math")

function m.init(_parent)
  openvr_c = _parent.c_api
  openvr = _parent

  local addonfuncs = truss.addons.openvr.functions
  local addonptr   = truss.addons.openvr.pointer

  m.rendermodelsptr = addonfuncs.truss_openvr_get_rendermodels(addonptr)

  -- have to create these indirect functions because there is no syntax to
  -- deal with double pointers from lua
  m.TargetStuff = struct {
    model: &openvr_c.RenderModel_t;
    texture: &openvr_c.RenderModel_TextureMap_t;
  }
  m.targets = terralib.new(m.TargetStuff)

  terra m.ovr_load_model(ovrptr: &openvr_c.IVRRenderModels, fn: &int8, tgt: &m.TargetStuff) : openvr_c.EVRRenderModelError
    return openvr_c.LoadRenderModel_Async(ovrptr, fn, &(tgt.model))
  end

  terra m.ovr_load_tex(ovrptr: &openvr_c.IVRRenderModels, texid: int32, tgt: &m.TargetStuff) : openvr_c.EVRRenderModelError
    return openvr_c.LoadTexture_Async(ovrptr, texid, &(tgt.texture))
  end

  -- if we need to pass a pointer to something, it's simpler to make an
  -- array and then index array[0] in lua
  m.task_queue = Queue()
  m.cache = {}
  m.options = {}
end

function m.update()
  if m.task_queue:length() <= 0 then return end
  local task = m.task_queue:peek()
  local completed = task:execute()
  if completed then m.task_queue:pop() end
end

local pose_info = nil
local controller_info = nil
function m.get_part_pose(controller_state, part)
  pose_info = pose_info or terralib.new(openvr_c.RenderModel_ComponentState_t)
  controller_info = controller_info or terralib.new(openvr_c.RenderModel_ControllerMode_State_t)
  local happy = openvr_c.GetComponentState(m.rendermodelsptr, 
                            part.parent_model_name, part.name, 
                            controller_state, 
                            controller_info, pose_info)
  if not happy then return end
  part.visible = bit.band(pose_info.uProperties, openvr_c.EVRComponentProperty_VRComponentProperty_IsVisible) > 0
  part.static = bit.band(pose_info.uProperties, openvr_c.EVRComponentProperty_VRComponentProperty_IsStatic) > 0
  if not part.pose then part.pose = math.Matrix4():identity() end
  openvr.openvr_mat34_to_mat(pose_info.mTrackingToComponentRenderModel, part.pose)
end

local function load_model_task(task)
  -- check if the model is already in the cache
  local geo_name = "geo_" .. task.model_name
  local cached_val = m.cache[geo_name]
  if cached_val ~= nil then
    log.debug("Cache Fetched " .. task.model_name .. " from cache.")
    task.geo = cached_val
    m._dispatch_success(task)
    return true
  end

  -- try to load the geometry
  local loaderr = m.ovr_load_model(m.rendermodelsptr, task.model_name, m.targets)
  if loaderr == openvr_c.EVRRenderModelError_VRRenderModelError_None then
    -- loaded
    log.debug("Async load returned for model " .. task.model_name)
    local model = m.targets.model
    if openvr.bad_structs then
      log.debug("modelloader: Using linux struct hack")
      model = openvr.bad_structs.RenderModel_t:overlay(m.targets.model)
      model:decode()
    end
    local geo = m._ovr_model_to_geo(task.model_name, model)
    local texid = model.diffuse_tex_id
    task.geo = geo
    task.texid = texid
    m.cache[geo_name] = task.geo
    m._dispatch_success(task)
    openvr_c.FreeRenderModel(m.rendermodelsptr, m.targets.model)
    return true
  elseif loaderr == openvr_c.EVRRenderModelError_VRRenderModelError_Loading then
    -- still loading (nothing to do but wait)
    return false
  else
    -- an actual error
    log.error("Error loading model " .. tostring(m.model_name) ..
              ": " .. tostring(loaderr))
    if task.on_fail then
      task:on_fail(loaderr)
    end
    return false
  end
end

local function load_texture_task(task)
  if task.geo == nil or task.texid == nil then
    log.error("modelloader: Invalid texture id on task!")
    return true
  end
  local tex_name = "tex_" .. task.texid
  local cached_val = m.cache[tex_name]
  if cached_val ~= nil then
    log.debug("Fetched texture for " .. task.model_name .. " from cache.")
    task.texture = cached_val
    m._dispatch_success(task)
    return true
  end

  local loaderr = m.ovr_load_tex(m.rendermodelsptr, task.texid, m.targets)
  if loaderr == openvr_c.EVRRenderModelError_VRRenderModelError_None then
    -- loaded
    log.debug("Async texture returned for model " .. task.model_name)
    local tex = m._ovr_tex_to_tex(task.texid, m.targets.texture)
    task.texture = tex
    m.cache[tex_name] = tex
    m._dispatch_success(task)
    openvr_c.FreeTexture(m.rendermodelsptr, m.targets.texture)
    return true
  elseif loaderr == openvr_c.EVRRenderModelError_VRRenderModelError_Loading then
    -- still loading (nothing to do but wait)
    return false
  else
    -- an actual error
    log.error("Error loading texture for " .. tostring(m.model_name) ..
              ": " .. tostring(loaderr))
    if task.on_fail then
        task:on_fail(loaderr)
    end
    return false
  end
end

function m._dispatch_success(task)
  if not task.load_textures or task.texture ~= nil then
    task:on_load()
  else -- load_textures and task.texture == nil
    task.execute = load_texture_task
    m.task_queue:push(task)
  end
end

m.string_buff_size = 512 -- maybe needs to be larger???
m.string_buff = terralib.new(int8[m.string_buff_size])

function m.enumerate_parts(trackable)
  if not trackable.device_idx then return nil end
  local base_model_name = trackable:get_prop("RenderModelName")
  log.info("Base model: " .. base_model_name)
  local n_parts = openvr_c.GetComponentCount(m.rendermodelsptr, base_model_name)
  log.info("num parts: " .. n_parts)
  local parts = {}
  for i = 1, n_parts do
    local retlen = openvr_c.GetComponentName(m.rendermodelsptr, 
                                            base_model_name, i - 1, 
                                            m.string_buff, m.string_buff_size)
    if retlen > 0 then
      local part_name = ffi.string(m.string_buff, retlen-1) -- strip /0 term
      local part_button_mask = openvr_c.GetComponentButtonMask(m.rendermodelsptr,
                                              base_model_name, part_name)
      retlen = openvr_c.GetComponentRenderModelName(m.rendermodelsptr, 
                                              base_model_name, part_name, 
                                              m.string_buff, m.string_buff_size)
      local part_model_name = nil
      if retlen > 0 then
        part_model_name = ffi.string(m.string_buff, retlen-1) -- strip /0 term
      end
      parts[part_name] = {
        name = part_name,
        button_mask = part_button_mask,
        parent_model_name = base_model_name,
        model_name = part_model_name
      }
    else
      log.info("Component " .. base_model_name .. ":" .. (i-1) .. " has no name?")
    end
  end
  return parts
end

function m._load_model(trackable, model_name, cb_success, cb_fail, load_textures)
  local task = {trackable = trackable,
                on_load = cb_success,
                on_fail = cb_fail,
                execute = load_model_task,
                model_name = model_name,
                load_textures = load_textures}
  m.task_queue:push(task)
end

function m.load_device_model(trackable, cb_success, cb_fail, load_textures)
  if trackable.device_idx == nil then
    log.error("Nil device index")
    cb_fail({trackable = trackable}, "Nil device index.")
    return
  end
  log.debug("Requesting model for " .. trackable.device_idx .. " | " ..
                                       trackable.device_class_name)
  local model_name = trackable:get_prop("RenderModelName")
  if not model_name then
    log.error("No render model available for " .. trackable.device_class_name)
    cb_fail({trackable = trackable}, "No render model available.")
    return
  end
  m._load_model(trackable, model_name, cb_success, cb_fail, load_textures)
end

function m.load_part_model(trackable, part, cb_succ, cb_fail, load_textures)
  if not part.model_name then return end
  m._load_model(trackable, part.model_name, cb_succ, cb_fail, load_textures)
end

function m._ovr_tex_to_tex(texid, data)
  local flags = 0 -- default texture flags
  local w, h = data.unWidth, data.unHeight
  log.debug("modelloader got tex of size " .. w .. " x " .. h)
  local datalen = w * h * 4
  return gfx.create_texture_from_data(w, h, data.rubTextureMapData,
                                          datalen, flags)
end

function m._ovr_model_to_geo(name, data)
  local vertinfo = m.options.vertinfo or
          gfx.create_basic_vertex_type({"position", "normal", "texcoord0"})
  local nverts, nindices = data.unVertexCount, data.unTriangleCount*3
  log.debug("modelloader got " .. nverts .. " vertices, and " ..
            nindices .. " indices.")
  local geo = gfx.StaticGeometry(name)
  geo:allocate(nverts, nindices, vertinfo)

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

  if m.options.commit == nil or m.options.commit == true then
    geo:commit()
  end

  return geo
end

return m
