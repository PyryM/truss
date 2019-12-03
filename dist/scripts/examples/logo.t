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
local class = require("class")

local drawables = {}
local next_drawable = 1
local function draw_2d_drawables(ctx)
  for idx, draw in pairs(drawables) do
    if draw.dead then
      drawables[idx] = nil
    else
      draw:draw(ctx)
    end
  end
end
local function add_2d_drawable(f, state)
  local d = state or {}
  drawables[next_drawable] = d
  next_drawable = next_drawable + 1
  async.run(f, d):next(nil, print)
  return d
end

local function _drawbox(state, ctx)
  ctx:BeginPath()
  ctx:Rect(state.x, state.y, state.w, state.h)
  ctx:FillColor(ctx:RGBA(unpack(state.color)))
  ctx:Fill()
end
local function _drawtext(state, ctx)
  ctx:FontFace(state.font or "sans")
  ctx:FontSize(state.font_size)
  ctx:FillColor(ctx:RGBA(unpack(state.color)))
  ctx:TextAlign(ctx.ALIGN_LEFT + ctx.ALIGN_TOP)
  if state.clip_w then
    ctx:Scissor(state.x, state.y, state.clip_w, state.h)
  end
  ctx:Text(state.x, state.y, state.text, nil)
  if state.clip_w then
    ctx:ResetScissor()
    ctx:BeginPath()
    ctx:Rect(state.x + state.clip_w, state.y, state.w - state.clip_w, state.h)
    ctx:Fill()
  end
end

local function out_expo(t)
  if t == 1 then
    return 1
  else
    return 1.001 * (-(2^(-10 * t)) + 1)
  end
end
local function textbox(state)
  state.color = state.color or {0xFF, 0x1D, 0x76, 200}
  state.draw = _drawbox
  local final_w = state.w
  for f = 1, 20 do
    state.w = final_w * out_expo(f/20)
    async.await_frames(1)
  end
  state.draw = _drawtext
  for f = 1, 30 do
    state.clip_w = final_w * out_expo(f/30)
    async.await_frames(1)
  end
  state.clip_w = nil
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
      pts[idx] = math.Vector(math.cos(theta)*0.15+0.5, tier/5, math.sin(theta)*0.15+0.5)
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

local function generate_logo_mesh(parent, material, resolution)
  local edge_funcs = {}
  for idx, edge in ipairs(make_column_edges()) do
    edge_funcs[idx] = ter_edge_dist_func(unpack(edge))
  end
  local ndivs = 4
  local dg = resolution / ndivs -- just assume no remainder
  local data = mc.mc_data_from_function(
    function() return 0.0 end, 
    resolution+1 -- need 1 voxel padding for reasons
  )
  local progress = add_2d_drawable(textbox, {
    x = 1280/2 - 400/2, y = 300, w = 400, h = 30, font_size = 30,
    color = {255,255,255,255},
    text = "Generating mesh", font = 'mono'
  })
  local partidx = 0
  for iz = 0, ndivs-1 do
    for iy = 0, ndivs-1 do
      for ix = 0, ndivs-1 do
        print(ix, iy, iz)
        local geo = gen_cell(data, ix, iy, iz, dg, edge_funcs)
        if geo then
          local mesh = parent:create_child(graphics.Mesh, "_logo_" .. partidx,
                                          geo, material)
          mesh.position:set(-0.5, -0.5, -0.5)
          mesh:update_matrix()
        end
        progress.text = ("Generating mesh [%03d / %03d]"):format(partidx, ndivs^3)
        partidx = partidx + 1
      end
    end
  end
  print("DONE?")
  progress.dead = true
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
  async.run(generate_logo_mesh, rotator, mat, 2^(options.detail)):next(nil, print)

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

local NVGThing = graphics.NanoVGComponent:extend("NVGThing")
function NVGThing:nvg_draw(ctx)
  ctx:load_font("font/FiraSans-Regular.ttf", "sans")
  ctx:load_font("font/FiraMono-Regular.ttf", "mono")
  draw_2d_drawables(ctx)
end

local gif_mode = false

function init()
  myapp = app.App{
    width = (gif_mode and 720) or 1280, height = 720, 
    msaa = true, stats = false,
    title = "truss | logo.t", clear_color = 0x000000ff
  }
  myapp.camera:add_component(orbitcam.OrbitControl{min_rad = 0.7, max_rad = 1.2})
  myapp.camera.orbit_control:set(0, 0, 0.7)
  local logo = myapp.scene:create_child(Logo, "logo", {detail = 8})
  logo.quaternion:euler({x = -math.pi/4, y = 0.2, z = 0}, 'ZYX')
  logo:update_matrix()

  myapp.scene:create_child(Stars, 'sky', {nstars = 30000})
  myapp.scene:create_child(ecs.Entity3d, "logotext", NVGThing())

  async.run(function()
    add_2d_drawable(textbox, {
      x = 10, y = 10, w = 400, h = 200,
      font_size = 200, text = 'truss'
    })
    async.await_frames(5)
    add_2d_drawable(textbox, {
      x = 390, y = 10, w = 220, h = 120,
      font_size = 100, text = '0.1.α'
    })
    if gif_mode then return end
    -- spawn caps
    local ypos = 5
    for capname, supported in pairs(gfx.get_caps().features) do
      local color = (supported and {200,255,200,255}) or {100,100,100,255}
      add_2d_drawable(textbox, {
        x = 1000, y = ypos, w = 250, h = 23, 
        font_size = 20, text = capname, color = color, font = 'mono'
      })
      ypos = ypos + 20
      async.await_frames(5)
    end
  end)
end

function update()
  if not gif_mode then
    myapp.camera.orbit_control:move_theta(math.pi * 2.0 / 120.0)
  end
  myapp:update()
end
