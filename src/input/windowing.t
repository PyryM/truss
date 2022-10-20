-- input/windowing.t
--
-- functionality for setting up basic windowed SDL applications

local build = require("build/build.t")
local SDL = require("./sdl.t")

local bgfx = require("gfx/bgfx.t")

local substrate = require("substrate")
local c = substrate.libc

local struct Rect32 {
  x: int32;
  y: int32;
  w: int32;
  h: int32;
}

local StringSlice = substrate.StringSlice
local wrap_c_str = substrate.wrap_c_str
local ByteArray = substrate.ByteArray

local m = {}

local MAX_EVENTS = 128
local ETYPES = { 
  -- Note this is just a subset of the SDL enum for reference
  QUIT = 0x100,
  WINDOWEVENT = 0x200,
  SYSWMEVENT = 0x201,
  KEYDOWN = 0x300,
  KEYUP = 0x301,
  TEXTEDITING = 0x302,
  TEXTINPUT = 0x303,
  MOUSEMOTION = 0x400,
  MOUSEBUTTONDOWN = 0x401,
  MOUSEBUTTONUP = 0x402,
  MOUSEWHEEL = 0x403
}

local struct Evt {
  event_type: uint32;
  keycode: uint32;
  keyname: int8[4];
  scancode: uint32;
  x: double;
  y: double;
  dx: double;
  dy: double;
  flags: uint32;
}
m.Evt = Evt

substrate.derive.derive_init(Evt)

local MAX_CURSORS = 32

local struct Cursor {
  cursor: &SDL.Cursor;
  data: ByteArray;
  mask: ByteArray;
  w: int32;
  h: int32;
  hot_x: int32;
  hot_y: int32;
}

substrate.derive.derive_init(Cursor)

terra Cursor:from_data(w: int32, h: int32, hx: int32, hy: int32, data: StringSlice, mask: StringSlice)
  self.cursor = SDL.CreateCursor(data:as_u8(), mask:as_u8(), w, h, hx, hy)
end

terra Cursor:set_active()
  if self.cursor ~= nil then
    SDL.SetCursor(self.cursor)
  end
end

local CursorPtr = &SDL.Cursor

local function platform_specific_bgfx_setup(pd, wmi)
  if truss.os == "Windows" then
    return quote
      pd.nwh = wmi.info.win.window
    end
  elseif truss.os == "OSX" then
    return quote 
      pd.nwh = wmi.info.cocoa.window
    end
  elseif truss.os == "Linux" then
    -- do we need to care about Wayland?
    return quote
      if false and wmi.subsystem == SDL.SYSWM_WAYLAND then
        -- this may not actually work, the bgfx entry example
        -- really wants to actually create an egl window itself
        -- for some reason
        pd.nwh = wmi.info.wl.egl_window
        pd.ndt = wmi.info.wl.display
      else
        pd.nwh = wmi.info.x11.window
        pd.ndt = wmi.info.x11.display
      end
    end
  else
    truss.error("Windowing not yet implemented for " .. truss.os)
    return nil
  end
end

local MAX_CONTROLLERS = 4

local struct ControllerState {
  connected: uint32;
  buttons: uint32;
  lx: float;
  ly: float;
  rx: float;
  ry: float;
  lt: float;
  rt: float;
}

substrate.derive.derive_init(ControllerState)
substrate.derive.derive_clear(ControllerState)

terra ControllerState:update_buttons(evt: &SDL.Event)
  var mask_bit: uint32 = 1 << evt.cbutton.button
  if evt.cbutton.state > 0 then
    self.buttons = self.buttons or mask_bit
  else
    self.buttons = self.buttons and (not mask_bit)
  end
end

