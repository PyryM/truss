-- vr/wandui.t
--
-- a really minimal UI to display on the wands

local class = require("class")
local Miniscript = require("utils/miniscript.t").Miniscript

local m = {}

function m.default_nvg_setup(stage, ctx)
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
  ctx:load_font("font/VeraMono.ttf", "sans")
end

local Widget = class("Widget")
function Widget:init(parent, options)
  self.parent = parent
  self:compute_bounds(options)
end

function Widget:compute_bounds(options)
  local b = {}
  if options.gx then
    local csize = self.parent.size / 12
    b.x = options.gx * csize + (csize / 8)
    b.y = options.gy * csize + (csize / 8)
    b.w = options.gw * csize - (csize / 4)
    b.h = options.gh * csize - (csize / 4)
  else
    b.x = options.x
    b.y = options.y
    b.w = options.w
    b.h = options.h
  end
  b.x2 = b.x + b.w
  b.y2 = b.y + b.h
  self.bounds = b
end

function Widget:in_bounds(x, y)
  local b = self.bounds
  return x >= b.x and x <= b.x2 and y >= b.y and y <= b.y2
end

function Widget:emit(evtname, evtdata)
  self.parent:event(evtname, evtdata)
end

local Label = Widget:extend("Label")
function Label:init(parent, options)
  Label.super.init(self, parent, options)
  self.text = options.text or "?"
  self.font_size = options.font_size or 1
  self.state = 0
end

function Label:draw(ctx)
  local color
  if self.state == 0 then
    color = "default"
  elseif self.state == 1 then
    color = "selected"
  elseif self.state == 2 then
    color = "inverted"
  end

  local b = self.bounds
  ctx:BeginPath()
  ctx:RoundedRect(b.x, b.y, b.w, b.h, 3)
  ctx:FillColor(ctx.colors[color].background)
  ctx:Fill()

  ctx:FontFace("sans")
  local fsize = self.font_size * ctx.base_font_size
  ctx:FontSize(fsize)
  ctx:FillColor(ctx.colors[color].foreground)
  ctx:TextAlign(ctx.ALIGN_MIDDLE + ctx.ALIGN_CENTER)
  ctx:Text(b.x + (b.w / 2), b.y + (b.h / 2), self.text or "?", nil)
end

local Button = Label:extend("Button")
function Button:init(parent, options)
  Button.super.init(self, parent, options)
  self.state = 0 -- 0: inactive, 1: hover, 2: down
  self.value = options.value or options.text
end

function Button:update(x, y, touched, pressed)
  local in_bounds = self:in_bounds(x, y)
  if in_bounds and pressed then
    if self.state == 1 then -- hover -> down
      self:down()
    end
    self.state = 2
  else
    if self.state == 2 then -- down -> hover or inactive
      self:up()
    end
    if in_bounds and touched then self.state = 1 else self.state = 0 end    
  end
end

-- these basically exist so other things can override them
function Button:down()
  self:emit("ui_button_down", self)
end

function Button:up()
  self:emit("ui_button_up", self)
end

local WandUI = class("WandUI")
m.WandUI = WandUI

function WandUI:init(options)
  self._widgets = {}
  self.size = options.size
  self._offset = options.offset or {x = 0, y = 0}
  self._script = Miniscript(options.f, self, options)
end

function WandUI:_to_pixel_coordinates(x, y)
  return (x + 1) * (self.size / 2), (y + 1) * (self.size / 2)
end

function WandUI:event(evtname, evtdata)
  if self._script then
    self._script:event(evtname, evtdata)
  end
end

function WandUI:update(controller)
  local tpad = controller.axes.trackpad1
  local mx, my = self:_to_pixel_coordinates(tpad.x, tpad.y)
  self.mx, self.my = mx, my
  local touched = controller.buttons.SteamVR_Touchpad >= 1
  local pressed = controller.buttons.SteamVR_Touchpad >= 2
  self.touched = touched
  self.pressed = pressed
  local alt = controller.buttons.ApplicationMenu >= 1
  if alt and (not self._prev_alt) then
    self:event("ui_alt_down", {})
  elseif (not alt) and self._prev_alt then
    self:event("ui_alt_up", {})
  end
  self._prev_alt = alt
  for _, widget in pairs(self._widgets) do
    if widget.update then widget:update(mx, my, touched, pressed) end
  end
  if self._script then self._script:update() end
end

function WandUI:draw(ctx)
  ctx:Save()
  ctx:Translate(self._offset.x, self._offset.y)
  ctx:Scissor(0, 0, self.size, self.size)
  for _, widget in pairs(self._widgets) do
    if widget.draw then widget:draw(ctx) end
  end
  ctx:BeginPath()
  ctx:Circle(self.mx, self.my, 20)
  ctx:FillColor(ctx.colors.default.foreground)
  ctx:Fill()
  ctx:Restore()
end

function WandUI:clear()
  self._widgets = {}
end

local function register_widget(widget_name, widget_class)
  WandUI[widget_name] = function(self, options)
    local w = widget_class(self, options)
    self._widgets[w] = w
    return w
  end
end
register_widget("button", Button)
register_widget("label", Label)

return m