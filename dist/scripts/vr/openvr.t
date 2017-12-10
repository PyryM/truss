-- vr/openvr.t
--
-- wrapper for the openvr api

local m = {}
local class = require("class")
local math = require("math")
local openvr_c = nil
local const = require("vr/constants.t")
local trackables = require("vr/trackables.t")
local modelloader = require("vr/modelloader.t")

local vr_modes = {}
if truss.addons.openvr ~= nil then
  log.info("OpenVR support is available.")
  openvr_c = terralib.includec("openvr_c.h")
  m.c_api = openvr_c
  m.available = true
  vr_modes = {
    other = openvr_c.EVRApplicationType_VRApplication_Other,
    scene = openvr_c.EVRApplicationType_VRApplication_Scene,
    overlay = openvr_c.EVRApplicationType_VRApplication_Overlay
  }
else
  log.info("openvr.t: not built with openvr, or addon not attached.")
  m.available = false
  return m
end

struct m.TargetSize {
  w: uint32;
  h: uint32;
}

function m.init(options)
  options = options or {}
  if not m.available then
    return false, "OpenVR support not built."
  end

  if options.use_linux_hacks then
    m.bad_structs = require("vr/linux_hacks.t").init_bad_structs(openvr_c)
  end

  local addonfuncs = truss.addons.openvr.functions
  local addonptr   = truss.addons.openvr.pointer
  m.openvr_mode = options.mode or "scene"
  if not vr_modes[m.openvr_mode] then
    truss.error("OpenVR application type/mode " .. m.openvr_mode 
                .. " does not exist.")
    return false, "Incorrect mode"
  end
  log.info("Initting openvr as " .. m.openvr_mode)
  local success = addonfuncs.truss_openvr_init(addonptr, vr_modes[m.openvr_mode])
  if success <= 0 then
    local errorstr = "OpenVR init error: " .. ffi.string(addonfuncs.truss_openvr_get_last_error(addonptr))
    log.error(errorstr)
    m.available = false
    return false, errorstr
  end

  log.info("VR Init succeeded...")

  m.addonfuncs = addonfuncs
  m.addonptr = addonptr

  m._init_sys()
  m.vr_event = terralib.new(openvr_c.VREvent_t)
  m._event_handlers = {}

  if m.openvr_mode == "scene" then
    m._init_compositor()
    m._init_trackables()
    modelloader.init(m)
  elseif m.openvr_mode == "other" then
    m._init_trackables()
    modelloader.init(m)
  elseif m.openvr_mode == "overlay" then
    m._init_overlay()
  end

  log.info("Finished Vr init")
  -- normally I would not care overly much about shutting down stuff on
  -- exit, but steamvr will show the app as unresponsive forever unless
  -- openvr actually shuts down
  truss.on_quit(m.shutdown)
  return true, ""
end

function m._init_overlay()
  local overlay = require("vr/overlay.t")
  overlay.init(m)
  m.create_overlay = overlay.create_overlay
end

function m._init_sys()
  m.sysptr = m.addonfuncs.truss_openvr_get_system(m.addonptr)
  log.info("sysptr: " .. tostring(m.sysptr))
end

function m._init_compositor()
  log.info("Initializing compositor")
  m.compositorptr = m.addonfuncs.truss_openvr_get_compositor(m.addonptr)
  log.info("compositor: " .. tostring(m.compositorptr))

  m.eye_poses = {math.Matrix4():identity(), math.Matrix4():identity()}
  m.eye_offsets = {math.Matrix4():identity(), math.Matrix4():identity()}
  m.eye_projections = {math.Matrix4():identity(), math.Matrix4():identity()}

  m.target_size = terralib.new(m.TargetSize)
  m.eye_submit_texes = {
    terralib.new(openvr_c.Texture_t),
    terralib.new(openvr_c.Texture_t)
  }

  m.eye_ids = {openvr_c.EVREye_Eye_Left, openvr_c.EVREye_Eye_Right}
end

