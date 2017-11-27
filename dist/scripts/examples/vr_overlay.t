local app = require("vr/vroverlayapp.t")
local geometry = require("geometry")
local pbr = require("shaders/pbr.t")
local graphics = require("graphics")
local orbitcam = require("gui/orbitcam.t")
local grid = require("graphics/grid.t")
local math = require("math")

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

local t = 0.0
function nanovg_render(stage, ctx)
  rounded_text(ctx, 70, 50, "truss overlay")
  local tstr = string.format("time  = % .4f", t)
  local pstr = string.format("rand  = % .4f", math.random())
  local rstr = string.format("const = % .4f", 3.1415926)
  rounded_text(ctx, 70, 50 + FONT_SIZE*1.1, tstr)
  rounded_text(ctx, 70, 50 + 2*FONT_SIZE*1.1, pstr)
  rounded_text(ctx, 70, 50 + 3*FONT_SIZE*1.1, rstr)
end

function init()
  myapp = app.VROverlayApp{title = "nanovg example", width = 512, height = 512,
                           msaa = true, stats = false, clear_color = 0x00000000,
                           nvg_setup = nanovg_setup, nvg_render = nanovg_render}

  local tf = math.Matrix4():compose(math.Vector(0.0, 0.0, -1.0), 
                                    math.Quaternion():identity())
  myapp.overlay:set_relative_transform(tf, 0) -- put overlay relative to head?
  myapp.overlay:set_width(0.5)
  myapp.overlay:set_visible(true)
end

function update()
  t = t + 1.0 / 60.0
  myapp:update()
end
