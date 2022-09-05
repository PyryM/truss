local app = require("app/app.t")
local geometry = require("geometry")
local pbr = require("material/pbr.t")
local graphics = require("graphics")
local orbitcam = require("graphics/orbitcam.t")
local grid = require("graphics/grid.t")
local gfx = require("gfx")
local sdl = require("addon/sdl.t")

function gamepad_added(app, evtname, evt)
  print("Enabling controller " .. evt.flags)
  local info = sdl.enable_controller(evt.flags)
  if info then 
    print("Enable! " .. info.name) 
  else
    print("Unable to enable.")
  end
end

function gamepad_axis(app, evtname, evt)
  print("[" .. evt.id .. "] Axis: " .. (evt.axis_name or evt.axis) 
        .. " => " .. evt.value)
end

function gamepad_button(app, evtname, evt)
  print("[" .. evt.id .. "] Button: " .. (evt.button_name or evt.button)
        .. " => " .. tostring(evt.down))
end

function init()
  myapp = app.App{title = "gamepad example", width = 1280, height = 720,
                  msaa = true, stats = true, clear_color = 0x404080ff}

  myapp.camera:add_component(orbitcam.OrbitControl({min_rad = 1, max_rad = 4}))

  local tex = gfx.Texture("textures/cone.png")
  local geo = geometry.uvsphere_geo()
  local mat = pbr.FacetedPBRMaterial{diffuse = {1.0, 1.0, 1.0, 1.0}, 
                                        tint = {0.001, 0.001, 0.001}, 
                                        roughness = 0.7,
                                        texture = tex}
  mymesh = myapp.scene:create_child(graphics.Mesh, "mymesh", geo, mat)
  mygrid = myapp.scene:create_child(grid.Grid, "grid", {thickness = 0.01, 
                                                color = {0.5, 0.2, 0.2}})
  mygrid.position:set(0.0, -1.0, 0.0)
  mygrid.quaternion:euler({x = math.pi / 2.0, y = 0.0, z = 0.0})
  mygrid:update_matrix()

  local input = myapp.ECS.systems.input
  input:on("gamepad_added", myapp, gamepad_added)
  input:on("gamepad_buttondown", myapp, gamepad_button)
  input:on("gamepad_buttonup", myapp, gamepad_button)
  --input:on("gamepad_axis", myapp, gamepad_axis)
end

function update()
  myapp:update()
end
