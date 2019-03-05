-- vr/input.t
--
-- 'new' openvr input system

local class = require("class")
local math = require("math")
local event = require("ecs/event.t")
local stringutils = require("utils/stringutils.t")
local openvr = require("./openvr.t")
local openvr_c = openvr.c_api
local input_ptr = nil
local const = require("./constants.t")

local MAX_ACTIVE_SETS = 16

local m = {}

local function resolve_description(description)
  if type(description) == 'string' then
    return {en = description}
  else
    return description
  end
end

local function add_description_to_manifest(path, description, manifest)
  for language_tag, desc in pairs(description) do
    if not manifest._localization[language_tag] then
      manifest._localization[language_tag] = {}
    end
    manifest._localization[language_tag][path] = desc
  end
end

local Action = class("Action")
function Action:init(set_path, name, info)
  self.evt = event.EventEmitter()
  self.path = set_path .. "/in/" .. name
  self.description = resolve_description(info.description or name)  
  self.requirement = info.requirement or "suggested"
  self.kind = info.kind
end
function Action:_resolve_handle()
  if not self.path then truss.error("Action has no path!") end
  self.handle = self.handle or terralib.new(openvr_c.VRActionHandle_t[1])
  openvr.GetActionHandle(input_ptr, self.path, self.handle)
end
function Action:_check_handle()
  if not self.handle then truss.error("Action has no handle!") end
end
function Action:on(...)
  self.evt:on(...)
end
function Action:_add_to_manifest(manifest)
  table.insert(manifest.actions, {
    name = self.path,
    ['type'] = self.kind,
    requirement = self.requirement
  })
  add_description_to_manifest(self.path, self.description, manifest)
end

local function TypedAction(kind, terratype)
  local _Action = Action:extend(kind)
  local type_data_size = terralib.sizeof(terratype)
  function _Action:init(set_path, name, info)
    _Action.super.init(self, set_path, name, info)
    self.data = terralib.new(terratype)
    self.datasize = type_data_size
    if self._init then self:_init(set_path, name, info) end
  end
  return _Action
end

local PoseAction = TypedAction("PoseAction", openvr_c.InputPoseActionData_t)
function PoseAction:_init(set_path, name, info)
  self:set_origin(info.origin)
  self.pose = math.Matrix4():identity()
  self.velocity = math.Vector():zero()
  self.angular_velocity = math.Vector():zero()
end
local ORIGINS = {
  seated = openvr_c.ETrackingUniverseOrigin_TrackingUniverseSeated,
  standing = openvr_c.ETrackingUniverseOrigin_TrackingUniverseStanding,
  roomscale = openvr_c.ETrackingUniverseOrigin_TrackingUniverseStanding,
  default = openvr_c.ETrackingUniverseOrigin_TrackingUniverseStanding
}
function PoseAction:set_origin(origin)
  self._origin = ORIGINS[origin or 'default']
  if not self._origin then 
    truss.error('"' .. tostring(origin) .. '" is not a valid origin')
  end
end
function PoseAction:_update()
  self:_check_handle()
  openvr_c.GetPoseActionData(input_ptr, self.handle[0], 
    self._origin, 0.0, 
    self.data, self.datasize )
  local pose = self.data.pose
  openvr.openvr_mat34_to_mat(pose.mDeviceToAbsoluteTracking, self.pose)
  openvr.openvr_v3_to_vector(pose.vVelocity, self.velocity)
  openvr.openvr_v3_to_vector(pose.vAngularVelocity, self.angular_velocity)
  self.connected = (pose.bDeviceIsConnected > 0)
  self.pose_valid = (pose.bPoseIsValid > 0)
  self.evt:emit("change", self)
end

local DigitalAction = TypedAction("DigitalAction", openvr_c.InputDigitalActionData_t)
function DigitalAction:_init()
  self.state, self.down = "up", false
end
function DigitalAction:_update()
  self:_check_handle()
  openvr_c.GetDigitalActionData(input_ptr, self.handle[0], self.data, self.datasize)
  if self.data.bChanged then
    local state = (self.data.bState and "down") or "up"
    self.state = state
    self.down = self.data.bState
    self.evt:emit(state, self)
    self.evt:emit("change", self)
  end
end

local AnalogAction = TypedAction("AnalogAction", openvr_c.InputAnalogActionData_t)
function AnalogAction:_init()
  self.state = math.Vector(0, 0, 0)
  self.delta_state = math.Vector(0, 0, 0)
end
function AnalogAction:_update()
  self:_check_handle()
  openvr_c.GetAnalogActionData(input_ptr, self.handle[0], self.data, self.datasize)
  self.state:set(self.data.x, self.data.y, self.data.z)
  self.delta_state:set(self.data.deltaX, self.data.deltaY, self.data.deltaZ)
  self.evt:emit("change", self.data)
end

local action_constructors = {
  boolean = DigitalAction,
  vector1 = AnalogAction,
  vector2 = AnalogAction,
  vector3 = AnalogAction,
  pose = PoseAction
}

local ActionSet = class("ActionSet")
function ActionSet:init(info)
  self._actions = {}
  self._name = info.name
  self._path = "/actions/" .. self._name
  self._usage = info.usage or "leftright"
  self._description = resolve_description(info.description or info.name) 
  for action_name, action_info in pairs(info.actions) do
    if action_name:sub(1,1) == "_" then
      truss.error("action names cannot start with underscore")
    end
    if self[action_name] then
      truss.error("Invalid action name: " .. action_name .. " is already used.")
    end
    local con = action_constructors[action_info.kind]
    if not con then 
      truss.error("No action kind " .. tostring(action_info.kind))
    end
    self._actions[action_name] = con(self._path, action_name, action_info)
    self[action_name] = self._actions[action_name]
  end