terra ControllerState:update_axis(evt: &SDL.Event)
  var val = [float](evt.caxis.value) / 32768.0
  var axis: int32 = evt.caxis.axis
  switch axis do
    case SDL.CONTROLLER_AXIS_LEFTX then
      self.lx = val
    case SDL.CONTROLLER_AXIS_LEFTY then
      self.ly = val
    case SDL.CONTROLLER_AXIS_RIGHTX then
      self.rx = val
    case SDL.CONTROLLER_AXIS_RIGHTY then
      self.ry = val
    case SDL.CONTROLLER_AXIS_TRIGGERLEFT then
      self.lt = val
    case SDL.CONTROLLER_AXIS_TRIGGERRIGHT then
      self.rt = val
    end
  end
end

local struct Controller {
  handle: &SDL.GameController;
  instance_id: int32;
  linear_id: uint32;
  state: ControllerState;
} 

terra Controller:init()
  self.handle = nil
  self.instance_id = -1
  self.linear_id = 0
  self.state:init()
end

terra Controller:open(id: uint32): bool
  self:close()
  if SDL.IsGameController(id) == 0 then return false end
  self.handle = SDL.GameControllerOpen(id)
  if self.handle == nil then return false end
  var joy = SDL.GameControllerGetJoystick(self.handle)
  self.instance_id = SDL.JoystickInstanceID(joy)
  self.state:clear()
  self.state.connected = 1
  return true
end

terra Controller:is_connected(): bool
  if self.handle == nil then return false end
  if SDL.GameControllerGetAttached(self.handle) == 0 then
    self:close()
    return false
  else
    return true
  end
end

terra Controller:close()
  if self.handle == nil then return end
  SDL.GameControllerClose(self.handle)
  self.handle = nil
  self.instance_id = -1
  self.state:clear()
end

local VERSION_STR_LEN = 32

local struct Windowing {
  evt_list: Evt[MAX_EVENTS];
  evt_count: uint32;
  window_w: int32;
  window_h: int32;
  window: &SDL.Window;
  cursors: Cursor[MAX_CURSORS];
  sys_cursors: CursorPtr[SDL.NUM_SYSTEM_CURSORS];
  push_controller_events: bool;
  controllers: Controller[MAX_CONTROLLERS];
  last_clipboard: &int8;
  filedrop_path: int8[256];
  version_str: int8[VERSION_STR_LEN];
}

terra Windowing:init(): bool
  self.evt_count = 0
  for i = 0, MAX_EVENTS do
    self.evt_list[i]:init()
  end
  for i = 0, MAX_CURSORS do
    self.cursors[i]:init()
  end
  for i = 0, MAX_CONTROLLERS do
    self.controllers[i]:init()
    self.controllers[i].linear_id = i
  end
  for i = 0, SDL.NUM_SYSTEM_CURSORS do
    self.sys_cursors[i] = nil
  end
  self.window_h = 0
  self.window_w = 0
  self.window = nil
  self.last_clipboard = nil
  self.filedrop_path[0] = 0
  self.filedrop_path[255] = 0
  self.push_controller_events = false
  return true
end

terra Windowing:_find_controller(instance_id: uint32): &Controller
  for i = 0, MAX_CONTROLLERS do
    var controller: &Controller = &(self.controllers[i])
    if controller.instance_id == instance_id and controller.handle ~= nil then
      return controller
    end
  end
  return nil
end

if build.target_name() == "wasm" then
  local CANVAS_ELEM = "#canvas" -- HARDCODED!
  log.warn("Warning! Hardcoding in", CANVAS_ELEM, "as target canvas!")
  terra Windowing:get_bgfx_platform_data(pd: &bgfx.platform_data_t): bool
    pd.ndt = nil
    pd.nwh = CANVAS_ELEM
    pd.context = nil
    pd.backBuffer = nil
    pd.backBufferDS = nil
    return true
  end
