local app = require("app/app.t")
local geometry = require("geometry")
local pbr = require("shaders/pbr.t")
local graphics = require("graphics")
local orbitcam = require("gui/orbitcam.t")

function init()
  myapp = app.App{title = "basic example", width = 1280, height = 720,
                  msaa = true, stats = true, clear_color = 0x404080ff}

  myapp.camera:add_component(orbitcam.OrbitControl({min_rad = 1, max_rad = 4}))

  local geo = geometry.icosphere_geo(1.0, 1, "ico")
  local mat = pbr.FacetedPBRMaterial({0.2, 0.03, 0.01, 1.0}, {0.001, 0.001, 0.001}, 0.7)
  mysphere = myapp.scene:create_child(graphics.Mesh, "Sphere", geo, mat)
end

function update()
  myapp:update()
end
