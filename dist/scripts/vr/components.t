-- vr/components.t
--
-- vr ecs components

local class = require("class")
local math = require("math")
local pipeline = require("graphics/pipeline.t")
local openvr = require("vr/openvr.t")
local Entity3d = require("ecs/entity.t").Entity3d
local Component = require("ecs/component.t").Component
local m = {}

local EYES = {left = 1, right = 2}

local VRCameraComponent = pipeline.DrawableComponent:extend("VRCameraComponent")
m.VRCameraComponent = VRCameraComponent

function VRCameraComponent:init()
  VRCameraComponent.super.init(self)
  self.mount_name = "vr_camera"
  self.vr_camera_tag = "primary"
  self.view_mats = {math.Matrix4(), math.Matrix4()}
  self.proj_mats = {}
end

function VRCameraComponent:on_preupdate()
  self._entity.matrix:copy(openvr.hmd.pose)
end

function VRCameraComponent:on_update()
  -- use the parent mat because openvr eye poses are given relative to the room
  -- rather than the hmd, and we will be moving our own entity around
  local parent_mat = self._entity.parent.matrix_world
  for i = 1,2 do
    self.view_mats[i]:multiply(parent_mat, openvr.eye_poses[i])
    self.view_mats[i]:invert()
    self.proj_mats[i] = openvr.eye_projections[i]
  end
  self:draw()
end

local VRCameraControl = pipeline.RenderOperation:extend("VRCameraControl")
m.VRCameraControl = VRCameraControl

function VRCameraControl:matches(comp)
  return comp.vr_camera_tag ~= nil
end

function VRCameraControl:draw(comp)
  local idx = EYES[self.stage.globals.eye]
  self.stage.view:set_matrices(comp.view_mats[idx], comp.proj_mats[idx])
end

local VRSystem = class("VRSystem")
m.VRSystem = VRSystem

function VRSystem:init()
  self.mount_name = "vr"
  self.update_priority = 101 -- try to update after normal graphics
end

function VRSystem:set_eye_textures(eye_texes)
  self.eye_texes = eye_texes
end

function VRSystem:update_begin()
  openvr.begin_frame()
end

function VRSystem:update_end()
  openvr.submit_frame(self.eye_texes)
end

-- convenience function to create an entity with the vr camera component
function m.VRCamera(name)
  return Entity3d(name, VRCameraComponent())
end

local VRControllerComponent = Component:extend("VRControllerComponent")
m.VRControllerComponent = VRControllerComponent

function VRControllerComponent:init(trackable)
  VRControllerComponent.super.init(self)
  self.mount_name = "vr_controller"
  self._trackable = trackable
end

local function print_failure(task, msg)
  log.error("Loading failure: " .. msg)
end

function VRControllerComponent:load_geo_to_component(target_comp_name)
  target_comp_name = target_comp_name or "mesh_shader"
  local target = self
  local function on_load(task)
    target._entity[target_comp_name].geo = task.geo
    --target._entity[target_comp_name]:configure()
  end
  self:load_model(on_load, print_failure, false)
end

function VRControllerComponent:load_model(on_load, on_fail, load_textures)
  self._trackable:load_model(on_load, on_fail, load_textures)
end

function VRControllerComponent:on_preupdate()
  self.axes = self._trackable.axes
  self.buttons = self._trackable.buttons
  self._entity.matrix:copy(self._trackable.pose)
end

return m
