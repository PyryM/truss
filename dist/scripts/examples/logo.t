-- examples/logo.t
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

function edge_dist_func(p0, p1)
  local x0, y0, z0 = p0:components()
  local x1, y1, z1 = p1:components()
  local d = p1 - p0
  local tardist = d:length3()
  local nx, ny, nz = d:normalize3():components()
  local THRESH = 0.05 * tardist
  return function(x, y, z)
    dx, dy, dz = x - x0, y - y0, z - z0
    parallel_dist = dx*nx + dy*ny + dz*nz
    -- if parallel_dist > tardist then
    --   dx, dy, dz = x - x1, y - y1, z - z1
    --elseif parallel_dist > 0 then
    dx = dx - nx*parallel_dist
    dy = dy - ny*parallel_dist
    dz = dz - nz*parallel_dist
    --end
    if parallel_dist < THRESH then
      parallel_dist = THRESH - parallel_dist
    elseif parallel_dist > tardist - THRESH then
      parallel_dist = parallel_dist - (tardist - THRESH)
    else
      parallel_dist = 0
    end
    local v = (dx*dx + dy*dy + dz*dz)
    v = math.exp(-1000*v) * math.exp(-parallel_dist*80)
    return v
  end
end

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

function make_column_edges()
  local edges = {}
  local prev_tier = nil
  for tier = 1, 4 do
    local pts = {}
    for idx = 0, 2 do
      local theta = math.random()*0.1 + (idx + tier/2) * math.pi * 2 / 3
      pts[idx] = math.Vector(math.cos(theta)*0.15+0.5, 
                             tier/5, 
                             math.sin(theta)*0.15+0.5)
    end
    for idx = 0, 2 do
      table.insert(edges, {pts[idx], pts[(idx+1)%3]})
      if prev_tier then
        table.insert(edges, {pts[idx], prev_tier[idx]})
        table.insert(edges, {pts[idx], prev_tier[(idx+1)%3]})
      end
    end
    prev_tier = pts
  end
  return edges
end

terra zero(oldval: float, x: float, y: float, z: float): float
  return 0.0
end

terra recenter(oldval: float, x: float, y: float, z: float): float
  return oldval - 0.8
end

function gen_cell(data, x, y, z, dg, funclist)
  local limits = {
    x_start = x*dg, x_end = (x+1)*dg + 1,
    y_start = y*dg, y_end = (y+1)*dg + 1,
    z_start = z*dg, z_end = (z+1)*dg + 1
  }
  mc.mc_data_from_terra(data, zero, limits)
  local t0 = truss.tic()
  for _, f in ipairs(funclist) do
    mc.mc_data_from_terra(data, f, limits)
    if truss.toc(t0)*1000.0 > 25.0 then
      async.await_frames(1)
      t0 = truss.tic()
    end
  end
  mc.mc_data_from_terra(data, recenter, limits)
  return mc.cubify_to_geo(data, 64000, nil, limits)
end

function generate_logo_mesh(parent, material, resolution)
  local edge_funcs = {}
  for idx, edge in ipairs(make_column_edges()) do
    edge_funcs[idx] = ter_edge_dist_func(unpack(edge))
  end
  local ndivs = 8
  local dg = resolution / ndivs -- just assume no remainder
  local data = mc.mc_data_from_function(
    function() return 0.0 end, 
    resolution+1 -- need 1 voxel padding for reasons
  ) 
  local partidx = 0
  for iz = 0, ndivs-1 do
    for iy = 0, ndivs-1 do
      for ix = 0, ndivs-1 do
        local geo = gen_cell(data, ix, iy, iz, dg, edge_funcs)
        local mesh = parent:create_child(graphics.Mesh, "_logo_" .. partidx,
                                         geo, material)
        mesh.position:set(-0.5, -0.5, -0.5)
        mesh:update_matrix()
        partidx = partidx + 1
      end
    end
  end
end

function Logo(_ecs, name, options)
  local ret = ecs.Entity3d(_ecs, name)
  local rotator = ret:create_child(ecs.Entity3d, "_rotator")
  rotator:add_component(ecs.UpdateComponent(function(self)
    self.f = (self.f or 0) + 1
    self.ent.quaternion:euler{x = 0, y = self.f*0.01, z = 0}
    self.ent:update_matrix()
  end))

  local mat = pbr.FacetedPBRMaterial{
    diffuse = {0.001,0.001,0.001,1.0},
    tint = {1.0, 0.02, 0.2}, 
    roughness = 0.3
  }
  async.run(generate_logo_mesh, rotator, mat, 2^(options.detail)):next(print, print)

  return ret
end

function Skybox(_ecs, name, texname)
  local sky_sphere = geometry.uvsphere_geo{lat_divs = 30, lon_divs = 30}
  local skymat = flat.FlatMaterial{
    skybox = true, texture = gfx.Texture(texname)
  }
  local skybox = graphics.Mesh(_ecs, name, sky_sphere, skymat)
  skybox.scale:set(-10, -10, -10)
  skybox:update_matrix()
  return skybox
end

local NVGThing = graphics.NanoVGComponent:extend("NVGThing")
function NVGThing:nvg_draw(ctx)
  ctx:load_font("font/FiraSans-Regular.ttf", "sans")
  ctx:FontFace("sans")
  ctx:FontSize(200)
  ctx:FillColor(ctx:RGBA(0xFF, 0x1D, 0x76, 200))
  ctx:TextAlign(ctx.ALIGN_LEFT + ctx.ALIGN_TOP)
  local dx = ctx:Text(30, 0, "truss", nil)
  ctx:FontSize(80)
  ctx:Text(dx + 10, 15, "0.1.0", nil)
end

function init()
  myapp = app.App{
    width = 1280, height = 720, 
    msaa = true, stats = false,
    title = "truss | logo.t", clear_color = 0x000000ff
  }
  myapp.camera:add_component(orbitcam.OrbitControl{min_rad = 0.7, max_rad = 1.2})
  local logo = myapp.scene:create_child(Logo, "logo", {detail = 8})
  logo.quaternion:euler({x = -math.pi/4, y = 0.2, z = 0}, 'ZYX')
  logo:update_matrix()

  myapp.scene:create_child(Skybox, 'sky', 'textures/starmap.ktx')
  myapp.scene:create_child(ecs.Entity3d, "logotext", NVGThing())
end

function update()
  myapp.camera.orbit_control:move_theta(math.pi * 2.0 / 120.0)
  myapp:update()
end
