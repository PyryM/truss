-- new_screencap.t
--
-- example of screen capture

local class = require("class")
local gfx = require("gfx")
local ecs = require("ecs")
local math = require("math")
local graphics = require("graphics")
local geometry = require("geometry")

local flat = require("material/flat.t")

local app = require("app/app.t")
local screencap = require("addons/screencap.t")
local orbitcam = require("graphics/orbitcam.t")

local captex = nil
local live_mat = nil

function init()
  local width, height = 640, 480
  myapp = app.App{title = "screencap example", width = width, height = height,
                  msaa = true, stats = true, clear_color = 0xff00ffff,
                  lowlatency = true, vsync = true}
  myapp.camera:add_component(orbitcam.OrbitControl{
    min_rad = 8, max_rad = 16
  })

  local geo = geometry.cube_geo{
    sx = 10.0, sy = 10.0, sz = 3.0
  }
  live_mat = flat.FlatMaterial{
    texture = gfx.Texture("textures/test_pattern.png")
  }
  local thecube = myapp.scene:create_child(graphics.Mesh, "cube", geo, live_mat)

  screencap.start_capture()
end

local t0 = truss.tic()
function update()
  local newcaptex = screencap.capture_screen()
  if newcaptex then
    print("Frame delta: " .. truss.toc(t0) * 1000.0)
    t0 = truss.tic()
    captex = newcaptex
    live_mat.uniforms.s_texAlbedo:set(newcaptex)
  end
  myapp:update()
end
