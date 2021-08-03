-- examples/logos/alien.t
-- run if you call truss.exe without any args and without a custom main.t

local app = require("app/app.t")
local geometry = require("geometry")
local pbr = require("material/pbr.t")
local flat = require("material/flat.t")
local gfx = require("gfx")
local graphics = require("graphics")
local orbitcam = require("graphics/orbitcam.t")
local grid = require("graphics/grid.t")
local mc = require("procgen/marchingcubes.t")
local math = require("math")
local tmath = require("math/tmath.t")
local cmath = require("math/cmath.t")
local ecs = require("ecs")
local async = require("async")
local class = require("class")
local imgui = require("gfx/imgui.t")
local common = require("examples/logos/logocommon.t")

local dbar = require("gui/databar.t")

function ter_edge_dist_func(p0, p1)
  local x0, y0, z0 = p0:components()
  local x1, y1, z1 = p1:components()
  local d = p1 - p0
  local tardist = d:length3()
  local nx, ny, nz = d:normalize3():components()
  local THRESH = 0.05 * tardist
  return terra(oldval: float, x: float, y: float, z: float): float
    var p0: tmath.Vec3f
    var p1: tmath.Vec3f
    var n: tmath.Vec3f
    var p: tmath.Vec3f
    n:set(nx, ny, nz)
    p0:set(x0, y0, z0)
    p1:set(x1, y1, z1)
    p:set(x, y, z)
    var dp: tmath.Vec3f = p - p0
    var parallel_dist = dp:dot(&n)
    dp = dp - (n * parallel_dist)
    if parallel_dist < THRESH then
      parallel_dist = THRESH - parallel_dist
    elseif parallel_dist > tardist - THRESH then
      parallel_dist = parallel_dist - (tardist - THRESH)
    else
      parallel_dist = 0.0
    end
    var v = dp:length_squared()
    v = cmath.expf(-1000.0*v) * cmath.expf(-parallel_dist*80.0)
    return oldval + v
  end
end

local terra zero(oldval: float, x: float, y: float, z: float): float
  return 0.0
end

local terra recenter(oldval: float, x: float, y: float, z: float): float
  return oldval - 0.8
end

local function gen_cell(data, x, y, z, dg, funclist)
  local limits = {
    x_start = x*dg, x_end = (x+1)*dg + 1,
    y_start = y*dg, y_end = (y+1)*dg + 1,
    z_start = z*dg, z_end = (z+1)*dg + 1
  }
  mc.mc_data_from_terra(data, zero, limits)
  local t0 = truss.tic()
  for _, f in ipairs(funclist) do
    mc.mc_data_from_terra(data, f, limits)
    if truss.toc(t0)*1000.0 > 10.0 then
      async.await_frames(1)
      t0 = truss.tic()
    end
  end
  mc.mc_data_from_terra(data, recenter, limits)
  return mc.cubify_to_geo(data, 64000, nil, limits)
end

local function generate_logo_mesh(parent, material, resolution, progress_cb)
  local edge_funcs = {}
  for idx, edge in ipairs(common.make_logo_column_edges()) do
    edge_funcs[idx] = ter_edge_dist_func(unpack(edge))
  end
  local ndivs = 4
  local dg = resolution / ndivs -- just assume no remainder
  local data = mc.mc_data_from_function(
    function() return 0.0 end, 
    resolution+1 -- need 1 voxel padding for reasons
  )
  local progress = common.add_textbox{
    x = gfx.backbuffer_width/2 - 400/2, y = gfx.backbuffer_height/2, 
    w = 400, h = 30, font_size = 30,
    color = {255,255,255,255},
    text = "Generating mesh", font = 'mono'
  }
  local partidx = 0
  for iz = 0, ndivs-1 do
    for iy = 0, ndivs-1 do
      for ix = 0, ndivs-1 do
        local geo = gen_cell(data, ix, iy, iz, dg, edge_funcs)
        if geo then
          local mesh = parent:create_child(graphics.Mesh, "_logo_" .. partidx,
                                          geo, material)
          mesh.position:set(-0.5, -0.5, -0.5)
          mesh:update_matrix()
        end
        if progress_cb then progress_cb(partidx, ndivs^3 - 1) end
        progress.text = ("Generating mesh [%03d / %03d]"):format(partidx, ndivs^3)
        partidx = partidx + 1
      end
    end
  end
  progress.dead = true
  if progress_cb then progress_cb(1, 1) end
end

local function Logo(_ecs, name, options)
  local ret = ecs.Entity3d(_ecs, name)
  local rotator = ret:create_child(ecs.Entity3d, "_rotator")
  rotator:add_component(ecs.UpdateComponent(function(self)
    self.f = (self.f or 0) + 1
    self.ent.quaternion:euler{x = 0, y = self.f/120, z = 0}
    self.ent:update_matrix()
  end))

  local mat = pbr.FacetedPBRMaterial{
    diffuse = {0.001,0.001,0.001,1.0},
    tint = {1.0, 0.02, 0.2}, 
    roughness = 0.3
  }
  async.run(generate_logo_mesh, rotator, mat, 2^(options.detail), options.progress_cb):next(nil, print)

  return ret
