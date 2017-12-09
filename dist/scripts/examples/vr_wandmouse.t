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
local miniscript = require("utils/miniscript.t")
local wandui = require("vr/wandui.t")
local config = require("utils/config.t")

local App = VRTrackingApp:extend("App")
function App:init(options)
  self.calib_file = config.Config{
      appname = "vive_mouse_calib", 
      use_global_save_dir = false,
      defaults = {
        origin = {0, 0, 0},
        right  = {1, 0, 0},
        up     = {0, 1, 0}
      }
    }:load()
  App.super.init(self, options)
  self.mice = {}
  self.calib_points = {math.Vector():from_array(self.calib_file.origin), 
                       math.Vector():from_array(self.calib_file.right), 
                       math.Vector():from_array(self.calib_file.up)}
  self:recompute_calib()
  self.uis = {}
end

function App:keydown(evtname, evt)
  if evt.keyname == "F12" then
    print("Saving screenshot!")
    gfx.save_screenshot("screenshot.png")
  elseif evt.keyname == "F1" then
    self:begin_calib()
  elseif evt.keyname == "F5" then
    print("Saving calibration")
    self:save_calib()
  end
end

function App:save_calib()
  self.calib_file.origin = self.calib_points[1]:to_array()
  self.calib_file.right  = self.calib_points[2]:to_array()
  self.calib_file.up     = self.calib_points[3]:to_array()
  self.calib_file:save()
end

function App:begin_calib()
  local controller = self.calib_target
  if not controller then return end

  print("Beginning calibration!")
  self.calib_func = miniscript.Miniscript(function(ctx)
    local ncaptured = 0
    local last_trigger = 0
    while ncaptured < 3 do
      local trigger = controller.vr_controller.axes.trigger1.x
      if trigger > 0.5 and last_trigger < 0.5 then
        ncaptured = ncaptured + 1
        self:capture_calib_point(ncaptured)
      end
      last_trigger = trigger
      ctx:wait()
    end
    self:recompute_calib()
    print("Calibration complete!")
  end)
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

  local t = p0.elem.z / p1.elem.z
  local x = p0.elem.x - (t * p1.elem.x)
  local y = p0.elem.y - (t * p1.elem.y)
  return x, y
end

local function ui_evt_loop(ctx, ui, userdata)
  while true do
    local evttype, evt = ctx:wait_event(1000)
    if evttype == "ui_button_down" then
      if evt.link then
        return evt.link(ctx, ui, userdata)
      else 
        print(evttype .. ": " .. evt.value)
      end
    end
  end
end

local ui_main, ui_subpanel1, ui_subpanel2

ui_main = function(ctx, ui, userdata)
  ui:clear()
  ui:button{text = "Panel 1", link = ui_subpanel1, 
            gx = 0, gy = 4, gw = 12, gh = 4}
  ui:button{text = "Panel 2", link = ui_subpanel2,
            gx = 0, gy = 8, gw = 12, gh = 4}
  return ui_evt_loop(ctx, ui, userdata)
end

ui_subpanel1 = function(ctx, ui, userdata)
  ui:clear()
  ui:button{text = "Back", link = ui_main, 
            gx = 0, gy = 0, gw = 4, gh = 3}
  ui:button{text = "P2", link = ui_subpanel2, 
            gx = 8, gy = 0, gw = 4, gh = 3}
  ui:button{text = "Banana", value = "banana",
            gx = 0, gy = 6, gw = 12, gh = 3}
  ui:button{text = "Orange", value = "orange",
            gx = 0, gy = 9, gw = 12, gh = 3}
  return ui_evt_loop(ctx, ui, userdata)
end

