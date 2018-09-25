local app = require("app/app.t")
local geometry = require("geometry")
local pbr = require("material/pbr.t")
local graphics = require("graphics")
local orbitcam = require("gui/orbitcam.t")
local grid = require("graphics/grid.t")
local ecs = require("ecs")

local FONT_SIZE = 20
local FONT_X_MARGIN = 5
local FONT_Y_MARGIN = 8

-- Draw text with a rounded-rectangle background
local function rounded_text(ctx, x, y, text)
  local tw = #text * FONT_SIZE * 0.55
  local th = FONT_SIZE
  ctx:BeginPath()
  ctx:RoundedRect(x, y, tw, th, 3)
  ctx:FillColor(ctx.bg_color)
  ctx:Fill()

  ctx:FontFace("sans")
  ctx:FontSize(FONT_SIZE)
  ctx:FillColor(ctx.font_color)
  ctx:TextAlign(ctx.ALIGN_MIDDLE)
  ctx:Text(x, y + th/2, text, nil)
end

local lowlatency = true
local mouse_state = {x = 0, y = 0}
function on_mouse(mstate, evtname, evt)
  mstate.x, mstate.y = evt.x, evt.y
end

local NVGThing = graphics.NanoVGComponent:extend("NVGThing")
function NVGThing:nvg_setup(ctx)
  ctx.bg_color = ctx:RGBAf(0.0, 0.0, 0.0, 0.5) -- semi-transparent black
  ctx.font_color = ctx:RGBf(1.0, 1.0, 1.0)     -- white
  ctx:load_font("font/VeraMono.ttf", "sans")

  ctx.test_image = ctx:load_image("textures/bad_green_cursor.png")
  print("Test image size: ", ctx.test_image.w, ctx.test_image.h)
end

function NVGThing:nvg_draw(ctx)
  local t = "SDL + vsync"
  if lowlatency then
    t = t .. " + BGFX Single-Threaded"
  else
    t = t .. " + BGFX Multi-Threaded"
  end
  rounded_text(ctx, 10, 10, t)
  local ocam = myapp.camera.orbit_control
  local tstr = string.format("theta = % .4f", ocam.theta)
  local pstr = string.format("phi   = % .4f", ocam.phi)
  local rstr = string.format("rad   = % .4f", ocam.rad)
  rounded_text(ctx, 70, 50 + FONT_SIZE*1.1, tstr)
  rounded_text(ctx, 70, 50 + 2*FONT_SIZE*1.1, pstr)
  rounded_text(ctx, 70, 50 + 3*FONT_SIZE*1.1, rstr)
  ctx:Image(ctx.test_image, mouse_state.x, mouse_state.y, 60, 60)
  ctx:BeginPath()
  ctx:Circle(mouse_state.x, mouse_state.y, 3)
  ctx:FillColor(ctx:RGB(255, 255, 255))
  ctx:Fill()
  ctx:BeginPath()
  ctx:Circle(mouse_state.x, mouse_state.y, 10)
  ctx:StrokeColor(ctx:RGB(255, 255, 255))
  ctx:StrokeWidth(2)
  ctx:Stroke()
end

function init()
  myapp = app.App{title = "nanovg example", width = 640, height = 480,
                  msaa = true, stats = false, clear_color = 0x404080ff,
                  lowlatency = lowlatency}

  myapp.ECS.systems.input:on("mousemove", mouse_state, on_mouse)
  myapp.camera:add_component(orbitcam.OrbitControl({min_rad = 1, max_rad = 4}))

  local geo = geometry.icosphere_geo{radius = 1, detail = 1}
  local mat = pbr.FacetedPBRMaterial{diffuse = {0.2, 0.03, 0.01, 1.0}, 
                                     tint = {0.001, 0.001, 0.001}, 
                                     roughness = 0.7}
  mymesh = myapp.scene:create_child(graphics.Mesh, "mymesh", geo, mat)
  mygrid = myapp.scene:create_child(grid.Grid, "grid", {thickness = 0.02, 
                                                color = {0.5, 0.5, 0.5}})
  mygrid.position:set(0.0, -1.0, 0.0)
  mygrid.quaternion:euler({x = math.pi / 2.0, y = 0.0, z = 0.0})
  mygrid:update_matrix()

  myapp.scene:create_child(ecs.Entity3d, "nvg_draw_thing", NVGThing())
end

function update()
  myapp:update()
end