end

local function Stars(_ecs, name, options)
  options = options or {}
  local nstars = options.nstars or 10000
  local vinfo = gfx.create_basic_vertex_type({"position"})
  local data = {indices = {}, attributes={position={}}}
  local p = math.Vector()
  local v = math.Vector()
  local x = math.Vector()
  local y = math.Vector()
  for star_idx = 1, nstars do
    math.rand_spherical(p)
    p:normalize3()
    math.rand_spherical(x):normalize3()
    y:cross(x, p):normalize3()
    x:cross(y, p):normalize3()
    local start_index = #(data.indices)
    for offset = 0, 2 do
      local theta = offset * 2.0 * math.pi / 3.0
      local s = math.random()*0.003 + 0.001
      v:lincomb(x, y, math.cos(theta)*s, math.sin(theta)*s)
      v:add(p)
      table.insert(data.attributes.position, v:to_array())
      table.insert(data.indices, start_index+offset)
    end
  end
  local geo = gfx.StaticGeometry(name):from_data(data)
  local mat = flat.FlatMaterial{skybox = true, state={cull=false}, color={0.3,0.3,0.3,1}}
  local stars = graphics.Mesh(_ecs, name, geo, mat)
  stars.scale:set(-10, -10, -10)
  stars:update_matrix()
  return stars
end

local gif_mode = false
local imgui_open = terralib.new(bool[1])
imgui_open[0] = false
local dbstate = nil

function init()
  myapp = app.App{
    width = (gif_mode and 720) or 1280, height = 720, 
    msaa = true, hidpi = true, stats = false, imgui = true,
    title = "truss | logo.t", clear_color = 0x000000ff,
  }

  local db_builder = dbar.DatabarBuilder{
    title = "BoopDoop",
    width = 400, height = 680,
    x = 20, y = 20,
    open = true, allow_close = true
  }
  db_builder:field{"logo_progress", "progress"}
  db_builder:field{"rotate_view", "bool", default = true, tooltip = "Automatically rotate the view\nDo newlines work?"}
  db_builder:field{"rotate_model", "bool", default = true, tooltip = "This doesn't actually work"}
  db_builder:field{"view_speed", "float", limits={0, 10.0}, default=1.0, tooltip = "Multiply rotate speed by this"}
  db_builder:field{"Boozle", "int", limits={-100,100}, default=13}
  db_builder:field{"Moozle", "float", limits={-100,100}, default=13.13}
  db_builder:field{"thingy", "choice", choices={"An Apple", "A Banana", "A Coconut"}, default=1}
  db_builder:field{"albedo", "color", default={1,0,1,1}}
  db_builder:field{"divider"}
  db_builder:field{"show_demo", "button", label="Show IMGUI demo!"}
  db_builder:field{"A random label!", "label"}
  dbstate = db_builder:build()

  function myapp:imgui_draw()
    if dbstate.show_demo > 0 then
      imgui_open[0] = true
      dbstate.show_demo = 0
    end
    if imgui_open[0] then
      imgui.C.ShowDemoWindow(imgui_open)
    end
    dbstate:draw()
  end

  myapp.camera:add_component(orbitcam.OrbitControl{min_rad = 0.7, max_rad = 1.2})
  myapp.camera.orbit_control:set(0, 0, 0.7)
  local logo = myapp.scene:create_child(Logo, "logo", {
    detail = 7, progress_cb = function(n, d)
      dbstate.logo_progress = n/d
    end
  })
  logo.quaternion:euler({x = -math.pi/4, y = 0.2, z = 0}, 'ZYX')
  logo:update_matrix()

  myapp.scene:create_child(Stars, 'sky', {nstars = 30000})
  myapp.scene:create_child(ecs.Entity3d, "logotext", common.NVGDrawer())

  async.run(function()
    common.add_textbox{
      x = 10, y = 10, w = 400, h = 200,
      font_size = 200, text = 'truss'
    }
    async.await_frames(5)
    common.add_textbox{
      x = 390, y = 10, w = 220, h = 120,
      font_size = 100, text = truss.C.get_version()
    }
    if gif_mode then return end
    -- spawn caps
    local ypos = 5
    local mult = gfx.backbuffer_width / myapp.width
    for capname, supported in pairs(gfx.get_caps().features) do
      local color = (supported and {200,255,200,255}) or {100,100,100,255}
      common.add_textbox{
        x = gfx.backbuffer_width - 280 * mult, y = ypos, w = 250 * mult, h = 23 * mult, 
        font_size = 20 * mult, text = capname, color = color, font = 'mono'
      }
      ypos = ypos + 20 * mult
      async.await_frames(5)
    end
  end)

  common.dump_text_caps()
end

function update()
  if dbstate.rotate_view and not gif_mode then
    myapp.camera.orbit_control:move_theta(dbstate.view_speed * math.pi * 2.0 / 120.0)
  end
  myapp:update()
end
