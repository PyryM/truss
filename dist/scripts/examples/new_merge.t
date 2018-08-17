local app = require("app/app.t")
local geometry = require("geometry")
local pbr = require("material/pbr.t")
local graphics = require("graphics")
local orbitcam = require("gui/orbitcam.t")
local grid = require("graphics/grid.t")
local config = require("utils/config.t")

local function srand(mag)
  return (math.random() * 2.0 - 1.0) * mag
end

local function add_tentacle(node, geo, n)
  for i = 1, n do
    node = node:create_child(graphics.DummyMesh, "nnn", geo)
    if i == 1 then
      node.quaternion:euler({x = srand(6), y = srand(6), z = srand(6)})
    else
      node.position:set(srand(0.2), 3.0 + srand(0.3), srand(0.2))
      node.quaternion:euler({x = srand(0.5), y = srand(0.5), z = srand(0.5)})
    end
    node.scale:set(0.9, 0.9, 0.9)
    node:update_matrix()
  end
end

function merge_a_bunch_of_stuff(n_tentacles, tentacle_length, geo)
  local builder = geometry.util.Builder()
  for _ = 1, n_tentacles do
    add_tentacle(builder.root, geo, tentacle_length)
  end
  local ret = builder:build()
  log.debug("Merged together into " .. ret.n_verts .. " vertices and " 
            .. ret.n_indices .. " indices.")
  return ret
end

function init()
  local cfg = config.Config{
      orgname = "truss", 
      appname = "merge_example", 
      use_global_save_dir = false,
      defaults = {
        width = 1280, height = 720, msaa = true, stats = true
      }
    }:load()
  cfg.title = "geometry merging example"  -- settings added after creation aren't saved
  cfg.clear_color = 0x000000ff 
  cfg:save()

  myapp = app.App(cfg)
  myapp.camera:add_component(orbitcam.OrbitControl{min_rad = 1, max_rad = 4})

  local base_geo = geometry.cylinder_geo{radius = 3.15, height = 6.0, segments = 11, capped = true}
  local tentacles = merge_a_bunch_of_stuff(100, 20, base_geo)
  local mat = pbr.FacetedPBRMaterial{diffuse = {0.0001, 0.0001, 0.0001, 1.0}, 
                                     tint = {0.01, 0.01, 0.01}, 
                                     roughness = 0.5}
  mymesh = myapp.scene:create_child(graphics.Mesh, "mymesh", tentacles, mat)
  mymesh.scale:set(0.1, 0.1, 0.1)
  mymesh:update_matrix()
  mygrid = myapp.scene:create_child(grid.Grid, {thickness = 0.03,
                                                numlines = 0, numcircles = 30,
                                                spacing = 2.0,
                                                color = {0.9, 0.1, 0.1, 1.0}})
  mygrid.position:set(0.0, -0.5, 0.0)
  mygrid.quaternion:euler({x = math.pi / 2.0, y = 0.0, z = 0.0})
  mygrid:update_matrix()
end

function update()
  myapp:update()
end
