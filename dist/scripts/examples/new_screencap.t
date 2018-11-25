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
local orbitcam = require("gui/orbitcam.t")

local captex = nil
local live_mat = nil

function take_snapshot()
  if not captex then return end
  if not snaptex then
    snaptex = gfx.Texture()
  end
  snaptex:copy(captex)
  snapshot_mat.uniforms.s_texAlbedo:set(snaptex)
end

function init()
  local width, height = 640, 480
  myapp = app.App{title = "screencap example", width = width, height = height,
                  msaa = true, stats = true, clear_color = 0xff00ffff,
                  lowlatency = true, single_threaded = true}
  myapp.camera:add_component(orbitcam.OrbitControl{
    min_rad = 1, max_rad = 4
  })

  local geo = geometry.cube_geo{
    sx = 10.0, sy = 10.0, sz = 3.0
  }
  live_mat = flat.FlatMaterial{
    texture = gfx.Texture("textures/test_pattern.png")
  }

  local thecube = myapp.scene:create_child(graphics.Mesh, "cube", geo, live_mat)
  thecube.position:set(-6, 0, 0)
  thecube:update_matrix()

  screencap.start_capture()
end

function update()
  local newcaptex = screencap.capture_screen()
  if newcaptex then
    captex = newcaptex
    live_mat.uniforms.s_texAlbedo:set(newcaptex)
  end
  myapp:update()
  --truss.sleep(14)
end
