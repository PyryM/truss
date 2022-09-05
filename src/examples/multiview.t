local app = require("app/app.t")
local geometry = require("geometry")
local pbr = require("material/pbr.t")
local graphics = require("graphics")
local orbitcam = require("graphics/orbitcam.t")
local math = require("math")

local MultiviewApp = app.App:extend("MultiviewApp")
function MultiviewApp:init_pipeline()
  local half_width = self.width / 2
  local left  = {         0, 0, half_width, self.height}
  local right = {half_width, 0, half_width, self.height}

  local clear_l = {color = self.clear_color or 0x000000ff, depth = 1.0}
  local clear_r = {color = 0x000000ff, depth = 1.0}

  local Vector = math.Vector
  local p = graphics.Pipeline({verbose = true})

  p:add_stage(graphics.MultiviewStage{
    name = "forward",
    globals = p.globals,
    render_ops = {
      graphics.MultiDrawOp(), 
      graphics.MultiCameraOp()
    },
    views = {
      {name = "left", clear = clear_l, viewport = left}, 
      {name = "right", clear = clear_r, viewport = right}
    }
  })
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
  self.ECS.systems.render:set_pipeline(p)
end

function MultiviewApp:init_scene()
  local fov = 65
  local aspect = 0.5 * self.width / self.height
  self.left_camera = self.ECS.scene:create_child(graphics.Camera,
                                                "Leftcamera",
                                                {fov = fov, tag = "left",
                                                orthographic = true,
                                                 left = -aspect, right = aspect,
                                                top = 1.0, bottom = -1.0})
  self.right_camera = self.ECS.scene:create_child(graphics.Camera,
                                                  "Rightcamera",
                                                 {fov = fov, tag = "right",
                                                  aspect = aspect})
  self.right_camera.position:set(0, 0, 5)
  self.right_camera:update_matrix()
  self.scene = self.ECS.scene
end

function init()
  myapp = MultiviewApp{title = "multiview example", 
                       width = 1280, height = 720,
                       msaa = true, stats = true, clear_color = 0x404080ff}

  myapp.left_camera:add_component(orbitcam.OrbitControl({min_rad = 1, max_rad = 4}))

  local geo = geometry.box_widget_geo{side_length = 1.0}
  local mat = pbr.FacetedPBRMaterial({0.2, 0.03, 0.01, 1.0}, {0.001, 0.001, 0.001}, 0.7)
  mymesh = myapp.scene:create_child(graphics.Mesh, "mymesh", geo, mat)
end

function update()
  myapp:update()
end
