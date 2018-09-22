local app = require("app/app.t")
local geometry = require("geometry")
local pbr = require("material/pbr.t")
local flat = require("material/flat.t")
local graphics = require("graphics")
local orbitcam = require("gui/orbitcam.t")
local grid = require("graphics/grid.t")
local gfx = require("gfx")
local ecs = require("ecs")

local CubeRenderApp = app.App:extend("CubeRenderApp")
function CubeRenderApp:init_pipeline()
  local cubemap = gfx.TextureCube{
    size = 2048,
    flags = {render_target = true},
    allocate = false
  }:commit()
  local cube_order = {"px", "nx", "py", "ny", "pz", "nz"}
  local ct = {}
  for idx, face_id in ipairs(cube_order) do
    ct[face_id] = gfx.TextureTarget{
      tex = cubemap,
      layer = idx - 1,
      depth_format = gfx.TEX_D24
    }
  end

  local colors = {0xaa0000ff, 0x00aa00ff, 0x0000aaff, 0xaaaa00ff, 0x00aaaaff, 0xaa00aaff}
  --local colors = {0x000000ff, 0x000000ff, 0x000000ff, 0x000000ff, 0x000000ff, 0x000000ff}

  local p = graphics.Pipeline({verbose = true})
  p:add_stage(graphics.MultiviewStage{
    name = "cube_render",
    globals = p.globals,
    filter = function(tags) return (not tags.cube) end,
    render_ops = {
      graphics.MultiDrawOp(), 
      graphics.MultiCameraOp()
    },
    always_clear = true,
    views = {
      {name = "cube_px", clear = {color = colors[1], depth = 1.0}, render_target = ct.px}, 
      {name = "cube_nx", clear = {color = colors[2], depth = 1.0}, render_target = ct.nx},
      {name = "cube_py", clear = {color = colors[3], depth = 1.0}, render_target = ct.py},
      {name = "cube_ny", clear = {color = colors[4], depth = 1.0}, render_target = ct.ny},
      {name = "cube_pz", clear = {color = colors[5], depth = 1.0}, render_target = ct.pz},
      {name = "cube_nz", clear = {color = colors[6], depth = 1.0}, render_target = ct.nz}
    }
  })
  p:add_stage(graphics.FullscreenStage{
    name = "pano_flatten",
    shader = "fs_fullscreen_panoflatten",
    input = cubemap
  })
  local Vector = require("math").Vector
  p.globals.u_lightDir:set_multiple({
      Vector( 1.0,  1.0,  0.0),
      Vector(-1.0,  1.0,  0.0),
      Vector( 0.0, -1.0,  1.0),
      Vector( 0.0, -1.0, -1.0)})
  p.globals.u_lightRgb:set_multiple({
      Vector(0.8, 0.8, 0.8),
      Vector(1.0, 1.0, 1.0),
      Vector(0.1, 0.1, 0.1),
      Vector(0.1, 0.1, 0.1)})

  self.pipeline = p
  self.cubemap = cubemap
  self.cube_targets = ct
  self.ECS.systems.render:set_pipeline(p)
end

function init()
  myapp = CubeRenderApp{title = "basic example", width = 1280, height = 640,
                  msaa = true, stats = true, clear_color = 0x404080ff}

  rotator = myapp.ECS.scene:create_child(ecs.Entity3d, "Rotator")
  cubecam = rotator:create_child(graphics.CubeCamera, "CubeCam", {})
  cubecam.position:set(2.5, 0.0, 0.0)
  cubecam:update_matrix()

  local geo = geometry.axis_widget_geo{}
  local mat = pbr.FacetedPBRMaterial({0.2, 0.03, 0.01, 1.0}, {0.001, 0.001, 0.001}, 0.7)
  mymesh = myapp.scene:create_child(graphics.Mesh, "mymesh", geo, mat)
  mygrid = myapp.scene:create_child(grid.Grid, "mygrid", {thickness = 0.01, 
                                                color = {0.5, 0.2, 0.2}})
  mygrid.position:set(0.0, -1.0, 0.0)
  mygrid.quaternion:euler({x = math.pi / 2.0, y = 0.0, z = 0.0})
  mygrid:update_matrix()

  local tartex = gfx.Texture("textures/test_pattern.png")
  local tarmat = flat.FlatMaterial{texture = tartex}
  local targeo = geometry.plane_geo{width = 1, height = 1}

  local target = myapp.scene:create_child(graphics.Mesh, "calibtarget", targeo, tarmat)
  target.position:set(0.5, 0.5, 0.5)
  target.quaternion:euler({x = 0.0, y = math.pi, z = 0.0})
  target:update_matrix()

  -- skybox
  -- local skygeo = geometry.uvsphere_geo{lat_divs = 30, lon_divs = 30}
  -- local skymat = flat.FlatMaterial{skybox = true, cubemap = true,
  --                   texture = myapp.cubemap,
  --                   tags = {cube = true}}
  -- skybox = myapp.scene:create_child(graphics.Mesh, "sky", skygeo, skymat)
  -- skybox.scale:set(-15, -15, -15)
  -- skybox:update_matrix()
end

local t = 0.0
function update()
  t = t + 1.0 / 60.0
  rotator.quaternion:euler{x = 0.0, y = t, z = 0.0}
  rotator:update_matrix()
  --cubecam.position:set(math.cos(t), 0, math.sin(t))
  --cubecam:update_matrix()
  myapp:update()
end