function m._init_trackables()
  log.info("Initializing trackables")
  trackables.init(m)
  m.MAX_TRACKABLES = const.k_unMaxTrackedDeviceCount
  m.trackable_poses = terralib.new(openvr_c.TrackedDevicePose_t[m.MAX_TRACKABLES])
  m.trackables = {}
end

function m.shutdown()
  log.info("OpenVR shutdown...")
  if not m.available then return end
  local addonfuncs = truss.addons.openvr.functions
  local addonptr   = truss.addons.openvr.pointer
  if m.create_overlay then -- we had initialized overlays
    require("vr/overlay.t").shutdown()
  end
  addonfuncs.truss_openvr_shutdown(addonptr)
  m.available = false
end

function m.begin_frame()
  if not m.available then return false end

  if m.openvr_mode == "scene" then
    local err = openvr_c.tr_ovw_WaitGetPoses(m.compositorptr, m.trackable_poses, m.MAX_TRACKABLES, nil, 0)
    if err ~= openvr_c.EVRCompositorError_VRCompositorError_None then
      log.error("WaitGetPoses error: " .. tostring(err))
      return false
    end
    m._update_trackables()
    m._update_projections()
    m._update_eye_poses()
    modelloader.update()
    m._update_vr_events()
  elseif m.openvr_mode == "other" then
    openvr_c.tr_ovw_GetDeviceToAbsoluteTrackingPose(m.sysptr, 
      openvr_c.ETrackingUniverseOrigin_TrackingUniverseStanding, 
      0.0, m.trackable_poses, m.MAX_TRACKABLES)
    m._update_trackables()
    modelloader.update()
  end
end

function m.submit_frame(eye_texes)
  if not m.available then return false end

  for eye = 1,2 do
    m.eye_submit_texes[eye].handle = bgfx.get_internal_texture_ptr(eye_texes[eye])
    m.eye_submit_texes[eye].eType = openvr_c.ETextureType_TextureType_DirectX
    m.eye_submit_texes[eye].eColorSpace = openvr_c.EColorSpace_ColorSpace_Auto
    openvr_c.tr_ovw_Submit(m.compositorptr, m.eye_ids[eye],
                           m.eye_submit_texes[eye], nil, 0)
  end
end

function m.load_model(device, callback_success, callback_failure)
  modelloader.load_device_model(device, callback_success, callback_failure)
end

function m._process_vr_event()
  local evt = m.vr_event
  if evt.eventType == openvr_c.EVREventType_VREvent_Quit then
    log.info("Openvr requested application quit!")
    openvr_c.tr_ovw_AcknowledgeQuit_Exiting(m.sysptr)
    truss.quit()
  end
end

function m._update_vr_events()
  local evtsize = sizeof(openvr_c.VREvent_t)
  while openvr_c.tr_ovw_PollNextEvent(m.sysptr, m.vr_event, evtsize) > 0 do
    m._process_vr_event()
  end
end

function m.on(evt_name, f)
  m._event_handlers[evt_name] = m._event_handlers[evt_name] or {}
  table.insert(m._event_handlers[evt_name], f)
end

function m._emit_event(evt_name, ...)
  for _, f in ipairs(m._event_handlers[evt_name] or {}) do
    f(...)
  end
end

function m._update_trackables()
  m.has_input_focus = openvr_c.tr_ovw_IsInputFocusCapturedByAnotherProcess(m.sysptr)
  local trackable_types = trackables.trackable_types

  for i = 0, m.MAX_TRACKABLES - 1 do
    local trackable_pose = m.trackable_poses[i]
    local target = m.trackables[i+1]

    if trackable_pose.bPoseIsValid > 0 then
      local ttype = openvr_c.tr_ovw_GetTrackedDeviceClass(m.sysptr, i)
      if not target or target.device_class ~= ttype then
        if target then
          target:on_disconnect()
          m._emit_event("trackable_disconnected", target)
        end
        log.info("New trackable " .. tostring(ttype))
        target = trackable_types[ttype].constructor(i, ttype)
        m.trackables[i+1] = target
        m._emit_event("trackable_connected", target)
      end
      target:update(trackable_pose)
    elseif target then
      target:on_lost_pose()
    end
  end
