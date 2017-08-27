local app = require("app/app.t")
local geometry = require("geometry")
local pbr = require("shaders/pbr.t")
local graphics = require("graphics")
local orbitcam = require("gui/orbitcam.t")
local grid = require("graphics/grid.t")

function nanovg_setup(stage, ctx)
  ctx.bg_color = ctx:RGBAf(0.0, 0.0, 0.0, 0.5) -- semi-transparent black
  ctx.font_color = ctx:RGBf(1.0, 1.0, 1.0)     -- white
  ctx:load_font("font/VeraMono.ttf", "sans")
end

local FONT_SIZE = 40
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

function nanovg_render(stage, ctx)
  rounded_text(ctx, 70, 50, "NanoVG: Initialized")
  local ocam = myapp.camera.orbit_control
  local tstr = string.format("theta = % .4f", ocam.theta)
  local pstr = string.format("phi   = % .4f", ocam.phi)
  local rstr = string.format("rad   = % .4f", ocam.rad)
  rounded_text(ctx, 70, 50 + FONT_SIZE*1.1, tstr)
  rounded_text(ctx, 70, 50 + 2*FONT_SIZE*1.1, pstr)
  rounded_text(ctx, 70, 50 + 3*FONT_SIZE*1.1, rstr)
end

function init()
  myapp = app.App{title = "nanovg example", width = 1280, height = 720,
                  msaa = true, stats = false, clear_color = 0x404080ff,
                  nvg_setup = nanovg_setup, nvg_render = nanovg_render}

  myapp.camera:add_component(orbitcam.OrbitControl({min_rad = 1, max_rad = 4}))

  local geo = geometry.icosphere_geo(1.0, 1)
  local mat = pbr.FacetedPBRMaterial({0.2, 0.03, 0.01, 1.0}, {0.001, 0.001, 0.001}, 0.7)
  mymesh = myapp.scene:create_child(graphics.Mesh, "mymesh", geo, mat)
  mygrid = myapp.scene:create_child(grid.Grid, {thickness = 0.02, 
                                                color = {0.5, 0.5, 0.5}})
  mygrid.position:set(0.0, -1.0, 0.0)
  mygrid.quaternion:euler({x = math.pi / 2.0, y = 0.0, z = 0.0})
  mygrid:update_matrix()
end

function update()
  myapp:update()
end