else
  terra Windowing:get_bgfx_platform_data(pd: &bgfx.platform_data_t): bool
    var wmi: SDL.SysWMinfo
    wmi.version.major = SDL.MAJOR_VERSION
    wmi.version.minor = SDL.MINOR_VERSION
    wmi.version.patch = SDL.PATCHLEVEL
    if SDL.GetWindowWMInfo(self.window, &wmi) ~= SDL.TRUE then
      c.io.printf("Error getting window info?\n")
      c.io.printf("SDLERROR: %s\n", SDL.GetError())
      return false
    end
    pd.ndt = nil
    pd.nwh = nil
    pd.context = nil
    pd.backBuffer = nil
    pd.backBufferDS = nil
    [platform_specific_bgfx_setup(pd, wmi)]
    return true
  end
end

terra Windowing:set_bgfx_window_data(): bool
  var pd: bgfx.platform_data_t
  if not self:get_bgfx_platform_data(&pd) then return false end
  bgfx.set_platform_data(&pd)
  return true
end

terra Windowing:get_window_bounds(hidpi: bool): Rect32
  var ret: Rect32 = Rect32{0, 0, 0, 0}
  --TODO: hidpi
  SDL.GetWindowPosition(self.window, &ret.x, &ret.y)
  SDL.GetWindowSize(self.window, &ret.w, &ret.h)
  return ret
end

terra Windowing:_push_event(e: Evt): bool
  if self.evt_count >= MAX_EVENTS then return false end
  self.evt_list[self.evt_count] = e
  self.evt_count = self.evt_count + 1
  return true
end

local terra limited_string_copy(dest: &int8, src: &int8, count: uint32)
  for i = 0, count do
    dest[i] = src[i]
    if src[i] == 0 then break end
  end
end

local terra translate_key_event(new_event: &Evt, evt: &SDL.Event)
  new_event.flags = evt.key.keysym.mod
  new_event.scancode = evt.key.keysym.scancode
  new_event.keycode = evt.key.keysym.sym
end

local terra translate_mouse_event(new_event: &Evt, evt: &SDL.Event)
  new_event.x = evt.button.x
  new_event.y = evt.button.y
  new_event.flags = evt.button.button
end

terra Windowing:_convert_and_push(evt: &SDL.Event)
  var new_event: Evt
  new_event:init()
  var is_valid: bool = true
  new_event.event_type = evt.type
  var etype: int32 = evt.type
  switch etype do
    case SDL.KEYDOWN then
      translate_key_event(&new_event, evt)
    case SDL.KEYUP then
      translate_key_event(&new_event, evt)
    case SDL.MOUSEMOTION then
      new_event.x = evt.motion.x
      new_event.y = evt.motion.y
      new_event.dx = evt.motion.xrel
      new_event.dy = evt.motion.yrel
      new_event.flags = evt.motion.state
    case SDL.MOUSEBUTTONDOWN then
      translate_mouse_event(&new_event, evt)
    case SDL.MOUSEBUTTONUP then
      translate_mouse_event(&new_event, evt)
    case SDL.MOUSEWHEEL then
      new_event.x = evt.wheel.x
      new_event.y = evt.wheel.y
      new_event.flags = evt.wheel.which
    case SDL.WINDOWEVENT then
      new_event.flags = evt.window.event
      new_event.x = evt.window.data1
      new_event.y = evt.window.data2
    case SDL.TEXTINPUT then
      limited_string_copy(new_event.keyname, evt.text.text, 4)
      -- IMPORTANT: scancode comes immediately after keyname in the struct,
      --            so setting it to zero also null-terminates keyname
      new_event.scancode = 0
    case SDL.DROPFILE then
      limited_string_copy(self.filedrop_path, evt.drop.file, 256)
    case SDL.CONTROLLERDEVICEADDED then
      var id = evt.cdevice.which
      new_event.flags = evt.cdevice.which
      new_event.scancode = 0
      c.io.printf("Controller connected [%d]\n", evt.cdevice.which)
      if id >= 0 and id < MAX_CONTROLLERS then
        if not self.controllers[id]:open(id) then return end
        new_event.scancode = self.controllers[id].instance_id
        c.io.printf("== instance_id [%d]\n", self.controllers[id].instance_id)
        c.io.printf("== name [%s]\n", SDL.GameControllerName(self.controllers[id].handle))
      end
    case SDL.CONTROLLERDEVICEREMOVED then
      new_event.scancode = evt.cdevice.which
      new_event.flags = 0
      var controller = self:_find_controller(evt.cdevice.which)
      if controller ~= nil then
        new_event.flags = controller.linear_id
        controller:close()
      end
    case SDL.CONTROLLERAXISMOTION then
      var controller = self:_find_controller(evt.caxis.which)
      if controller ~= nil then controller.state:update_axis(evt) end
      if not self.push_controller_events then return end
      new_event.flags = evt.caxis.which
      new_event.scancode = evt.caxis.axis
      new_event.x = [float](evt.caxis.value) / 32768.0
    case SDL.CONTROLLERBUTTONDOWN then
      var controller = self:_find_controller(evt.cbutton.which)
      if controller ~= nil then controller.state:update_buttons(evt) end
      if not self.push_controller_events then return end
      new_event.flags = evt.cbutton.which
      new_event.scancode = evt.cbutton.button
    case SDL.CONTROLLERBUTTONUP then
      var controller = self:_find_controller(evt.cbutton.which)
      if controller ~= nil then controller.state:update_buttons(evt) end
      if not self.push_controller_events then return end
      new_event.flags = evt.cbutton.which
      new_event.scancode = evt.cbutton.button
    end
  else
    return
  end

  self:_push_event(new_event)
