local app = require("app/app.t")
local geometry = require("geometry")
local pbr = require("material/pbr.t")
local flat = require("material/flat.t")
local graphics = require("graphics")
local orbitcam = require("gui/orbitcam.t")
local grid = require("graphics/grid.t")
local config = require("utils/config.t")
local gfx = require("gfx")
local simplex = require("procgen/simplex.t")
local ecs = require("ecs")
local math = require("math")

local Rotator = ecs.UpdateComponent:extend("Rotator")
function Rotator:init(rate)
  Rotator.super.init(self)
  self.t = 0.0
  self.rate = rate or (1.0 / 60.0)
end

function Rotator:update()
  self.t = self.t + self.rate
  self.ent.quaternion:euler({x = 0, y = self.t, z = 0}, 'ZYX')
  self.ent:update_matrix()
end

function init()
  local cfg = config.Config{
      orgname = "truss", 
      appname = "textures_example", 
      use_global_save_dir = false,
      defaults = {
        width = 1280, height = 720, msaa = true, stats = true
      }
    }:load()
  cfg.title = "textures example"
  cfg.clear_color = 0x404080ff 
  cfg:save()

  myapp = app.App(cfg)
  myapp.camera:add_component(orbitcam.OrbitControl{min_rad = 1, max_rad = 4})

  local geo = geometry.cube_geo{sx = 0.5, sy = 0.5, sz = 0.5}
  
  -- texture from file
  local mat = flat.FlatMaterial{
    diffuse = {1.0, 0.0, 1.0, 1.0}, 
    tint = {0.001, 0.001, 0.001},
    roughness = 0.7,
    texture = gfx.Texture("textures/test_pattern.png")
  }
  local cube1 = myapp.scene:create_child(graphics.Mesh, "cube1", geo, mat)
  cube1:add_component(Rotator(1.0 / 60.0))
  cube1.position:set(0.0, 0.0, -1.0)
  cube1:update_matrix()

  -- 2d texture from data (simplex noise)
  local noisetex = gfx.Texture2d{width = 64, height = 64, format = gfx.TEX_BGRA8}
  local p = 0
  for r = 0, 63 do
    for c = 0, 63 do
      local cr = math.floor((simplex.simplex_2d(r / 16, c / 16) + 1) * 127.5)
      local cg = math.floor((simplex.simplex_2d(3.0 + r / 16, c / 16) + 1) * 127.5)
      local cb = math.floor((simplex.simplex_2d(7.0 + r / 16, c / 16) + 1) * 127.5)
      noisetex.cdata[p]   = cb
      noisetex.cdata[p+1] = cg
      noisetex.cdata[p+2] = cr
      noisetex.cdata[p+3] = 255
      p = p + 4
    end
  end
  noisetex:commit()
  local mat2 = flat.FlatMaterial{
    diffuse = {1.0, 1.0, 1.0, 1.0}, 
    tint = {0.001, 0.001, 0.001},
    roughness = 0.7,
    texture = noisetex
  }
  local cube2 = myapp.scene:create_child(graphics.Mesh, "cube2", geo, mat2)
  cube2:add_component(Rotator(1.0 / 60.0))
  cube2.position:set(0.0, 0.0, 1.0)
  cube2:update_matrix()

  -- 3d texture from data
  local tempv = math.Vector()
  local function texfunc(x, y, z)
    local r = math.sqrt(x*x + y*y + z*z)
    local v = math.floor((math.cos(r * 20) + 1.0) * 127.5)
    return v, v, v
  end

  local noise3d = gfx.Texture3d{width = 32, height = 32, depth = 32, 
                                format = gfx.TEX_BGRA8}
  local p = 0
  for r = 0, 31 do
    for c = 0, 31 do
      for d = 0, 31 do
        local x, y, z = (r - 16)/16, (c - 16)/16, (d - 16)/16
        local cr, cg, cb = texfunc(x, y, z)
        noise3d.cdata[p]   = cb
        noise3d.cdata[p+1] = cg
        noise3d.cdata[p+2] = cr
        noise3d.cdata[p+3] = 255
        p = p + 4
      end
    end
  end
  noise3d:commit()
  local mat3 = flat.FlatMaterial{
    texture = noise3d,
    origin = math.Vector(-0.5, -0.5, -0.5), scale = 10.1
  }
  local cube3 = myapp.scene:create_child(graphics.Mesh, "cube3", geo, mat3)
  cube3:add_component(Rotator(1.0 / 60.0))

  local gridlines = myapp.scene:create_child(grid.Grid, 'grid', {
    thickness = 0.01, 
    color = {0.5, 0.2, 0.2}
  })
  gridlines.position:set(0.0, -1.0, 0.0)
  gridlines.quaternion:euler({x = math.pi / 2.0, y = 0.0, z = 0.0})
  gridlines:update_matrix()
end

function update()
  myapp:update()
end
