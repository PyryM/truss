local VRTrackingApp = require("vr/vrtrackingapp.t").VRTrackingApp
local geometry = require("geometry")
local pbr = require("shaders/pbr.t")
local graphics = require("graphics")
local orbitcam = require("gui/orbitcam.t")
local grid = require("graphics/grid.t")

function init()
  app = VRTrackingApp{title = "vr (tracking only, no hmd)", 
                      width = 1280, height = 720,
                      msaa = true, stats = true, 
                      clear_color = 0x404080ff, lowlatency = true}
  app.camera:add_component(orbitcam.OrbitControl({min_rad = 1, max_rad = 4}))

  local geo = geometry.box_widget_geo{side_length = 1.0}
  local mat = pbr.FacetedPBRMaterial({0.2, 0.03, 0.01, 1.0}, {0.001, 0.001, 0.001}, 0.7)
  box = app.scene:create_child(graphics.Mesh, "box", geo, mat)
  lines = app.scene:create_child(grid.Grid, {thickness = 0.01, 
                                                color = {0.5, 0.2, 0.2}})
  lines.position:set(0.0, -1.0, 0.0)
  lines.quaternion:euler({x = math.pi / 2.0, y = 0.0, z = 0.0})
  lines:update_matrix()
end

function update()
  app:update()
end
