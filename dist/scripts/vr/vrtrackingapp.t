-- vr/vrtrackingapp.t
--
-- convenience app for creating a tracker-only (no hmd) app

local class = require("class")
local ecs = require("ecs")
local graphics = require("graphics")
local openvr = require("vr/openvr.t")
local app = require("app/app.t")
local vrcomps = require("vr/components.t")

local m = {}
local VRTrackingApp = app.App:extend("VRTrackingApp")
m.VRTrackingApp = VRTrackingApp

function VRTrackingApp:init(options)
  VRTrackingApp.super.init(self, options)
  openvr.init{mode = "other", use_linux_hacks = options.use_linux_hacks}
  self.controllers = {}
  openvr.on("trackable_connected", function(trackable)
    self:add_controller(trackable)
  end)
end

function VRTrackingApp:add_controller(trackable)
  if trackable.device_class_name ~= "Controller" then
    return
  end

  local geometry = require("geometry")
  local pbr = require("shaders/pbr.t")
  local geo = geometry.icosphere_geo{radius = 0.1, detail = 1}
  local mat = pbr.FacetedPBRMaterial({0.03,0.03,0.03,1.0},
                                     {0.001, 0.001, 0.001}, 0.7)
  
  local controller = self.ECS.scene:create_child(ecs.Entity3d, 
                                                 "controller")
  controller:add_component(vrcomps.VRControllerComponent(trackable))
  controller.vr_controller:create_mesh_parts(geo, mat)
  table.insert(self.controllers, controller)
end

function VRTrackingApp:update()
  openvr.begin_frame()
  VRTrackingApp.super.update(self)
end

return m