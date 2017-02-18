-- vr/trackables.t
--
-- implementations for various trackable objects

local m = {}
local openvr = nil
local class = require("class")
local math = require("math")
local const = require("vr/constants.t")

function m.init(parent_openvr)
  openvr = parent_openvr
  -- not really sure why we make an array of two of these
  m.prop_error = terralib.new(openvr.c_api.ETrackedPropertyError[2])
  m._parse_props()
  m._create_button_masks()

  local openvr_c = openvr.c_api
  m.trackable_types = {
    [openvr_c.ETrackedDeviceClass_TrackedDeviceClass_HMD] =
      {name = "HMD", constructor = m.HMD},
    [openvr_c.ETrackedDeviceClass_TrackedDeviceClass_Controller] =
      {name = "Controller", constructor = m.Controller},
    [openvr_c.ETrackedDeviceClass_TrackedDeviceClass_GenericTracker] =
      {name = "Generic", constructor = m.Trackable},
    [openvr_c.ETrackedDeviceClass_TrackedDeviceClass_TrackingReference] =
      {name = "Reference", constructor = m.Trackable}
  }
end

local function find_prop_error_name(prop_error)
  local cname = openvr.c_api.tr_ovw_GetPropErrorNameFromEnum(openvr.sysptr,
                                                             prop_error)
  return ffi.string(cname)
end

local function check_prop_error(val, prop_error)
  if prop_error == openvr.c_api.ETrackedPropertyError_TrackedProp_Success then
    return val
  else
    return nil, find_prop_error_name(prop_error)
  end
end

local function get_prop(gfunc)
  return function(device_idx, prop_id)
    local ret = gfunc(openvr.sysptr, device_idx, prop_id, m.prop_error)
    return check_prop_error(ret, m.prop_error[0])
  end
end

local function get_matrix34_prop(device_idx, prop_id)
  local mat = openvr.c_api.tr_ovw_GetMatrix34TrackedDeviceProperty(openvr.sysptr, device_idx, prop_id, m.prop_error)
  local truss_mat = math.Matrix4()
  openvr.openvr_mat34_to_mat(mat, truss_mat)
  return check_prop_error(truss_mat, m.prop_error[0])
end

m.string_buff_size = 512
m.string_buff = terralib.new(int8[m.string_buff_size])

local function get_string_prop(device_idx, prop_id)
  local retsize = openvr.c_api.tr_ovw_GetStringTrackedDeviceProperty(openvr.sysptr,
    device_idx, prop_id, m.string_buff, m.string_buff_size, m.prop_error)
  if retsize < 1 then return nil end
  local ret = ffi.string(m.string_buff, retsize-1) -- strip null terminator
  return check_prop_error(ret, m.prop_error[0])
end

function m._parse_props()
  local props = {}
  local c_api = openvr.c_api
  m.trackable_props = props

  local patt = "^ETrackedDeviceProperty_Prop_([^_]*)_([^_]*)$"
  for k, prop_enum_val in pairs(c_api) do
    local prop_funcs = {
      Bool = get_prop(openvr.c_api.tr_ovw_GetBoolTrackedDeviceProperty),
      Float = get_prop(openvr.c_api.tr_ovw_GetFloatTrackedDeviceProperty),
      Uint64 = get_prop(openvr.c_api.tr_ovw_GetUint64TrackedDeviceProperty),
      Int32 = get_prop(openvr.c_api.tr_ovw_GetInt32TrackedDeviceProperty),
      String = get_string_prop,
      Matrix34 = get_matrix34_prop
    }

    local found, _, prop_name, prop_type = string.find(k, patt)
    if found then
      local gfunc = prop_funcs[prop_type]
      if gfunc then
        m.trackable_props[prop_name] = {prop_id = prop_enum_val,
                                        getter_func = gfunc}
      else
        log.warning("No getter for " .. prop_name .. ":" .. prop_type)
      end
    end
  end
end

function m._create_button_masks()
  m.button_masks = {}
  local bnames = {
    "System",
    "ApplicationMenu",
    "Grip",
    "DPad_Left",
    "DPad_Up",
    "DPad_Right",
    "DPad_Down",
    "A",
    "ProximitySensor",
    "Axis0",
    "Axis1",
    "Axis2",
    "Axis3",
    "Axis4",
    "SteamVR_Touchpad",
    "SteamVR_Trigger",
    "Dashboard_Back",
    "Max"
  }
  for _, bname in ipairs(bnames) do
    local enum_val = openvr.c_api["EVRButtonId_k_EButton_" .. bname]
    m.button_masks[bname] = math.ulllshift(1, enum_val)
  end
end

