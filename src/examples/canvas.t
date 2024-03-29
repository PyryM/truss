local app = require("app/app.t")
local geometry = require("geometry")
local pbr = require("material/pbr.t")
local flat = require("material/flat.t")
local graphics = require("graphics")
local orbitcam = require("graphics/orbitcam.t")
local grid = require("graphics/grid.t")
local gfx = require("gfx")

local myapp

local function context_setup(ctx)
  if ctx.setup_complete then return end
  ctx.bg_color = ctx:RGBf(0.5, 0.5, 0.5)   -- gray
  ctx.font_color = ctx:RGBf(1.0, 1.0, 1.0) -- white
  ctx:load_font("font/VeraMono.ttf", "sans")
  ctx.setup_complete = true
end

-- Draw text with a rounded-rectangle background
local function draw_rounded_label(component, ctx)
  context_setup(ctx)
  local FONT_SIZE = 64
  local FONT_X_MARGIN = 5
  local FONT_Y_MARGIN = 8

  local w, h = ctx.width, ctx.height
  ctx:BeginPath()
  ctx:RoundedRect(0, 0, w, h, 10)
  ctx:FillColor(ctx.bg_color)
  ctx:Fill()

  ctx:FontFace("sans")
  ctx:FontSize(FONT_SIZE)
  ctx:FillColor(ctx.font_color)
  ctx:Text(FONT_X_MARGIN, h - FONT_Y_MARGIN, component.text, nil)
end

local label_geo = nil
local function Label(_ecs, name, options)
  options = options or {}
  if not label_geo then
    label_geo = geometry.plane_geo{width = 1.0, height = 0.25}
  end
  local canvas = graphics.CanvasComponent{width = options.width or 256, 
                                          height = options.height or 64}
  local mat = flat.FlatMaterial{
    texture = canvas:get_tex(), 
    color = {1.0, 1.0, 1.0, 1.0},
    state = gfx.State{cull = false}
  }
  local ret = graphics.Mesh(_ecs, name, label_geo, mat)
  ret:add_component(canvas)
  canvas.text = options.text or name or "Hello World??"
  canvas:submit_draw(draw_rounded_label)
  return ret
end

local function init()
  myapp = app.App{title = "canvas example", width = 1280, height = 720,
                  msaa = true, stats = false, clear_color = 0x404080ff,
                  num_workers = 3}
  myapp.camera:add_component(orbitcam.OrbitControl{min_rad = 1, max_rad = 4})

  for i = 1,7 do
    local label = myapp.scene:create_child(Label, "hello_" .. i)
    label.position:set(0.0, 0.3*i - 1, 0.0)
    label.quaternion:euler{x = 0, y = math.pi/2, z = 0}
    label:update_matrix()
  end
  
  local mygrid = myapp.scene:create_child(grid.Grid, "grid", {thickness = 0.02, 
                                                color = {0.5, 0.5, 0.5}})
  mygrid.position:set(0.0, -1.0, 0.0)
  mygrid.quaternion:euler{x = math.pi / 2.0, y = 0.0, z = 0.0}
  mygrid:update_matrix()
end

local function update()
  myapp:update()
end

return {init = init, update = update}
