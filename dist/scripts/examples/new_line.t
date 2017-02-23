local class = require("class")
local gfx = require("gfx")
local ecs = require("ecs/ecs.t")
local component = require("ecs/component.t")
local entity = require("ecs/entity.t")
local sdl_input = require("ecs/sdl_input.t")
local sdl = require("addons/sdl.t")
local math = require("math")
local pipeline = require("graphics/pipeline.t")
local framestats = require("graphics/framestats.t")
local line = require("graphics/line.t")

local camera = require("graphics/camera.t")
local orbitcam = require("gui/orbitcam.t")

width = 800
height = 600

function init()
  -- basic init
  sdl.create_window(width, height, 'keyboard events')
  gfx.init_gfx({msaa = true, debugtext = true, window = sdl})

  -- create ecs
  ECS = ecs.ECS()
  ECS:add_system(sdl_input.SDLInputSystem())
  local p = ECS:add_system(pipeline.Pipeline({verbose = true}))
  p:add_stage(pipeline.Stage({
    name = "solid_geo",
    clear = {color = 0x303050ff, depth = 1.0},
  }, {pipeline.GenericRenderOp(), camera.CameraControlOp()}))

  ECS:add_system(framestats.DebugTextStats())

  ECS.scene:add_component(sdl_input.SDLInputComponent())
  ECS.scene:on("keydown", function(entity, evt)
    local keyname = ffi.string(evt.keycode)
    if keyname == "F12" then
      print("Saving screenshot!")
      gfx.save_screenshot("screenshot.png")
    end
  end)

  local cam = camera.Camera({fov = 65, aspect = width/height})
  cam:add_component(sdl_input.SDLInputComponent())
  cam:add_component(orbitcam.OrbitControl({min_rad = 1.0, max_rad = 15.0}))
  ECS.scene:add(cam)

  -- create the scene
  lineobj = create_line()
  ECS.scene:add(lineobj)
end

function update()
  -- update ecs
  ECS:update()
end

local Twiddler = component.Component:extend("Twidder")
function Twiddler:init(idata, ldata)
  self.idata, self.ldata = idata, ldata
  self.mount_name = "twiddler"
end

local htime = 0.0
local function hfield(x, y, z)
  --local mult = 1.0 + math.tanh((math.tan(x + y * 3.0 + time)*0.5)*0.1)
  --mult = math.max(-5.0, math.min(5.0, mult))
  local mult = math.sin(y*1.1 + htime)*0.1*math.cos(x + htime) + math.cos(z + htime)*0.1
  mult = 1.0 + (mult * mult)*10
  return x*mult, y*mult, z*mult
end

function Twiddler:on_update()
  htime = htime + 1.0/60.0

  local linecomp = self._entity.line_shader
  if not linecomp.dynamic then return end
  local idata = self.idata
  for i,v in ipairs(self.ldata) do
    local v2 = idata[i]
    v[1], v[2], v[3] = hfield(v2[1], v2[2], v2[3])
  end

  linecomp:set_points({self.ldata})
end


-- actually creates the cube structure
function create_line()
  local npoints = 5000

  local linecomp = line.LineShaderComponent({maxpoints = npoints, dynamic = true})
  local f = 50 * math.pi * 2.0

  local initial_data = {}
  local linedata = {}
  local curtheta = 0.1
  for i = 1,npoints do
    local z = 10.0 * (i/npoints - 0.5)
    local currad = 5.0 - math.abs(z)
    --math.sqrt(25.0 - z*z)
    local thetaStep = math.min(0.1, 2.0 / currad)
    curtheta = curtheta + thetaStep
    local x = math.cos(curtheta) * currad
    local y = math.sin(curtheta) * currad
    linedata[i] = {x,z,y}
    initial_data[i] = {x,z,y}
  end

  linecomp:set_points({linedata})
  linecomp.mat.uniforms.u_color:set(math.Vector(0.8,0.8,0.8))
  linecomp.mat.uniforms.u_thickness:set(math.Vector(0.1))

  local ret = entity.Entity3d("line")
  ret:add_component(linecomp)
  ret:add_component(Twiddler(initial_data, linedata))

  -- create a grid
  -- local thegrid = grid.Grid({numlines = 0, numcircles = 20, spacing = 1.0})
  -- thegrid.position:set(0.0, -5.0, 0.0)
  -- thegrid.quaternion:fromEuler({x= -math.pi / 2.0, y=0, z=0}, 'ZYX')
  -- thegrid:updateMatrix()
  -- rootobj:add(thegrid)

  return ret
end
