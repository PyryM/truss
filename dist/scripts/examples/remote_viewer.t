-- examples/remote_viewer.t
-- 
-- remote viewer example (through io/zremote)

local zmq = require("io/zmq.t")
local zremote = require("io/zremote.t")
local geometry = require("geometry")
local pbr = require("shaders/pbr.t")
local flat = require("shaders/flat.t")
local graphics = require("graphics")
local orbitcam = require("gui/orbitcam.t")
local grid = require("graphics/grid.t")
local config = require("utils/config.t")
local ecs = require("ecs")
local math = require("math")
local gfx = require("gfx")

local georoot = nil
local models = {}
local nextmodel = 1

local terra to_float_array(src: &int8)
  return [&float](src)
end

local terra copy_to_uint16_array(src: &int8, dest: &uint16, count: int32)
  var csrc: &uint16 = [&uint16](src)
  for i = 0, count do
    dest[i] = csrc[i]
  end
end

local terra copy_to_uint32_array(src: &int8, dest: &uint32, count: int32)
  var csrc: &uint32 = [&uint32](src)
  for i = 0, count do
    dest[i] = csrc[i]
  end
end

local function copy_indices(src, dest, n)
  local csrc = nil
  if #src == n*2 then
    copy_to_uint16_array(src, dest, n)
  elseif #src == n*4 then
    copy_to_uint32_array(src, dest, n)
  else
    truss.error("Index buffer size mismatch: not 2 or 4 bytes! Expected "
                .. n*2 .. " or " .. n*4 .. ", got " .. #src)
  end
end

-- have to fill this in later because vertex info can't be created until
-- the renderer is initialized
local vertex_info = nil
local copy_verts = nil

local function geo_from_strings(geodata)
  local nverts = geodata.nverts
  local actual_size = #geodata.verts
  local expected_size = (nverts * 4 * 3)
  if actual_size ~= expected_size then
    truss.error("Vertex stream size mismatch: got " 
                .. actual_size .. " expected " .. expected_size)
  end
  local nindices = geodata.nindices
  local geo = gfx.StaticGeometry()
  print("verts: " .. nverts)
  print("indices: " .. nindices)
  geo:allocate(nverts, nindices, vertex_info)
  copy_verts(to_float_array(geodata.verts), geo.verts, geo.n_verts)
  copy_indices(geodata.indices, geo.indices, geo.n_indices)
  geo:commit()
  return geo
end

local function mat_from_opts(mat_opts)
  -- todo
  return pbr.FacetedPBRMaterial{
    diffuse = {0.2, 0.2, 0.2, 1.0}, 
    tint = {0.001, 0.001, 0.001}, 
    roughness = 0.7}
  --return flat.FlatMaterial{color = {0.2, 0.2, 0.2, 1.0}}
end

local function transform_from_opts(tf)
  -- todo
  return math.Matrix4():identity()
end

local function add_model(opts)
  if not opts.geo then truss.error("add_model: no geometry specified") end
  local geo = geo_from_strings(opts.geo)
  local mat = mat_from_opts(opts.mat)
  local model_name = opts.name or ("model_" .. nextmodel)
  nextmodel = nextmodel + 1
  local model = georoot:create_child(graphics.Mesh, model_name, geo, mat)
  model.matrix:copy(transform_from_opts(opts.transform))
  models[model_name] = model
end

local function clear_models()
  for modelname, model in pairs(models) do
    model.mesh.geo:destroy()
    model:destroy()
  end
  models = {}
end

function init()
  local cfg = config.Config{
      appname = "remote_viewer", 
      defaults = {
        width = 1280, height = 720, msaa = true, stats = true, 
        vr = false, url = "tcp://*:5555"
      },
    }:load()
  cfg.title = "remote_viewer"  -- settings added after creation aren't saved
  cfg.clear_color = 0x404080ff 
  cfg:save()

  local url = truss.args[3] or cfg.url
  if not url or url == "" then
    print("Remote: no host url specified")
    truss.quit()
    return
  end
  remote_env = {
    add = add_model,
    clear = clear_models
  }
  zmq.init()
  remote = zremote.Remote{url = url, 
                  env = truss.extend_table(remote_env, truss.clean_subenv)}

  local App
  if cfg.vr then
    App = require("vr/vrapp.t").VRApp
  else
    App = require("app/app.t").App
  end
  app = App(cfg)
  georoot = app.scene:create_child(ecs.Entity3d, "georoot")
  georoot.position:set(0.0, 1.0, 0.0)
  --georoot.scale:set(0.001, 0.001, 0.001)
  georoot:update_matrix()

  local base_grid = app.scene:create_child(grid.Grid, {thickness = 0.01, 
                                                       color = {0.5, 0.5, 0.5, 1.0}})
  base_grid.position:set(0.0, 0.0, 0.0)
  base_grid.quaternion:euler({x = math.pi / 2.0, y = 0.0, z = 0.0})
  base_grid:update_matrix()

  if not cfg.vr then
    app.camera:add_component(orbitcam.OrbitControl{min_rad = 0.1, max_rad = 4})
    app.camera.orbit_control.orbitpoint:set(0.0, 1.0, 0.0)
  end

  -- fill in vertex stuff
  vertex_info = gfx.create_basic_vertex_type({"position"})
  copy_verts = terra (src: &float, dest: &vertex_info.ttype, count: int32)
    var pos = 0
    for pos = 0, count do
      dest[pos].position[0] = src[pos*3 + 0]
      dest[pos].position[1] = src[pos*3 + 1]
      dest[pos].position[2] = src[pos*3 + 2]
    end
  end
end

function update()
  remote:update()
  app:update()
end