end

function m.openvr_v3_to_vector(v3, target)
  local e = target.elem
  e.x, e.y, e.z, e.w = v3.v[0], v3.v[1], v3.v[2], 0.0
end

function m.openvr_v2_to_vector(v2, target)
  local e = target.elem
  e.x, e.y, e.z, e.w = v2.v[0], v2.v[1], 0.0, 0.0
end

function m.openvr_mat44_to_mat(m_4x4, target)
  local d = target.data
  local m = m_4x4.m
  d[0], d[4], d[ 8], d[12] = m[0][0], m[0][1], m[0][2], m[0][3]
  d[1], d[5], d[ 9], d[13] = m[1][0], m[1][1], m[1][2], m[1][3]
  d[2], d[6], d[10], d[14] = m[2][0], m[2][1], m[2][2], m[2][3]
  d[3], d[7], d[11], d[15] = m[3][0], m[3][1], m[3][2], m[3][3]
end

function m.openvr_mat34_to_mat(m_3x4, target)
  local d = target.data
  local m = m_3x4.m
  d[0], d[4], d[ 8], d[12] = m[0][0], m[0][1], m[0][2], m[0][3]
  d[1], d[5], d[ 9], d[13] = m[1][0], m[1][1], m[1][2], m[1][3]
  d[2], d[6], d[10], d[14] = m[2][0], m[2][1], m[2][2], m[2][3]
  d[3], d[7], d[11], d[15] =     0.0,     0.0,     0.0,     1.0
end

function m.mat_to_openvr_mat34(mat, target)
  local s = mat.data
  local d = target.m
  d[0][0], d[0][1], d[0][2], d[0][3] = s[0], s[4], s[ 8], s[12]
  d[1][0], d[1][1], d[1][2], d[1][3] = s[1], s[5], s[ 9], s[13]
  d[2][0], d[2][1], d[2][2], d[2][3] = s[2], s[6], s[10], s[14]
end

-- local terra derefInt(x: &uint32) : uint32
--   return @x
-- end

function m._update_projections()
  local near = m.nearClip or 0.05
  local far = m.farClip or 100.0
  for i, eyeID in ipairs(m.eye_ids) do
    local m44 = openvr_c.tr_ovw_GetProjectionMatrix(m.sysptr, eyeID, near, far)
    m.openvr_mat44_to_mat(m44, m.eye_projections[i])
  end
end

function m._update_eye_poses()
  for i, eyeID in ipairs(m.eye_ids) do
    local m34 = openvr_c.tr_ovw_GetEyeToHeadTransform(m.sysptr, eyeID)
    m.openvr_mat34_to_mat(m34, m.eye_offsets[i])
  end

  for i = 1,2 do
    m.eye_poses[i]:identity()
    m.eye_poses[i]:multiply(m.hmd.pose, m.eye_offsets[i])
  end
end

terra m._get_target_size(sysptr: &openvr_c.IVRSystem, target: &m.TargetSize)
  openvr_c.tr_ovw_GetRecommendedRenderTargetSize(sysptr, &target.w, &target.h)
end

function m.get_target_size()
  m._get_target_size(m.sysptr, m.target_size)
  return m.target_size.w, m.target_size.h
end

function m.print_debug_info()
  m._update_projections()
  m._update_eye_poses()
  local w,h = m.get_target_size()
  log.info("--------------openvr.print_debug_info()------------")
  log.info("Recommended target size: " .. w .. " x " .. h)
  log.info("ProjectionL: " .. m.eye_projections[1]:prettystr())
  log.info("ProjectionR: " .. m.eye_projections[2]:prettystr())
  log.info("OffsetL: " .. m.eye_offsets[1]:prettystr())
  log.info("OffsetR: " .. m.eye_offsets[2]:prettystr())
  log.info("---------------------------------------------------")
end

return m