local Trackable = class("Trackable")
m.Trackable = Trackable
function Trackable:init(device_idx, device_class)
  self.device_idx = device_idx
  self.device_class = device_class
  self.device_class_name = m.trackable_types[device_class].name
end

function Trackable:get_prop(propname)
  local p = m.trackable_props[propname]
  if not p then
    truss.error("Property " .. propname .. " does not exist in openvr!")
    return nil
  end
  return p.getter_func(self.device_idx, p.prop_id)
end

function Trackable:on_lost_pose()
  log.info("Trackable " .. self.device_class_name .. " lost pose.")
end

function Trackable:on_disconnect()
  log.info("Trackable "  .. self.device_class_name .. "disconnected.")
end

function Trackable:update_pose(src)
  if self.pose == nil then self.pose = math.Matrix4():identity() end
  if self.velocity == nil then self.velocity = math.Vector():zero() end
  openvr.openvr_mat34_to_mat(src.mDeviceToAbsoluteTracking, self.pose)
  openvr.openvr_v3_to_vector(src.vVelocity, self.velocity)
  self.connected = (src.bDeviceIsConnected > 0)
  self.pose_valid = (src.bPoseIsValid > 0)
end

Trackable.update = Trackable.update_pose

local HMD = Trackable:extend("HMD")
m.HMD = HMD
function HMD:init(device_idx, device_class)
  HMD.super.init(self, device_idx, device_class)
  log.info("Creating HMD class thing")
end

function HMD:update(src)
  self:update_pose(src)
  openvr.hmd = self
end

local Controller = Trackable:extend("Controller")
m.Controller = Controller
function Controller:init(device_idx, device_class)
  Controller.super.init(self, device_idx, device_class)
  self._has_vibrated = false
end

function Controller:vibrate(strength)
  if self.device_idx == nil or not self.connected then return end
  if self._has_vibrated then return end
  local us_dur = math.min(math.floor(strength * 3500), 3500)
  if us_dur < 100 then return end
  openvr.c_api.tr_ovw_TriggerHapticPulse(openvr.sysptr, self.device_idx, 0, us_dur)
  self._has_vibrated = true
end

-- query openvr to turn its unlabeled list of five axes into named fields like
-- "trigger1", "joystick1", etc.
function Controller:_parse_axes()
  self.axes = {}
  local openvr_c = openvr.c_api

  local axislabels = {
    [tonumber(openvr_c.EVRControllerAxisType_k_eControllerAxis_TrackPad)] = {"trackpad", 0},
    [tonumber(openvr_c.EVRControllerAxisType_k_eControllerAxis_Joystick)] = {"joystick", 0},
    [tonumber(openvr_c.EVRControllerAxisType_k_eControllerAxis_Trigger)] = {"trigger", 0}
  }

  for i = 0, const.k_unControllerStateAxisCount - 1 do
    local axisEnum = openvr_c.tr_ovw_GetInt32TrackedDeviceProperty(openvr.sysptr, self.device_idx,
      openvr_c.ETrackedDeviceProperty_Prop_Axis0Type_Int32 + i, m.prop_error)
    local axisinfo = axislabels[tonumber(axisEnum)]
    if axisinfo ~= nil then
      axisinfo[2] = axisinfo[2] + 1
      local axisName = axisinfo[1] .. axisinfo[2]
      self.axes[i] = axisName
      self[axisName] = {x = 0.0, y = 0.0}
    end
  end
end

-- function Controller:update(src)
--   self:update_pose(src)
--
--   if self.rawstate == nil then
--     self.rawstate = terralib.new(openvr_c.VRControllerState_t)
--     self.pressed = {}
--     self.touched = {}
--     self.lastpacket = 0
--   end
--   local rawstate = self.rawstate
--   local lastpacket = rawstate.unPacketNum
--   openvr_c.tr_ovw_GetControllerState(openvr.sysptr, self.device_idx, rawstate)
--   -- if rawstate.unPacketNum == lastpacket then
--   --     log.debug("Skipping " .. self.device_idx ..
--   --              " packet @ " .. lastpacket)
--   --     return
--   -- end
--   local bpressed = rawstate.ulButtonPressed
--   local btouched = rawstate.ulButtonTouched
--   for bname, bmask in pairs(m.button_masks) do
--     self.pressed[bname] = math.ulland(bpressed, bmask) > 0
--     self.touched[bname] = math.ulland(btouched, bmask) > 0
--   end
--   if self.axes == nil then self:_parse_axes() end
--   for i = 0, const.k_unControllerStateAxisCount - 1 do
--     local axisName = self.axes[i]
--     if axisName ~= nil then
--       self[axisName] = {x = rawstate.rAxis[i].x, y = rawstate.rAxis[i].y}
--     end
--   end
--   self._has_vibrated = false
-- end

return m
