-- vr/components.t
--
-- vr ecs components

local class = require("class")
local math = require("math")
local graphics = require("graphics")
local ecs = require("ecs")
local openvr = require("vr/openvr.t")
local m = {}

local EYES = {left = 1, right = 2}

local VRCameraComponent = graphics.RenderComponent:extend("VRCameraComponent")
m.VRCameraComponent = VRCameraComponent

function VRCameraComponent:init()
  VRCameraComponent.super.init(self)
  self.mount_name = "vr_camera"
  self.vr_camera_tag = "primary"
  self.view_mats = {math.Matrix4(), math.Matrix4()}
  self.proj_mats = {}
end

function VRCameraComponent:mount()
  self:add_to_systems({"preupdate"})
  graphics.RenderComponent.mount(self)
end

function VRCameraComponent:preupdate()
  self.ent.matrix:copy(openvr.hmd.pose)
end

function VRCameraComponent:render()
  -- use the parent mat because openvr eye poses are given relative to the room
  -- rather than the hmd, and we will be moving our own entity around
  local parent_mat = self.ent.parent.matrix_world
  for i = 1,2 do
    self.view_mats[i]:multiply(parent_mat, openvr.eye_poses[i])
    self.view_mats[i]:invert()
    self.proj_mats[i] = openvr.eye_projections[i]
  end
  VRCameraComponent.super.render(self)
end

local VRCameraControlOp = graphics.RenderOperation:extend("VRCameraControlOp")
m.VRCameraControlOp = VRCameraControlOp

function VRCameraControlOp:matches(comp)
  return comp.vr_camera_tag ~= nil
end

function VRCameraControlOp:render(context, comp)
  local idx = EYES[context.eye or context.globals.eye or context.name]
  context.view:set_matrices(comp.view_mats[idx], comp.proj_mats[idx])
end

function VRCameraControlOp:multi_render(contexts, comp)
  for idx, ctx in ipairs(contexts) do
    ctx.view:set_matrices(comp.view_mats[idx], comp.proj_mats[idx])
  end
end

local VRBeginFrameSystem = class("VRBeginFrameSystem")
m.VRBeginFrameSystem = VRBeginFrameSystem

function VRBeginFrameSystem:init()
  self.mount_name = "vr_begin"
end

function VRBeginFrameSystem:update()
  openvr.begin_frame()
end

local VRSubmitSystem = class("VRSubmitSystem")
m.VRSubmitSystem = VRSubmitSystem

function VRSubmitSystem:init()
  self.mount_name = "vr_end"
end

function VRSubmitSystem:set_eye_textures(eye_texes)
  self.eye_texes = eye_texes
end

function VRSubmitSystem:update()
  openvr.submit_frame(self.eye_texes)
end

-- convenience function to create an entity with the vr camera component
function m.VRCamera(ecs, name)
  return Entity3d(ecs, name, VRCameraComponent())
end

local VRTrackableComponent = ecs.Component:extend("VRTrackableComponent")
m.VRTrackableComponent = VRTrackableComponent

function VRTrackableComponent:init(trackable)
  VRTrackableComponent.super.init(self)
  self.mount_name = "trackable"
  self._trackable = trackable
end

function VRTrackableComponent:mount()
  VRTrackableComponent.super.mount(self)
  self:add_to_systems({"preupdate"})
  self:wake()
end

local function print_failure(task, msg)
  log.error("Loading failure: " .. msg)
end

function VRTrackableComponent:load_geo_to_component(target_comp_name)
  target_comp_name = target_comp_name or "mesh_shader"
  local ent = self.ent
  local function on_load(task)
    ent[target_comp_name].geo = task.geo
    if ent.configure then ent:configure() end
  end
  self:load_model(on_load, print_failure, false)
end

function VRTrackableComponent:load_model(on_load, on_fail, load_textures)
  self._trackable:load_model(on_load, on_fail, load_textures)
end

function VRTrackableComponent:preupdate()
  self.axes = self._trackable.axes
  self.buttons = self._trackable.buttons
  self.ent.matrix:copy(self._trackable.pose)
end

local VRControllerComponent = VRTrackableComponent:extend("VRControllerComponent")
m.VRControllerComponent = VRControllerComponent

function VRControllerComponent:init(trackable)
  VRControllerComponent.super.init(self, trackable)
  self.mount_name = "vr_controller"
end

function VRControllerComponent:preupdate()
  self.axes = self._trackable.axes
  self.buttons = self._trackable.buttons
  self.ent.matrix:copy(self._trackable.pose)
end

return m
