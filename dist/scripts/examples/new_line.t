local app = require("app/app.t")
local gfx = require("gfx")
local ecs = require("ecs")
local math = require("math")
local graphics = require("graphics")

local grid = require("graphics/grid.t")
local orbitcam = require("gui/orbitcam.t")

function init()
  -- app/ecs setup
  myapp = app.App{title = "line example", width = 1280, height = 720,
                  msaa = true, stats = true, clear_color = 0x404080ff,
                  lowlatency = true}
  myapp.camera:add_component(orbitcam.OrbitControl({min_rad = 2, max_rad = 5}))

  -- scene setup
  local mygrid = myapp.scene:create_child(grid.Grid, 'grid', {
    thickness = 0.01, 
    color = {0.5, 0.2, 0.2, 1.0}
  })
  mygrid.position:set(0.0, -1.0, 0.0)
  mygrid.quaternion:euler({x = math.pi / 2.0, y = 0.0, z = 0.0})
  mygrid:update_matrix()

  local linething = create_line(myapp.scene)
  linething.scale:set(0.2, 0.2, 0.2)
  linething:update_matrix()
end

function update()
  myapp:update()
end

local Twiddler = ecs.Component:extend("Twiddler")
function Twiddler:init(idata, ldata)
  self.idata, self.ldata = idata, ldata
  self.mount_name = "line_twiddler"
end

function Twiddler:mount()
  self:add_to_systems({"update"})
  self:wake()
end

local function hfield(htime, x, y, z)
  --local mult = 1.0 + math.tanh((math.tan(x + y * 3.0 + time)*0.5)*0.1)
  --mult = math.max(-5.0, math.min(5.0, mult))
  local mult = math.sin(y*1.1 + htime)*0.1*math.cos(x + htime) + math.cos(z + htime)*0.1
  mult = 1.0 + (mult * mult)*10
  return x*mult, y*mult, z*mult
end

function Twiddler:update()
  --print("update?")
  self.htime = (self.htime or 0.0) + 1.0/60.0
  local htime = self.htime
  local idata = self.idata
  for i,v in ipairs(self.ldata) do
    local v2 = idata[i]
    v[1], v[2], v[3] = hfield(htime, v2[1], v2[2], v2[3])
  end
  self.ent.line:set_points({self.ldata})
end

-- actually creates the line structure
function create_line(parent)
  local npoints = 5000
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

  local linetex = gfx.Texture("textures/terrible_dashed_line.png")
  local ret = parent:create_child(graphics.Line, "line", {
    maxpoints = npoints, dynamic = true, points = {linedata},
    color = {0.8,0.8,0.8,0.75}, thickness = 0.05, 
    texture = linetex, alpha_test = true, u_mult = 360.0
  })
  ret:add_component(Twiddler(initial_data, linedata))

  return ret
end
