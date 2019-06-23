-- vr/components.t
--
-- vr ecs components

local class = require("class")
local math = require("math")
local gfx = require("gfx")
local graphics = require("graphics")
local ecs = require("ecs")
local openvr = require("vr/openvr.t")
local stateutils = require("utils/state.t")
local m = {}

local EYES = {left = 1, right = 2}

local EyeComponent = graphics.CameraComponent:extend("EyeComponent")
m.EyeComponent = EyeComponent

-- A Camera for a single eye
function EyeComponent:init(options)
  if (not options) or (not options.eye) then
    truss.error("EyeComponent: options.eye must be specified")
  end
  EyeComponent.super.init(self, options)
  self.eye = options.eye
  self.tags = gfx.tagset{is_camera = true, camera_tag = self.eye}
end

function EyeComponent:mount()
  EyeComponent.super.mount(self)
  self:add_to_systems({"update"})
  self:wake()
end

function EyeComponent:update()
  local eye_idx = EYES[self.eye]
  self.ent.matrix:copy(openvr.eye_offsets[eye_idx])
  self.proj_mat = openvr.eye_projections[eye_idx]
end

local HMDComponent = ecs.UpdateComponent:extend("HMDComponent")
function HMDComponent:update()
  if openvr.hmd then self.ent.matrix:copy(openvr.hmd.pose) end
end

-- Typical VR Root setup (HMD + two eyes)
function m.RoomRoot(_ecs, name)
  local parent = ecs.Entity3d(_ecs, name)

  local hmd = parent:create_child(ecs.Entity3d, "hmd", HMDComponent())
  local left_eye = hmd:create_child(ecs.Entity3d, "left_eye", EyeComponent{eye = "left"})
  local right_eye = hmd:create_child(ecs.Entity3d, "right_eye", EyeComponent{eye = "right"})

  return parent
end

local TrackableComponent = ecs.Component:extend("TrackableComponent")
m.TrackableComponent = TrackableComponent

function TrackableComponent:init(trackable)
  TrackableComponent.super.init(self)
  self.mount_name = "trackable"
  self._trackable = trackable
end

function TrackableComponent:mount()
  TrackableComponent.super.mount(self)
  self:add_to_systems({"update"})
  self:wake()
end

local function print_failure(task, msg)
  log.error("Loading failure: " .. msg)
end

function TrackableComponent:load_geo_to_component(target_comp_name)
  target_comp_name = target_comp_name or "mesh"
  local ent = self.ent
  local function on_load(task)
    ent[target_comp_name]:set_geometry(task.geo)
  end
  self:load_model(on_load, print_failure, false)
end

function TrackableComponent:load_model(on_load, on_fail, load_textures)
  self._trackable:load_model(on_load, on_fail, load_textures)
end

function TrackableComponent:create_mesh(default_geo, default_mat, create_parts)
  if create_parts and self.create_mesh_parts then
    return self:create_mesh_parts(default_geo, default_mat)
  end

  if not self.ent.mesh then
    self.ent:add_component(graphics.MeshComponent(default_geo, default_mat))
  end

  self:load_geo_to_component("mesh")
end

function TrackableComponent:update()
  self.axes = self._trackable.axes
  self.buttons = self._trackable.buttons
  self.ent.matrix:copy(self._trackable.pose)
end

function TrackableComponent:on(...)
  self._trackable:on(...)
end

local ControllerComponent = TrackableComponent:extend("ControllerComponent")
m.ControllerComponent = ControllerComponent

function ControllerComponent:init(trackable)
  ControllerComponent.super.init(self, trackable)
  self.mount_name = "controller"
  self._prev_axes = {}
  self._prev_buttons = {}
end

function ControllerComponent:create_parts()
  local raw_parts = self._trackable:get_parts()
  self.parts = {}
  self._dynamic_parts = {}
  for partname, part in pairs(raw_parts) do
    self.parts[partname] = self.ent:create_child(ecs.Entity3d, partname)
    self._dynamic_parts[partname] = self.parts[partname]
  end
  return self.parts
end

function ControllerComponent:create_mesh_parts(default_geo, default_mat)
  local part_entities = self:create_parts()
  for pname, pent in pairs(part_entities) do
    if self._trackable.parts[pname].model_name then --not all parts have models
      pent:add_component(graphics.MeshComponent(default_geo, default_mat))
      self:load_part_geo_to_component(pname, "mesh")
    end
  end
end

function ControllerComponent:_update_parts()
  for partname, part_entity in pairs(self._dynamic_parts) do
    local p_src = self._trackable.parts[partname]
    if p_src then
      part_entity.matrix:copy(p_src.pose)
      if part_entity.mesh then 
        part_entity.visible = p_src.visible 
      end
      if p_src.static then
        self._dynamic_parts[partname] = nil
      end
    end
  end
end

function ControllerComponent:load_part_geo_to_component(partname, target_comp_name)
  target_comp_name = target_comp_name or "mesh"
  local ent = self.parts[partname]
  local function on_load(task)
    ent[target_comp_name]:set_geometry(task.geo)
  end
  self:load_part_model(partname, on_load, print_failure, false)
end

function ControllerComponent:load_part_model(partname, on_load, on_fail, load_textures)
  self._trackable:load_part_model(partname, on_load, on_fail, load_textures)
end

function ControllerComponent:update()
  self.axes = self._trackable.axes
  self.buttons = self._trackable.buttons
  self.ent.matrix:copy(self._trackable.pose)
  if self.parts and self._trackable.parts then
    self:_update_parts()
  end
end

m.Bounds = function(_ecs, name, options)
  options = options or {}
  local material = options.material
  if not material then
    local color = options.color or {0.8, 0.8, 0.3, 1.0}
    material = require("material/flat.t").FlatMaterial{color = color}
  end
  print(openvr.play_area.x_size, openvr.play_area.z_size)
  local geo = require("geometry").rectangle_frame_geo{
    width = openvr.play_area.x_size,
    height = openvr.play_area.z_size,
    thickness = options.thickness or 0.1
  }
  local bounds = graphics.Mesh(_ecs, name, geo, material)
  bounds.quaternion:euler{x = -math.pi/2, y = 0, z = 0}
  bounds.position:set(0, options.hover or 0.02, 0)
  bounds:update_matrix()
  return bounds
end

return m
