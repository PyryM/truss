-- soloud_test
--
-- sound example

local app = require("app/app.t")
local geometry = require("geometry")
local pbr = require("material/pbr.t")
local graphics = require("graphics")
local orbitcam = require("graphics/orbitcam.t")
local grid = require("graphics/grid.t")
local config = require("util/config.t")
local soloud = require('sound/soloud.t')
local clib = require("substrate/clib.t")

local terra test_alloc(): &float
  var x = [&float](clib.std.malloc(sizeof(float)))
  return x
end

function init()
  local xx = test_alloc()
  print(xx)

  myapp = app.App{
    width = 1280, height = 720, 
    msaa = true, stats = false,
    title = "truss", clear_color = 0x000000ff,
  }
  myapp.camera:add_component(orbitcam.OrbitControl{min_rad = 1, max_rad = 4})

  local geo = geometry.box_widget_geo{side_length = 1.0}
  local mat = pbr.FacetedPBRMaterial{
    diffuse = {0.2, 0.03, 0.01, 1.0}, 
    tint = {0.001, 0.001, 0.001}, 
    roughness = 0.7
  }
  mymesh = myapp.scene:create_child(graphics.Mesh, "mymesh", geo, mat)
  mygrid = myapp.scene:create_child(grid.Grid, "grid", 
    {thickness = 0.01, color = {0.5, 0.2, 0.2}}
  )
  mygrid.position:set(0.0, -1.0, 0.0)
  mygrid.quaternion:euler({x = math.pi / 2.0, y = 0.0, z = 0.0})
  mygrid:update_matrix()

  soloud.init()
  --bgmusic = soloud.loadWav("sounds/tetsno.ogg")
  bgmusic = soloud.WavStream("sounds/ambience.ogg")
  bgmusic:set_looping(true)
  bgmusic:play():set_volume(0.2)

  hitsound = soloud.Wav("sounds/bell.wav")

  local speech = soloud.Speech()
  speech:set_params{
    frequency = 1800, 
    speed = 10.0, 
    declination = 1.0,
    waveform = "warble"
  }
  speech:set_volume(3.0)
  local filter = soloud.EchoFilter{delay = 0.1, decay = 0.6}
  speech:set_filter(filter)
  speech:say("so now I am going to say the words that confuse the internet: " ..
             "laurel yanny laurel yanny laurel yanny")

  myapp.ECS.systems.input:on("keydown", myapp, function(self, evtname, evt)
    hitsound:play(0.6):set_volume(math.random()*0.5 + 0.5)
    speech:say("you pressed " .. evt.keyname)
  end)
end

function update()
  --local volume = math.random() * 4 + 1.0
  --if math.random() < 0.10 and hitsound then hitsound:play(volume) end
  myapp:update()
end