local app = require("app/app.t")
local geometry = require("geometry")
local pbr = require("shaders/pbr.t")
local graphics = require("graphics")
local orbitcam = require("gui/orbitcam.t")
local grid = require("graphics/grid.t")

function init()
  myapp = app.App{title = "basic example", width = 1280, height = 720,
                  msaa = true, stats = true, clear_color = 0x404080ff}

  myapp.camera:add_component(orbitcam.OrbitControl({min_rad = 1, max_rad = 4}))

  local geo = geometry.box_widget_geo(1.0)
  local mat = pbr.FacetedPBRMaterial({0.2, 0.03, 0.01, 1.0}, {0.001, 0.001, 0.001}, 0.7)
  mymesh = myapp.scene:create_child(graphics.Mesh, "mymesh", geo, mat)
  mygrid = myapp.scene:create_child(grid.Grid, {thickness = 0.01, 
                                                color = {0.5, 0.2, 0.2}})
  mygrid.position:set(0.0, -1.0, 0.0)
  mygrid.quaternion:euler({x = math.pi / 2.0, y = 0.0, z = 0.0})
  mygrid:update_matrix()
end

function update()
  myapp:update()
end