end

terra Windowing:get_filedrop_path(): StringSlice
  return wrap_c_str(self.filedrop_path)
end

terra Windowing:get_keycode_name(keycode: uint32): StringSlice
  return wrap_c_str(SDL.GetKeyName(keycode))
end

terra Windowing:get_base_path(): StringSlice
  -- leaks a little bit of memory so don't abuse!
  return wrap_c_str(SDL.GetBasePath())
end

terra Windowing:get_save_path(org_name: &int8, app_name: &int8)
  -- leaks a little bit of memory so don't abuse!
  return wrap_c_str(SDL.GetPrefPath(org_name, app_name))
end

terra Windowing:enable_text_input(enabled: bool)
  if enabled then
    SDL.StartTextInput()
  else
    SDL.StopTextInput()
  end
end

terra Windowing:set_fps_mouse_mode(fps_mode: bool)
  SDL.SetRelativeMouseMode([int32](fps_mode))
end

terra Windowing:set_cursor_visible(visible: bool)
  SDL.ShowCursor([int32](visible))
end

terra Windowing:set_system_cursor(idx: int32)
  --var cursor = SDL.CreateSystemCursor([SDL.SystemCursor](idx))
  --SDL.SetCursor(cursor)
  if idx < 0 or idx >= SDL.NUM_SYSTEM_CURSORS then return end
  if self.sys_cursors[idx] == nil then
    c.io.printf("Creating system cursor: %d\n", idx)
    self.sys_cursors[idx] = SDL.CreateSystemCursor([SDL.SystemCursor](idx))
  end
  SDL.SetCursor(self.sys_cursors[idx])
end

terra Windowing:poll_events(): bool
  self.evt_count = 0
  var evt: SDL.Event
  var not_closed = true
  while SDL.PollEvent(&evt) > 0 do
    if evt.type == SDL.WINDOWEVENT and evt.window.event == SDL.WINDOWEVENT_CLOSE then
      not_closed = false
    end
    self:_convert_and_push(&evt)
  end
  return not_closed
end

terra Windowing:get_event_count(): uint32
  return self.evt_count
end

terra Windowing:get_event(idx: uint32): Evt
  if idx < self.evt_count then
    return self.evt_list[idx]
  else
    var temp_event: Evt
    temp_event:init()
    return temp_event
  end
end

