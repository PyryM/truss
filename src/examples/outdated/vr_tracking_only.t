local VRTrackingApp = require("vr/vrtrackingapp.t").VRTrackingApp
local geometry = require("geometry")
local pbr = require("material/pbr.t")
local graphics = require("graphics")
local orbitcam = require("graphics/orbitcam.t")
local grid = require("graphics/grid.t")

function init()
  app = VRTrackingApp{title = "vr (tracking only, no hmd)", 
                      width = 1280, height = 720,
                      msaa = true, stats = true, 
                      clear_color = 0x404080ff, lowlatency = true}
  app.camera:add_component(orbitcam.OrbitControl({min_rad = 1, max_rad = 4}))
  app:on("trackable_connected", function(_, evtname, evt)
    print("Got trackable!")
    if evt.trackable.device_class_name == "Controller" then
      print("Got controller!") 
      evt.trackable:on("button", function(_, evtname, evt)
        print(evt.name, evt.state, evt.axis)
      end)
    end
  end)

  local geo = geometry.box_widget_geo{side_length = 1.0}
  local mat = pbr.FacetedPBRMaterial({0.2, 0.03, 0.01, 1.0}, {0.001, 0.001, 0.001}, 0.7)
  box = app.scene:create_child(graphics.Mesh, "box", geo, mat)
  grid = app.scene:create_child(grid.Grid, "grid", {
    thickness = 0.01, 
    color = {0.5, 0.2, 0.2}
  })
  grid.quaternion:euler({x = math.pi / 2.0, y = 0.0, z = 0.0})
  grid:update_matrix()
end

function update()
  app:update()
end
