-- examples/vr_wandmouse.t
--
-- demonstrates how to use a wand as a mouse

local VRTrackingApp = require("vr/vrtrackingapp.t").VRTrackingApp
local geometry = require("geometry")
local pbr = require("shaders/pbr.t")
local graphics = require("graphics")
local orbitcam = require("gui/orbitcam.t")
local grid = require("graphics/grid.t")
local ecs = require("ecs")
local vrcomps = require("vr/components.t")
local math = require("math")

local App = VRTrackingApp:extend("App")
function App:init(options)
  App.super.init(self, options)
  self.mice = {}
end

function App:keydown(evtname, evt)
  if evt.keyname == "F12" then
    print("Saving screenshot!")
    gfx.save_screenshot("screenshot.png")
  elseif evt.keyname == "F1" then
    self:capture_calib_point(1)
  elseif evt.keyname == "F2" then
    self:capture_calib_point(2)
  elseif evt.keyname == "F3" then
    self:capture_calib_point(3)
  elseif evt.keyname == "F4" then
    self:recompute_calib()
  end
end

function App:capture_calib_point(n)
  if self.calib_target then
    self.calib_points[n] = self.calib_target.matrix_world:get_translation()
    print("Got calib point: " .. tostring(self.calib_points[n]))
  end
end

function App:recompute_calib()
  local x = self.calib_points[2] - self.calib_points[1]
  local y = self.calib_points[3] - self.calib_points[1]
  self.calib_scale = 1.0 / y:length3()
  local z = math.Vector():cross(x, y):normalize3()
  x:cross(y, z):normalize3()
  y:cross(z, x):normalize3()
  x.elem.w = 0
  y.elem.w = 0
  z.elem.w = 0
  self.calib_points[1].elem.w = 1
  self.calib_mat = math.Matrix4():from_basis{x, y, z, self.calib_points[1]}
  if self.calib_marker then
    self.calib_marker.matrix:copy(self.calib_mat)
  end
  self.calib_mat:invert()
end

local p0, p1 = math.Vector(), math.Vector()
function App:project_cursor(src_mat, fix_center, fix_distance)
  src_mat:get_translation(p0)
  src_mat:get_column(3, p1)
  p0.elem.w = 1.0 -- position like
  p1.elem.w = 0.0 -- vector   like
  -- transform into calibrated space, 
  -- mouse plane is oriented x,y facing +z
  self.calib_mat:multiply(p0) 
  self.calib_mat:multiply(p1)
  if fix_center then
    p0.elem.x, p0.elem.y = 0, 0
  end
  if fix_distance then
    p0.elem.z = 1.0
  end

  -- print("d: " .. tostring(p1))
  -- print("p: " .. tostring(p0))

  local t = p0.elem.z / p1.elem.z
  local x = p0.elem.x - (t * p1.elem.x)
  local y = p0.elem.y - (t * p1.elem.y)
  return x, y
end

function App:add_controller(trackable)
  if trackable.device_class_name ~= "Controller" then
    return
  end

  local geo = geometry.icosphere_geo{radius = 0.02, detail = 1}
  local mat = pbr.FacetedPBRMaterial({0.03,0.03,0.03,1.0},
                                     {0.001, 0.001, 0.001}, 0.7)
  
  local controller = self.ECS.scene:create_child(ecs.Entity3d, "controller")
  controller:add_component(vrcomps.VRControllerComponent(trackable))
  controller.vr_controller:create_mesh_parts(geo, mat)

  local extrageo = geometry.axis_widget_geo{scale = 0.1}
  local extramat = pbr.FacetedPBRMaterial({0.2, 0.03, 0.01, 1.0}, {0.001, 0.001, 0.001}, 0.7)
  controller:create_child(graphics.Mesh, "axis", extrageo, extramat)
  -- controller.vr_controller:enable_events(true)

  -- controller:on("controller_axis", self, self.axis_event)
  -- controller:on("controller_button", self, self.button_event)

  -- first controller
  self.calib_target = self.calib_target or controller
  table.insert(self.controllers, controller)
  controller.vr_controller.mouse_id = #(self.controllers)

  self.calib_points = {math.Vector(0, 0, 0), 
                       math.Vector(1, 0, 0), 
                       math.Vector(0, 1, 0)}
  self:recompute_calib()
end

function App:update()
  App.super.update(self)
  for idx, controller in ipairs(self.controllers) do
    self.mice[idx] = self.mice[idx] or {x = 0, y = 0}
    local m = self.mice[idx]
    m.x, m.y = self:project_cursor(controller.matrix_world, false, false)
    if self.world_cursor then
      self.world_cursor.position:set(m.x, m.y, 0.0)
      self.world_cursor:update_matrix()
    end
    m.x = m.x * self.calib_scale
    m.y = m.y * self.calib_scale
  end
end

-- function App:axis_event(evtname, evt)
-- end

-- function App:button_event(evtname, evt)
-- end

function nanovg_setup(stage, ctx)
  ctx.bg_color = ctx:RGBAf(0.0, 0.0, 0.0, 0.5) -- semi-transparent black
  ctx.font_color = ctx:RGBf(1.0, 1.0, 1.0)     -- white
  ctx:load_font("font/VeraMono.ttf", "sans")
  ctx.mouse_colors = {
    ctx:RGBf(1.0, 0.5, 0.5), ctx:RGBf(0.5, 1.0, 0.5),
    ctx:RGBf(0.5, 0.5, 1.0), ctx:RGBf(1.0, 1.0, 0.5)
  }
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
  if not app then return end
  for i, mouse in ipairs(app.mice) do
    local x, y = mouse.x, mouse.y
    x = (x + 1) * (ctx.width / 2)
    y = (-y + 1) * (ctx.height / 2)
    ctx:BeginPath()
    ctx:Circle(x, y, 20)
    ctx:FillColor(ctx.mouse_colors[i])
    ctx:Fill()
  end
end

function init()
  app = App{title = "vr (tracking only, no hmd)", 
            width = 1280, height = 720,
            msaa = true, stats = true, 
            clear_color = 0x404080ff, lowlatency = true,
            nvg_setup = nanovg_setup, nvg_render = nanovg_render}
  app.camera:add_component(orbitcam.OrbitControl({min_rad = 1, max_rad = 4}))

  local geo = geometry.axis_widget_geo{scale = 0.1}
  local mat = pbr.FacetedPBRMaterial({0.2, 0.03, 0.01, 1.0}, {0.001, 0.001, 0.001}, 0.7)
  box = app.scene:create_child(graphics.Mesh, "box", geo, mat)
  app.calib_marker = box

  local sgeo = geometry.icosphere_geo{radius = 0.02, detail = 1}
  local smat = pbr.FacetedPBRMaterial({0.03,0.03,0.03,1.0},
                                     {0.001, 0.001, 0.001}, 0.7)
  local world_cursor = box:create_child(graphics.Mesh, "cursor", sgeo, smat)
  app.world_cursor = world_cursor

  lines = app.scene:create_child(grid.Grid, {thickness = 0.01, 
                                                color = {0.5, 0.2, 0.2}})
  lines.position:set(0.0, -1.0, 0.0)
  lines.quaternion:euler({x = math.pi / 2.0, y = 0.0, z = 0.0})
  lines:update_matrix()
end

function update()
  app:update()
end
