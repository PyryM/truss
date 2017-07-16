local app = require("app/app.t")
local geometry = require("geometry")
local pbr = require("shaders/pbr.t")
local graphics = require("graphics")
local orbitcam = require("gui/orbitcam.t")

function init()
  myapp = app.App{title = "basic example", width = 1280, height = 720,
                  msaa = true, stats = true, clear_color = 0x404080ff}

  myapp.camera:add_component(orbitcam.OrbitControl({min_rad = 1, max_rad = 4}))

  local geo = geometry.box_widget_geo(1.0)
  local mat = pbr.FacetedPBRMaterial({0.2, 0.03, 0.01, 1.0}, {0.001, 0.001, 0.001}, 0.7)
  mymesh = myapp.scene:create_child(graphics.Mesh, "mymesh", geo, mat)
end

function update()
  myapp:update()
end
