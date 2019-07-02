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
  openvr.init{mode = "other"}
  self.trackables = {}
  if options.create_trackables ~= false then
    openvr.on("trackable_connected", function(trackable)
      self:add_trackable(trackable)
    end)
  end
  self._evt = ecs.EventEmitter()
end

function VRTrackingApp:on(...)
  return self._evt:on(...)
end

function VRTrackingApp:add_trackable(trackable)
  local geometry = require("geometry")
  local pbr = require("material/pbr.t")
  local geo = geometry.icosphere_geo{radius = 0.1, detail = 3}
  local mat = pbr.FacetedPBRMaterial{
    diffuse = {0.03,0.03,0.03,1.0},
    tint = {0.001, 0.001, 0.001}, 
    roughness = 0.7
  }
  
  local trackable_entity = self.scene:create_child(ecs.Entity3d, "trackable")
  trackable_entity:add_component(vrcomps.TrackableComponent(trackable))
  trackable_entity.trackable:create_mesh(geo, mat)
  table.insert(self.trackables, trackable_entity)

  self._evt:emit("trackable_connected", {
    trackable = trackable,
    entity = trackable_entity,
    idx = #self.trackables
  })
end

function VRTrackingApp:update()
  openvr.begin_frame()
  VRTrackingApp.super.update(self)
end

return m