ui_subpanel2 = function(ctx, ui, userdata)
  ui:clear()
  ui:button{text = "P1", link = ui_subpanel1, 
            gx = 0, gy = 0, gw = 4, gh = 3}
  ui:button{text = "Back", link = ui_main, 
            gx = 8, gy = 0, gw = 4, gh = 3}
  ui:button{text = "Red", value = "r",
            gx = 0, gy = 6, gw = 4, gh = 3}
  ui:button{text = "Green", value = "g",
            gx = 4, gy = 6, gw = 4, gh = 3}
  ui:button{text = "Blue", value = "b",
            gx = 8, gy = 6, gw = 4, gh = 3}
  return ui_evt_loop(ctx, ui, userdata)
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

  local ui = wandui.WandUI{
    size = 240,
    offset = {x = 300 * (#(self.controllers)-1), y = 100},
    f = ui_main
  }
  table.insert(self.uis, ui)
end

function App:update()
  App.super.update(self)
  if self.calib_func then
    local still_running = self.calib_func:update()
    if not still_running then
      self.calib_func = nil
    end
    return
  end
  for idx, controller in ipairs(self.controllers) do
    self.mice[idx] = self.mice[idx] or {x = 0, y = 0}
    local m = self.mice[idx]
    m.x, m.y = self:project_cursor(controller.matrix_world, true, true)
    if self.world_cursor then
      self.world_cursor.position:set(m.x, m.y, 0.0)
      self.world_cursor:update_matrix()
    end
    m.x = m.x * self.calib_scale
    m.y = m.y * self.calib_scale
    if self.uis[idx] then self.uis[idx]:update(controller.vr_controller) end
  end
end

function nanovg_setup(stage, ctx)
  ctx.bg_color = ctx:RGBAf(0.0, 0.0, 0.0, 0.5) -- semi-transparent black
  ctx.font_color = ctx:RGBf(1.0, 1.0, 1.0)     -- white
  ctx:load_font("font/VeraMono.ttf", "sans")
  ctx.mouse_colors = {
    ctx:RGBf(1.0, 0.5, 0.5), ctx:RGBf(0.5, 1.0, 0.5),
    ctx:RGBf(0.5, 0.5, 1.0), ctx:RGBf(1.0, 1.0, 0.5)
  }
  ctx.colors = {
    default = {
      background = ctx:RGBAf(0.0, 0.0, 0.0, 0.5), -- semi-transparent black
      foreground = ctx:RGBf(1.0, 1.0, 1.0)        -- white
    },
    disabled = {
      background = ctx:RGBAf(0.0, 0.0, 0.0, 0.25), -- semi-transparent black
      foreground = ctx:RGBf(0.5, 0.5, 0.5)         -- gray
    },
    selected = {
      background = ctx:RGBAf(0.15, 0.5, 0.15, 0.5), -- pastel green
      foreground = ctx:RGBf(1.0, 1.0, 1.0)          -- white
    },
    failed = {
      background = ctx:RGBAf(0.5, 0.15, 0.15, 0.5), -- pastel red
      foreground = ctx:RGBf(1.0, 1.0, 1.0)          -- white
    },
    disabledselected = {
      background = ctx:RGBAf(0.0, 0.5, 0.0, 0.25), -- dark green
      foreground = ctx:RGBf(0.5, 0.5, 0.5)         -- white
    },
    inverted = {
      foreground = ctx:RGBf(0.0, 0.0, 0.0),        -- black
      background = ctx:RGBAf(1.0, 1.0, 1.0, 0.5)   -- white
    }
  }
  ctx.base_font_size = 32
end

function nanovg_render(stage, ctx)
  if not app then return end
  for i, ui in ipairs(app.uis) do
    ui:draw(ctx)
  end
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
  app = App{title = "vr (wand mouse, no hmd rendering)", 
            width = 1280, height = 720,
            msaa = true, stats = true, 
            clear_color = 0x404080ff, lowlatency = true,
            nvg_setup = nanovg_setup, nvg_render = nanovg_render}
  app.camera:add_component(orbitcam.OrbitControl({min_rad = 1, max_rad = 4}))

  lines = app.scene:create_child(grid.Grid, {thickness = 0.01, 
                                                color = {0.5, 0.2, 0.2}})
  lines.position:set(0.0, -1.0, 0.0)
  lines.quaternion:euler({x = math.pi / 2.0, y = 0.0, z = 0.0})
  lines:update_matrix()
end

function update()
  app:update()
end
