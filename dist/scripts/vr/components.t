-- vr/components.t
--
-- vr ecs components

local class = require("class")
local math = require("math")
local graphics = require("graphics")
local ecs = require("ecs")
local openvr = require("vr/openvr.t")
local stateutils = require("utils/state.t")
local m = {}

local EYES = {left = 1, right = 2}

local VRCameraComponent = graphics.RenderComponent:extend("VRCameraComponent")
m.VRCameraComponent = VRCameraComponent

function VRCameraComponent:init(options)
  options = options or {}
  VRCameraComponent.super.init(self)
  self.mount_name = "vr_camera"
  self.vr_camera_tag = options.tag or "vr_primary"
  self.view_mats = {math.Matrix4(), math.Matrix4()}
  self.proj_mats = {}
end

function VRCameraComponent:mount()
  self:add_to_systems({"preupdate"})
  graphics.RenderComponent.mount(self)
end

function VRCameraComponent:preupdate()
  if openvr.hmd then self.ent.matrix:copy(openvr.hmd.pose) end
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

local VRCameraControlOp = graphics.MultiRenderOperation:extend("VRCameraControlOp")
m.VRCameraControlOp = VRCameraControlOp

function VRCameraControlOp:init(tag)
  self._tag = tag or "vr_primary"
end

function VRCameraControlOp:matches(comp)
  return comp.vr_camera_tag == self._tag
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
  self.mount_name = "vr_submit"
end

function VRSubmitSystem:set_eye_textures(eye_texes)
  self.eye_texes = eye_texes
end

function VRSubmitSystem:update()
  openvr.submit_frame(self.eye_texes)
end

-- convenience function to create an entity with the vr camera component
function m.VRCamera(_ecs, name)
  return ecs.Entity3d(_ecs, name, VRCameraComponent())
end

local VRTrackableComponent = ecs.Component:extend("VRTrackableComponent")
m.VRTrackableComponent = VRTrackableComponent

function VRTrackableComponent:init(trackable)
  VRTrackableComponent.super.init(self)
  self.mount_name = "vr_trackable"
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
  target_comp_name = target_comp_name or "mesh"
  local ent = self.ent
  local function on_load(task)
    ent[target_comp_name]:set_geometry(task.geo)
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
  self._prev_axes = {}
  self._prev_buttons = {}
end

function VRControllerComponent:create_parts()
  local raw_parts = self._trackable:get_parts()
  self.parts = {}
  self._dynamic_parts = {}
  for partname, part in pairs(raw_parts) do
    self.parts[partname] = self.ent:create_child(ecs.Entity3d, partname)
    self._dynamic_parts[partname] = self.parts[partname]
  end
  return self.parts
end

function VRControllerComponent:create_mesh_parts(default_geo, default_mat)
  local part_entities = self:create_parts()
  for pname, pent in pairs(part_entities) do
    if self._trackable.parts[pname].model_name then --not all parts have models
      pent:add_component(graphics.MeshRenderComponent(default_geo, default_mat))
      self:load_part_geo_to_component(pname, "mesh")
    end
  end
end

function VRControllerComponent:_update_parts()
  for partname, part_entity in pairs(self._dynamic_parts) do
    local p_src = self._trackable.parts[partname]
    if p_src then
      part_entity.matrix:copy(p_src.pose)
      if part_entity.mesh then 
        part_entity.mesh.visible = p_src.visible 
      end
      if p_src.static then
        self._dynamic_parts[partname] = nil
      end
    end
  end
end

function VRControllerComponent:load_part_geo_to_component(partname, target_comp_name)
  target_comp_name = target_comp_name or "mesh"
  local ent = self.parts[partname]
  local function on_load(task)
    ent[target_comp_name]:set_geometry(task.geo)
  end
  self:load_part_model(partname, on_load, print_failure, false)
end

function VRControllerComponent:load_part_model(partname, on_load, on_fail, load_textures)
  self._trackable:load_part_model(partname, on_load, on_fail, load_textures)
end

function VRControllerComponent:enable_events(enabled)
  self._emit_events = (enabled == nil) or enabled
end

function VRControllerComponent:preupdate()
  self.axes = self._trackable.axes
  self.buttons = self._trackable.buttons
  self.ent.matrix:copy(self._trackable.pose)
  if self.parts and self._trackable.parts then
    self:_update_parts()
  end
  if self._emit_events then
    -- compare and copy old state
    for k, v in pairs(self.axes) do
      local px, py = self._prev_axes[k].x or 0, self._prev_axes[k].y or 0
      if px ~= v.x or py ~= v.y then
        self.ent:emit("axis", 
          {axis = k, prev_x = px, prev_y = py, x = v.x, y = v.y, 
           component = self})
      end
      self._prev_axes[k].x = v.x
      self._prev_axes[k].y = v.y
    end
    for k, v in pairs(self.buttons) do
      local pv = self._prev_buttons[k] or 0
      if pv ~= v then
        self.ent:emit("button", {button = k, prev = pv, value = v, 
                                            component = self})
      end
      self._prev_buttons[k] = v
    end
  end
end

return m