terra Windowing:controller_get_state(idx: uint32): ControllerState
  if idx >= MAX_CONTROLLERS then idx = 0 end
  return self.controllers[idx].state
end

terra Windowing:controller_is_connected(idx: uint32): bool
  if idx >= MAX_CONTROLLERS then return false end
  return self.controllers[idx]:is_connected()
end

terra Windowing:controller_get_name(idx: uint32): StringSlice
  if idx >= MAX_CONTROLLERS then return wrap_c_str("InvalidIndex") end
  if self.controllers[idx]:is_connected() then
    return wrap_c_str(SDL.GameControllerName(self.controllers[idx].handle))
  else
    return wrap_c_str("None")
  end
end

if SDL.GameControllerHasRumble and SDL.GameControllerHasLED then
  log.build("SDL supports controller rumble/led")
  -- SDL 2.0.20+
  terra Windowing:controller_has_rumble(idx: uint32): bool
    if idx >= MAX_CONTROLLERS then return false end
    var controller = &(self.controllers[idx])
    if controller.handle == nil then return false end
    return SDL.GameControllerHasRumble(controller.handle) ~= 0
  end

  terra Windowing:controller_rumble(idx: uint32, low_freq: uint16, high_freq: uint16, duration_ms: uint32)
    if idx >= MAX_CONTROLLERS then return end
    var controller = &(self.controllers[idx])
    if controller.handle == nil then return end
    SDL.GameControllerRumble(controller.handle, low_freq, high_freq, duration_ms)
  end

  terra Windowing:controller_has_led(idx: uint32): bool
    if idx >= MAX_CONTROLLERS then return false end
    var controller = &(self.controllers[idx])
    if controller.handle == nil then return false end
    return SDL.GameControllerHasLED(controller.handle) ~= 0
  end

  terra Windowing:controller_set_led(idx: uint32, r: uint8, g: uint8, b: uint8)
    if idx >= MAX_CONTROLLERS then return end
    var controller = &(self.controllers[idx])
    if controller.handle == nil then return end
    SDL.GameControllerSetLED(controller.handle, r, g, b)
  end
else
  -- older SDL2
  log.build("SDL does NOT support controller rumble/led")
  terra Windowing:controller_has_rumble(idx: uint32): bool
    return false
  end

  terra Windowing:controller_rumble(idx: uint32, low_freq: uint16, high_freq: uint16, duration_ms: uint32)
    -- nop
  end

  terra Windowing:controller_has_led(idx: uint32): bool
    return false
  end

  terra Windowing:controller_set_led(idx: uint32, r: uint8, g: uint8, b: uint8)
    -- nop
  end
end

terra Windowing:get_event_ref(idx: uint32): &Evt
  if idx < self.evt_count then
    return &(self.evt_list[idx])
  else
    return nil
  end
end

terra Windowing:get_clipboard(): StringSlice
  if self.last_clipboard ~= nil then
    SDL.free(self.last_clipboard)
    self.last_clipboard = nil
  end
  var ret: StringSlice
  if SDL.HasClipboardText() > 0 then
    self.last_clipboard = SDL.GetClipboardText()
    return wrap_c_str(self.last_clipboard)
  else
    return wrap_c_str("")
  end
end

terra Windowing:set_clipboard(text: &int8)
  if text == nil then return end
  SDL.SetClipboardText(text)
end

terra Windowing:get_sdl_version(): StringSlice
  var version: SDL.version
  SDL.GetVersion(&version)
  c.io.snprintf(self.version_str, VERSION_STR_LEN, 
    "%d.%d.%d", version.major, version.minor, version.patch)
  return wrap_c_str(self.version_str)
end

