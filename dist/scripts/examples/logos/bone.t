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
  var vlength = cmath.sqrt((x*x) + (y*y) + (z*z))
  return vlength - 0.8
end

local function sphere_diff(x0, y0, z0, rad)
  local terra diff_sdf(oldval: float, x: float, y: float, z: float): float
    var dx = x - x0
    var dy = y - y0
    var dz = z - z0
    var vlength = cmath.sqrt((dx*dx) + (dy*dy) + (dz*dz))
    var sdfval: float = vlength - rad
    return cmath.fmax(oldval, -sdfval)
  end
  return diff_sdf
end

local terra clamp(v: float, minv: float, maxv: float): float
  if v < minv then return minv elseif v > maxv then return maxv end
  return v
end

local terra mix(x: float, y: float, a: float): float
  return x + a*(y-x)
end

local terra soft_union(d1: float, d2: float, k: float): float
  var h = clamp(0.5 + 0.5*(d2-d1)/k, 0.0, 1.0)
  return mix(d2, d1, h) - k*h*(1.0-h)
end

local function softmax_capsule(p0, p1, rad, k)
  local V3 = tmath.Vec3f
  local ax, ay, az = unpack(p0:to_array())
  local bx, by, bz = unpack(p1:to_array())

  return terra(oldval: float, x: float, y: float, z: float): float
    --vec3 pa = p - a, ba = b - a;
    var pa: V3
    pa:set(x - ax, y - ay, z - az)
    var ba: V3
    ba:set(bx - ax, by - ay, bz - az) 
    --float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    var h: float = pa:dot(&ba) / ba:dot(&ba)
    if h < 0.0 then h = 0.0 elseif h > 1.0 then h = 1.0 end
    var distvec: V3 = pa - (ba * h)
    var newdist: float = distvec:length() - rad
    --return cmath.fmin(oldval, newdist)
    return soft_union(oldval, newdist, k)
  end
end

local function gen_sdf(funclist, databuff, res, mult, offset, cb)
  local RES = assert(res)
  local OFFSET = offset or 0.0
  local MULT = mult or 255.0
  local terra gen(dest: &uint8, z: uint32)
    var dpos: uint32 = RES*RES*z
    for y = 0, RES do
      for x = 0, RES do
        var fx = [float](x) / RES
        var fy = [float](y) / RES
        var fz = [float](z) / RES
        var val: float = 10000.0
        escape
          for _, f in ipairs(funclist) do
            emit(quote
              val = f(val, fx, fy, fz) 
            end)
          end
        end
        --val = val * 0.5
        var ival: int32 = (val + OFFSET) * MULT
        if ival < 0 then ival = 0 end
        if ival > 255 then ival = 255 end
        dest[dpos] = ival
        dpos = dpos + 1
      end
    end
  end
  for z = 0, RES-1 do
    gen(databuff, z)
    if cb then cb(z, RES-1) end
  end
end

