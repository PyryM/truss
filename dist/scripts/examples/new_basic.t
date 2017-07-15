local app = require("app/app.t")
local icosphere = require("geometry/icosphere.t")
local pbr = require("shaders/pbr.t")
local graphics = require("graphics")

function setup_scene()
  -- move camera someplace useful
  myapp.camera.position:set(0.0, 0.0, 5.0)
  myapp.camera:update_matrix()

  local geo = icosphere.icosphere_geo(1.0, 2, "ico")
  local mat = pbr.FacetedPBRMaterial({0.2, 0.03, 0.01, 1.0},
                                     {0.001, 0.001, 0.001}, 0.7)

  mysphere = myapp.scene:create_child(graphics.Mesh, "SphereMcSphereFace",
                                      geo, mat)
end

function init()
  myapp = app.App{title = "blah", width = 1280, height = 720,
                  msaa = true, stats = false, clear_color = 0x404080ff}
  setup_scene()
end

function update()
  myapp:update()
end