terra Windowing:create_window(w: int32, h: int32, title: &int8, fullscreen: bool, display: int32): bool
  SDL.SetMainReady() -- is this needed?
  var res = SDL.Init(SDL.INIT_VIDEO or SDL.INIT_GAMECONTROLLER)
  if res ~= 0 then
    return false
  end
  var flags: uint32 = SDL.WINDOW_SHOWN + SDL.WINDOW_RESIZABLE
  var xpos: int32 = SDL.WINDOWPOS_CENTERED
  var ypos: int32 = SDL.WINDOWPOS_CENTERED
  var window = SDL.CreateWindow(title, xpos, ypos, w, h, flags)
  self.window = window

  if not self:set_bgfx_window_data() then
    c.io.printf("Error setting window data")
    return false
  end

  return true
end

terra Windowing:create_window_and_bgfx(backend: bgfx.renderer_type_t, w: int32, h: int32, title: &int8): bool
  SDL.SetMainReady() -- is this needed?
  var res = SDL.Init(SDL.INIT_VIDEO or SDL.INIT_GAMECONTROLLER)
  if res ~= 0 then
    return false
  end
  var flags: uint32 = SDL.WINDOW_SHOWN + SDL.WINDOW_RESIZABLE
  var xpos: int32 = SDL.WINDOWPOS_CENTERED
  var ypos: int32 = SDL.WINDOWPOS_CENTERED
  var window = SDL.CreateWindow(title, xpos, ypos, w, h, flags)
  self.window = window

  if not self:set_bgfx_window_data() then
    c.io.printf("Error setting window data")
    return false
  end

  -- NOTE THAT THIS IS "RENDER_FRAME" AND NOT JUST "FRAME"!!!!!!!
  bgfx.render_frame(-1) -- init single-threaded

  var init_data: bgfx.init_t
  bgfx.init_ctor(&init_data)
  init_data.type = backend
  init_data.debug = false
  init_data.profile = false
  init_data.resolution.width = w
  init_data.resolution.height = h
  init_data.resolution.reset = bgfx.RESET_VSYNC
  self:get_bgfx_platform_data(&(init_data.platformData))

  if not bgfx.init(&init_data) then
    c.io.printf("BGFX init error?\n")
    return false
  end
  bgfx.set_debug(bgfx.DEBUG_TEXT)
  return true
end

terra Windowing:set_bgfx_debug(show_text: bool, show_stats: bool)
  var flags: uint32 = 0
  if show_text then
    flags = flags or bgfx.DEBUG_TEXT
  end
  if show_stats then
    flags = flags or bgfx.DEBUG_STATS
  end
  bgfx.set_debug(flags)
end

terra Windowing:reset_bgfx(w: int32, h: int32)
  var flags = bgfx.RESET_VSYNC
  bgfx.reset(w, h, flags, bgfx.TEXTURE_FORMAT_COUNT)
end

m.Windowing = Windowing

function m.build(options)
  return {Windowing = Windowing, ctype = Windowing}
end

function m.create()
  local ret = terralib.new(Windowing)
  ret:init()
  return ret
end

local EXTRA_KEYS = {
  ["return"] = string.byte("\r", 1),
  ["enter"] = string.byte("\r", 1),
}
function m._push_event(target)
  if target.evt_count >= MAX_EVENTS then return nil end
  local new_event = target.evt_list[target.evt_count]
  target.evt_count = target.evt_count + 1
  return new_event
end

function m.push_key_event(target, key, down)
  local new_event = m._push_event(target)
  if not new_event then return false end
  new_event.event_type = (down and SDL.KEYDOWN) or SDL.KEYUP
  new_event.scancode = 0
  -- SDL keycodes mostly just happen to be the ASCII representations
  new_event.keycode = EXTRA_KEYS[key] or string.byte(key, 1)
  new_event.flags = 0
  return true
end

function m.push_text_event(target, text)
  local new_event = m._push_event(target)
  if not new_event then return false end
  new_event.event_type = SDL.TEXTINPUT
  new_event.scancode = 0
  for bytepos = 0, 3 do
    new_event.keyname[bytepos] = text:byte(bytepos+1) or 0
  end
  return true
end

return m