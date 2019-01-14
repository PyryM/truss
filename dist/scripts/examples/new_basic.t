--[[
  ## Basic Example

  Demonstrates some basic features of truss.
]]

--[[
  A bunch of typical includes. We include both the midlevel graphics
  module `gfx` and the high-level module `graphics`.
]]
local App = require("app/app.t").App
local gfx = require("gfx")
local geometry = require("geometry")
local graphics = require("graphics")
local Grid = require("graphics/grid.t").Grid
local pbr = require("material/pbr.t")
local flat = require("material/flat.t")
local orbitcam = require("gui/orbitcam.t")
local Config = require("utils/config.t").Config

--[[ 
  A script loaded as the 'main' script has to define two functions:
  `init` and `update`.
]]
function init()
  --[[
    The `config` module can be used to save/load user-editable (in json format)
    configuration files. The orgname and appname are used to figure out the
    OS-recommended save path (which tends to be pretty obscure).
  ]]
  local cfg = Config{
    orgname = "truss", 
    appname = "basic_example", 
    use_global_save_dir = false,
    defaults = {
      width = 1280, height = 720, msaa = true, stats = true
    }
  }:load()
  -- because these settings don't have defaults, they won't be
  -- saved or loaded from the .json
  cfg.title = "basic_example"  
  cfg.clear_color = 0x404080ff 
  cfg:save()

  --[[
    Our `config.Config` instance will have the fields we provided in
    `defaults`, which is why we can pass it directly to the `App()`
    constructor.
  ]]
  app = App(cfg)

  --[[
    `App` automatically creates a camera entity, so we add an `OrbitControl`
    component onto it to provide the mouse controls to move the camera.
  ]]
  app.camera:add_component(orbitcam.OrbitControl{
    min_rad = 1, max_rad = 4
  })

  --[[
    Typically to create models you'll obtain a geometry and a material and then
    instantiate a `graphics.Mesh` from them.

    The local transforms of entities are exposed as `.position`, `.scale`,
    and `.quaternion`; note that after changing any of these, the combined
    transform matrix must be updated with `:update_matrix()`. 

    Although these values can be directly assigned,
    e.g., `mygrid.position = math.Vector(0, -1, 0)`, it's typically better
    to mutate them in place with various setter functions.
  ]]
  local geo = geometry.box_widget_geo{side_length = 1.0}
  local mat = pbr.FacetedPBRMaterial{
    diffuse = {0.2, 0.03, 0.01, 1.0}, 
    tint = {0.001, 0.001, 0.001}, 
    roughness = 0.7
  }
  mesh = app.scene:create_child(graphics.Mesh, "mesh", geo, mat)
  grid = app.scene:create_child(Grid, "mygrid", {
    thickness = 0.01, color = {0.6, 0.6, 0.6}
  })
  grid.position:set(0.0, -1.0, 0.0)
  grid.quaternion:euler({x = math.pi / 2.0, y = 0.0, z = 0.0})
  grid:update_matrix()

  --[[
    Textures are a mid-level primitive, and so are part of `gfx` rather
    than `graphics`.
  ]]
  local tartex = gfx.Texture("textures/test_pattern.png")
  local tarmat = flat.FlatMaterial{texture = tartex}
  local targeo = geometry.plane_geo{width = 1, height = 1}

  target = app.scene:create_child(graphics.Mesh, "calibtarget", 
                                  targeo, tarmat)
  target.position:set(-0.5, 0.0, 0.0)
  target.quaternion:euler({x = 0.0, y = math.pi/2.0, z = 0.0})
  target:update_matrix()
end

--[[
  Our update function just defers all the hard work to `App`.
]]
function update()
  app:update()
end