end

function ActionSet:_resolve_handles()
  self._handle = self._handle or terralib.new(openvr_c.VRActionSetHandle_t[1])
  openvr.GetActionSetHandle(input_ptr, self._path, self._handle)
  for _, action in pairs(self._actions) do
    action:_resolve_handle()
  end
end

function ActionSet:_update()
  for _, action in pairs(self._actions) do
    action:_update()
  end
end

function ActionSet:_add_to_manifest(manifest)
  table.insert(manifest.action_sets, {
    name = self._path,
    usage = self._usage
  })
  add_description_to_manifest(self._path, self._description, manifest)
  for _, action in pairs(self._actions) do
    action:_add_to_manifest(manifest)
  end
end

m.ActionSet = ActionSet

function m.init()
  local addonfuncs = truss.addons.openvr.functions
  local addonptr   = truss.addons.openvr.pointer

  -- TODO: cast this for actual type checking?
  input_ptr = addonfuncs.truss_openvr_get_input(addonptr)

  m._active_sets = {}
  m._active_set_arr = terralib.new(openvr_c.VRActiveActionSet_t[MAX_ACTIVE_SETS])
  m._num_active = 0

  m._temp_input_handle = terralib.new(openvr_c.VRInputValueHandle_t[1]) 
end

function m.create_default_manifest()
  return require("./default_action_manifest.lua")
end

local INPUT_TYPES = {
  left = 'hand/left', right = 'hand/right', gamepad = 'gamepad', head = 'head'
}
function m._get_input_handle(input_type)
  if not input_type then return const.k_ulInvalidInputValueHandle end
  local path = '/user/' .. (INPUT_TYPES[input_type] or input_type)
  openvr_c.GetInputSourceHandle(input_ptr, path, m._temp_input_handle)
  return m._temp_input_handle[0]
end

function m._stage_active()
  if not self._active_sets_changed then return end
  m._num_active = 0
  m._active_sets = {}
  for setname, set in pairs(m._action_sets) do
    if set.active then
      m._active_sets[set_name] = set
      local active_set = m._active_set_arr[m._num_active]
      active_set.ulActionSet = set.handle[0]
      active_set.ulRestrictedToDevice = m._get_input_handle(set.target_device)
      if set.secondary_action_set then
        local h = m._action_sets[set.secondary_action_set].handle[0]
        active_set.ulSecondaryActionSet = h
      else
        active_set.ulSecondaryActionSet = const.k_ulInvalidActionSetHandle
      end
      m._num_active = m._num_active + 1
    end
  end
  self._active_sets_changed = false
  return m._num_active
end

function m._update()
  local n_active = m._stage_active()
  if n_active == 0 then return end -- would openvr be OK with zero active?
  openvr_c.UpdateActionState(input_ptr, 
                             m._active_set_arr, 
                             terralib.sizeof(openvr_c.VRActiveActionSet_t), 
                             n_active)
  for _, set in pairs(m._active_sets) do
    set:_update()
  end
end

function m._write_manifest(manifest)
  if not truss.absolute_data_path then
    truss.error("Installing a manifest requires an absolute data path to be set!")
  end
  local fn = "/openvr_action_manifest.json"
  m.manifest_path = truss.absolute_data_path .. fn
  local manifest_json = require("json"):encode_pretty(manifest)
  truss.save_string("openvr_actions.json", manifest_json)
  return m.manifest_path
end

function m._action_sets_to_manifest(action_sets)
  local manifest = {
    default_bindings = {
      {
        controller_type = "vive_controller",
        binding_url = "vive_controller_bindings.json"
      }
    },
    actions = {}, action_sets = {}, localization = {}, _localization = {}
  }
  for _, aset in pairs(action_sets) do
    aset:_add_to_manifest(manifest)
  end
  for language_tag, translations in pairs(manifest._localization) do
    translations.language_tag = language_tag
    table.insert(manifest.localization, translations)
  end
  local function name_order(a, b) return a.name < b.name end
  table.sort(manifest.actions, name_order)
  table.sort(manifest.action_sets, name_order)
  manifest._localization = nil
  return manifest
end

function m.change_active_sets(sets_or_names)
  for _, set in pairs(self._action_sets) do
    set.active = false
  end
  for _, set_or_name in pairs(sets_or_names) do
    if type(set_or_name) == 'string' then
      self._action_sets[set_or_name].active = true
    else -- assume an actual action set was passed in
      set_or_name.active = true
    end
  end
  self._active_sets_changed = true
end

function m.generate_action_sets(defs)
  local ret = {}
  for set_name, set in pairs(defs) do
    if set._update then -- already an action set
      ret[set_name] = set
    elseif set.actions then
      if not set.name then set.name = set_name end
      ret[set_name] = ActionSet(set)
    else
      ret[set_name] = ActionSet{
        name = set_name,
        description = set_name,
        usage = 'leftright',
        actions = set
      }
    end
  end
  return ret
end

function m.register_action_sets(action_sets)
  if self._action_sets then
    truss.error("Can only register action sets once.")
  end
  action_sets = m.generate_action_sets(action_sets)
  self._action_sets = action_sets
  self.action_sets = action_sets
  local manifest = m._action_sets_to_manifest(action_sets)
  local path = m._write_manifest(manifest)
  openvr_c.SetActionManifestPath(input_ptr, path)
  return action_sets
end

return m