local function generate_logo_3d_tex(resolution, cb)
  local edge_funcs = {}
  for idx, edge in ipairs(common.make_logo_column_edges()) do
    --if idx > 1 then break end
    edge_funcs[idx] = softmax_capsule(edge[1], edge[2], 0.025, 0.03)
  end
  print(#edge_funcs)

  local sdftex = gfx.Texture3d{
    width = resolution, height = resolution, depth = resolution, 
    format = gfx.TEX_R8, allocate = true, dynamic = false
  }

  gen_sdf(edge_funcs, sdftex.cdata, resolution, 255.0, 0.5, cb)

  log.info("sdftex size: " .. sdftex.cdatasize)
  sdftex:commit()
  return sdftex
end

local function Logo(_ecs, name, options)
  local state = options.state or {
    rotate_model = true, thresh = 0.5,
    step = 0.002, normstep = 0.01,
    light_size = 45, light_power = 1.0,
    num_rays = 8
  }

  local parent = ecs.Entity3d(_ecs, name)
  local rotator = parent:create_child(ecs.Entity3d, "rotator")

  local geo = geometry.off_center_cube_geo{
    sx = 1.0, 
    sy = 1.0,
    sz = 1.0
  }

  local inv_model_mat = math.Matrix4():identity()

  local mat = MarchMat{
    s_volume = assert(options.sdf_tex),
    u_marchParams = {0.002, 0.5, 0.01, -1},
    u_scaleParams = {1.0, 1.0, 1.0, 1.0},
    u_timeParams = {0.0, 0.0, 0.0, 0.0},
    u_lightDir = {1.0, 0.0, 0.0, 0.0},
    u_invModel = inv_model_mat,
  }

  rotator:add_component(ecs.UpdateComponent(function(self)
    self.f = (self.f or 0)
    if state.rotate_model then self.f = self.f + 1 end
    self.ent.quaternion:euler{x = 0, y = self.f/120, z = 0}
    self.ent:update_matrix()
  end))

  local logo = rotator:create_child(graphics.Mesh, "cube3", geo, mat)

  logo:add_component(ecs.UpdateComponent(function(self)
    self.f = (self.f or 0) + 1
    if state.static_noise then self.f = 0 end
    local lightthresh = math.cos(math.pi * state.light_size/180.0)
    mat.uniforms.u_timeParams:set((self.f % 999) / 999999, state.num_rays)
    mat.uniforms.u_marchParams:set(
      state.step, state.thresh, state.normstep, lightthresh
    )
    mat.uniforms.u_scaleParams:set(1, 1, 1, state.light_power)
  end))

  logo._post_transform = function(ent, matrix_world)
    inv_model_mat:invert(matrix_world)
    mat.uniforms.u_invModel:set(inv_model_mat)
  end

  logo.position:set(-0.5, -0.5, -0.5)
  logo:update_matrix()

  return parent
end

local gif_mode = false
local imgui_open = terralib.new(bool[1])
imgui_open[0] = false
local dbstate = nil

function init()
  local IG_COLORS = {
    0x202020ff, -- text
    0xffffffff, -- bg
    0x808080ff, -- accent 1
    0xd08080ff  -- accent 2
  }
  -- local IG_COLORS = {
  --   0xffffffff, -- text
  --   0x072e30ff, -- bg
  --   0x44e9e6ff, -- accent 1
  --   0x44e9e6ff  -- accent 2
  -- }

  myapp = app.App{
    width = (gif_mode and 720) or 1280, height = 720, 
    msaa = false, hidpi = false, stats = false, imgui = {colors = IG_COLORS},
    title = "truss | logos/bone.t", clear_color = 0xddddddff,
    backend = "vulkan"
  }

  local db_builder = imgui.DatabarBuilder{
    title = "Settings",
    width = 400, height = 680,
    x = 1280 - 420, y = 20,
    open = true, allow_close = true
  }
  db_builder:field{"logo_progress", "progress"}
  db_builder:field{"rotate_view", "bool", default = true}
  db_builder:field{"rotate_model", "bool", default = true}
  db_builder:field{"view_speed", "float", limits={0, 10.0}, default=1.0}
  db_builder:field{"thresh", "float", limits={0.48,0.8}, default=0.522,
    tooltip="SDF surface level"}
  db_builder:field{"light_size", "float", limits={0, 180}, format="%.1f deg",
    default=57, tooltip="area light size (cone half-angle)"}
  db_builder:field{"light_power", "float", limits={0, 10}, default=1.3,
    tooltip="multiply light strength"}
  db_builder:field{"num_rays", "int", limits={1, 32}, default=8,
    tooltip="how many rays to cast for ambient occlusiion"}
  db_builder:field{"step", "float", limits={0.001, 0.1}, default=0.005,
    tooltip="raymarch minimum step size"}
  db_builder:field{"normstep", "float", limits={0.001, 0.1}, default=0.001,
    tooltip="how far to step in SDF to estimate normals"}
  db_builder:field{"static_noise", "bool", default=false}

  db_builder:field{"divider"}
  db_builder:field{"show_demo", "button", label="Show IMGUI demo!"}
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

  myapp.camera:add_component(orbitcam.OrbitControl{min_rad = 0.8, max_rad = 3.0})
  myapp.camera.orbit_control:set(0, 0, 1.0)

  async.run(function()
    local tex3d = generate_logo_3d_tex(128, function(z, zmax)
      dbstate.logo_progress = z/zmax
      async.await_frames(1)
    end)
    local logo = myapp.scene:create_child(Logo, "logo", {
      sdf_tex = tex3d, state = dbstate
    })
    logo.quaternion:euler({x = -math.pi/4, y = 0.2, z = 0}, 'ZYX')
    logo:update_matrix()
  end):next(nil, print)

  myapp.scene:create_child(ecs.Entity3d, "logotext", common.NVGDrawer())

  async.run(function()
    local logocolor = {50, 50, 50, 200}
    common.add_textbox{
      x = 10, y = 10, w = 400, h = 200,
      font_size = 200, text = 'truss', color = logocolor
    }
    async.await_frames(5)
    common.add_textbox{
      x = 390, y = 10, w = 220, h = 120, color = logocolor,
      font_size = 100, text = "0.2.α" -- truss.BIN_VERSION
    }
  end)
end

function update()
  if dbstate.rotate_view and not gif_mode then
    myapp.camera.orbit_control:move_theta(dbstate.view_speed * math.pi * 2.0 / 120.0)
  end
  myapp:update()
end
