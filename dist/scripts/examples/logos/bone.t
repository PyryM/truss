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
local math = require("math")
local tmath = require("math/tmath.t")
local cmath = require("math/cmath.t")
local ecs = require("ecs")
local async = require("async")
local class = require("class")
local imgui = require("imgui")
local common = require("examples/logos/logocommon.t")

local MarchMat = gfx.define_base_material{
  name = "MarchMat",
  program = {"vs_logo_bone_raymarch", "fs_logo_bone_raymarch"},
  uniforms = {
    u_marchParams = 'vec', 
    u_scaleParams = 'vec',
    u_invModel = 'mat4',
    u_timeParams = 'vec',
    u_lightDir = 'vec',
    s_volume = {kind = 'tex', sampler = 0, flags = {u = 'clamp', v = 'clamp', w = 'clamp'}}
  }, 
  state = {}
}

local terra sphere_sdf(oldval: float, x: float, y: float, z: float): float
  x = x - 0.5
  y = y - 0.5
  z = z - 0.5
  var vlength = cmath.sqrt((x*x) + (y*y) + (z*z))
  return vlength - 0.4
end

local function sphere_diff(x0, y0, z0, rad)
  local terra diff_sdf(oldval: float, x: float, y: float, z: float): float
    x = x - 0.5
    y = y - 0.5
    z = z - 0.5
    var dx = x - x0
    var dy = y - y0
    var dz = z - z0
    var vlength = cmath.sqrt((dx*dx) + (dy*dy) + (dz*dz))
    var sdfval: float = vlength - rad
    return cmath.fmax(oldval, -sdfval)
  end
  return diff_sdf
end

local function ter_edge_dist_func(p0, p1)
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

local function gen_sdf(funclist, databuff, res, mult, offset)
  local RES = assert(res)
  local OFFSET = offset or 0.0
  local MULT = mult or 255.0
  local terra gen(dest: &uint8)
    var dpos: uint32 = 0
    for z = 0, RES do
      for y = 0, RES do
        for x = 0, RES do
          var fx = [float](x) / RES
          var fy = [float](y) / RES
          var fz = [float](z) / RES
          var val: float = 0.0
          escape
            for _, f in ipairs(funclist) do
              emit(quote
                val = f(val, fx, fy, fz) 
              end)
            end
          end
          var ival: int32 = (val + OFFSET) * MULT
          if ival < 0 then ival = 0 end
          if ival > 255 then ival = 255 end
          dest[dpos] = ival
          dpos = dpos + 1
        end
      end
    end
  end
  gen(databuff)
end

local function generate_logo_3d_tex(resolution)
  --[[
  local edge_funcs = {}
  for idx, edge in ipairs(common.make_logo_column_edges()) do
    edge_funcs[idx] = ter_edge_dist_func(unpack(edge))
  end
  ]]
  local edge_funcs = {sphere_sdf}
  for i = 1, 10 do
    local cx = math.random()-0.5
    local cy = math.random()-0.5
    local cz = math.random()-0.5
    local rad = math.random()*0.2 + 0.05
    table.insert(edge_funcs, sphere_diff(cx, cy, cz, rad))
  end

  local sdftex = gfx.Texture3d{
    width = resolution, height = resolution, depth = resolution, 
    format = gfx.TEX_R8, allocate = true, dynamic = false
  }

  gen_sdf(edge_funcs, sdftex.cdata, resolution, 255.0, 0.5)

  sdftex:commit()
  return sdftex
end

local function Logo(_ecs, name, options)
  local geo = geometry.off_center_cube_geo{
    sx = 1.0, 
    sy = 1.0,
    sz = 1.0
  }

  local tex3d = generate_logo_3d_tex(options.resolution or 128)
  local inv_model_mat = math.Matrix4():identity()

  local mat = MarchMat{
    s_volume = tex3d,
    u_marchParams = {0.002, 0.5, 0.0, 0.0},
    u_scaleParams = {1.0, 1.0, 1.0, 1.0},
    u_timeParams = {0.0, 0.0, 0.0, 0.0},
    u_lightDir = {1.0, 0.0, 0.0, 0.0},
    u_invModel = inv_model_mat,
  }

  local logo = graphics.Mesh(_ecs, "cube3", geo, mat)

  logo:add_component(ecs.UpdateComponent(function(self)
    self.f = (self.f or 0) + 1
    local lx = math.cos(self.f / 120)
    local ly = math.sin(self.f / 120)
    inv_model_mat:invert(self.ent.matrix_world)
    mat.uniforms.u_invModel:set(inv_model_mat)
    mat.uniforms.u_lightDir:set(lx, 0.0, ly, 0.0)
  end))

  return logo
end

local gif_mode = false
local imgui_open = terralib.new(bool[1])
imgui_open[0] = false
local dbstate = nil

function init()
  myapp = app.App{
    width = (gif_mode and 720) or 1280, height = 720, 
    msaa = true, hidpi = true, stats = false, imgui = true,
    title = "truss | logos/bone.t", clear_color = 0x000000ff,
  }

  local db_builder = imgui.DatabarBuilder{
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

  myapp.camera:add_component(orbitcam.OrbitControl{min_rad = 1.2, max_rad = 3.0})
  myapp.camera.orbit_control:set(0, 0, 1.2)
  local logo = myapp.scene:create_child(Logo, "logo", {resolution = 128})
  logo.position:set(-0.5, -0.5, -0.5)
  --logo.quaternion:euler({x = -math.pi/4, y = 0.2, z = 0}, 'ZYX')
  logo:update_matrix()

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
