-- vr_fov.t
--
-- fov testing

local gfx = require("gfx")
local math = require("math")
local ecs = require("ecs")
local graphics = require("graphics")
local geometry = require("geometry")
local grid = require("graphics/grid.t")

local VRApp = require("vr/vrapp.t").VRApp
local openvr = require("vr/openvr.t")
local vrcomps = require("vr/components.t")

local pbr = require("material/pbr.t")
local flat = require("material/flat.t")

function init()
  app = VRApp({title = "vr fov testing", nvg = false,
               mirror = "both", stats = true, 
               create_controllers = true})
  create_scene(app.ECS.scene)
end

function update()
  app:update()
end

----------------------------------------------------------------------------
--- FOV Sphere
----------------------------------------------------------------------------

function create_fov_sphere_geo()
  local sphere_to_cartesian = require("geometry/uvsphere.t").sphere_to_cartesian
  return geometry.uvsphere_geo{
    lat_divs = 60, lon_divs = 60, cap_size = 0.001,
    projfunc = function(lat, lon)
      local x, y, _ = sphere_to_cartesian(lat, lon, 0.5001)
      return 0.5-x, 0.5-y
    end
  }
end

local function draw_fov_rings(component, ctx)
  ctx:load_font("font/FiraMono-Regular.ttf", "sans")

  local FONT_SIZE = 24
  local FONT_X_MARGIN = 5
  local FONT_Y_MARGIN = 8

  local w, h = ctx.width, ctx.height
  local cx, cy = w/2, h/2

  for theta_degrees = 0, 150, 5 do
    local theta = math.pi * theta_degrees / 180.0
    local rad = math.sin(theta/2) * (w/2)

    ctx:BeginPath()
    ctx:Circle(cx, cy, rad)
    if theta_degrees % 15 == 0 then
      ctx:StrokeWidth(3.0)
      ctx:StrokeColor(ctx:RGB(255,255,255))
    else
      ctx:StrokeWidth(1.5)
      ctx:StrokeColor(ctx:RGB(128,128,128))
    end
    ctx:Stroke()

    if theta_degrees % 30 == 0 then
      ctx:FontFace("sans")
      ctx:TextAlign(ctx.ALIGN_MIDDLE + ctx.ALIGN_CENTER)
      ctx:FontSize(FONT_SIZE)

      local x, y = cx+rad, cy
      local text = tostring(theta_degrees)
      ctx:FontBlur(6.0)
      ctx:FillColor(ctx:RGB(0, 0, 0))
      ctx:Text(x, y, text, nil)
      ctx:Text(x, y, text, nil)
      ctx:Text(x, y, text, nil)
      ctx:Text(x, y, text, nil)
      ctx:Text(x, y, text, nil)
      ctx:FontBlur(0.0)
      ctx:FillColor(ctx:RGB(255, 255, 255))
      ctx:Text(x, y, text, nil)
    end
  end
end

function FOVRingSphere(_ecs, name, options)
  options = options or {}
  local geo = create_fov_sphere_geo()
  local canvas = graphics.CanvasComponent{width = 1024, height = 1024}
  local mat = flat.FlatMaterial{
    texture = canvas:get_tex(), 
    color = {1.0, 1.0, 1.0, 1.0}
  }
  local ret = graphics.Mesh(_ecs, name, geo, mat)
  ret:add_component(canvas)
  canvas:submit_draw(draw_fov_rings)
  ret.scale:set(-1, -1, -1)
  ret.quaternion:euler({x = 0.0, y = math.pi, z = 0.0})
  ret:update_matrix()
  return ret
end

----------------------------------------------------------------------------
--- Scene setup
----------------------------------------------------------------------------

-- create a big red ball so that there's something to see at least
function create_scene(root)
  local geo = geometry.icosphere_geo{detail = 3}
  local mat = pbr.FacetedPBRMaterial{diffuse = {0.2,0.03,0.01,1.0},
                                    tint = {0.001, 0.001, 0.001}, 
                                    roughness = 0.7}

  local thegrid = root:create_child(grid.Grid, "grid", 
                                    {spacing = 0.5, numlines = 8,
                                     color = {0.8, 0.8, 0.8}, 
                                     thickness = 0.003})
  thegrid.quaternion:euler({x = -math.pi / 2.0, y = 0, z = 0}, 'ZYX')
  thegrid:update_matrix()

  local axis_geo = geometry.axis_widget_geo{}
  local m2 = root:create_child(graphics.Mesh, "axis0", axis_geo, mat)
  m2.position:set(0.0, 1.0, 0.0)
  m2.scale:set(0.1, 0.1, 0.1)
  m2:update_matrix()

  local target = root:create_child(FOVRingSphere, "calibsphere")
  target.position:set(0.0, 1.0, 0.0)
  target:update_matrix()
end