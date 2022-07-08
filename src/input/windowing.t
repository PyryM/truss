-- input/windowing.t
--
-- functionality for setting up basic windowed SDL applications

local SDL = require("./sdl.t")
local c = require("native/clib.t")

local bgfx = require("gfx/bgfx.t")

local commontypes = require("native/commontypes.t")
local SizedString = commontypes.SizedString
local wrap_c_str = commontypes.wrap_c_str
local Rect32 = commontypes.Rect32
local ByteBuffer = require("native/buffer.t").ByteBuffer

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

terra Evt:init()
  self.event_type = 0
  self.keycode = 0
  self.scancode = 0
  self.x = 0.0
  self.y = 0.0
  self.dx = 0.0
  self.dy = 0.0
  self.flags = 0
end

local MAX_CURSORS = 32

local struct Cursor {
  cursor: &SDL.Cursor;
  data: ByteBuffer;
  mask: ByteBuffer;
  w: int32;
  h: int32;
  hot_x: int32;
  hot_y: int32;
}

-- TODO: autogen init functions?
terra Cursor:init()
  self.cursor = nil
  -- self.data:init()
  -- self.mask:init()
  -- self.w = -1
  -- self.h = -1
  -- self.hot_x = -1
  -- self.hot_y = -1
end

terra Cursor:from_data(w: int32, h: int32, hx: int32, hy: int32, data: SizedString, mask: SizedString)
  self.cursor = SDL.CreateCursor(data:as_u8(), mask:as_u8(),
                                 w, h, hx, hy)
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

local struct Windowing {
  evt_list: Evt[MAX_EVENTS];
  evt_count: uint32;
  window_w: int32;
  window_h: int32;
  window: &SDL.Window;
  cursors: Cursor[MAX_CURSORS];
  sys_cursors: CursorPtr[SDL.NUM_SYSTEM_CURSORS];
  last_clipboard: &int8;
  filedrop_path: int8[256];
}

terra Windowing:init()
  self.evt_count = 0
  for i = 0, MAX_EVENTS do
    self.evt_list[i]:init()
  end
  for i = 0, MAX_CURSORS do
    self.cursors[i]:init()
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
end

terra Windowing:set_bgfx_window_data(): bool
  var wmi: SDL.SysWMinfo
  wmi.version.major = SDL.MAJOR_VERSION
  wmi.version.minor = SDL.MINOR_VERSION
  wmi.version.patch = SDL.PATCHLEVEL
  if SDL.GetWindowWMInfo(self.window, &wmi) ~= SDL.TRUE then
    c.io.printf("Error getting window info?\n")
    return false
  end
  var pd: bgfx.platform_data_t
  pd.ndt = nil
  pd.nwh = nil
  pd.context = nil
  pd.backBuffer = nil
  pd.backBufferDS = nil
  [platform_specific_bgfx_setup(pd, wmi)]
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

terra Windowing:_convert_and_push(evt: &SDL.Event)
  var new_event: Evt
  new_event:init()
  var is_valid: bool = true
  new_event.event_type = evt.type
  var etype = evt.type
  if etype == SDL.KEYDOWN or etype == SDL.KEYUP then
    new_event.flags = evt.key.keysym.mod
    new_event.scancode = evt.key.keysym.scancode
    new_event.keycode = evt.key.keysym.sym
  elseif etype == SDL.MOUSEMOTION then
    new_event.x = evt.motion.x
    new_event.y = evt.motion.y
    new_event.dx = evt.motion.xrel
    new_event.dy = evt.motion.yrel
    new_event.flags = evt.motion.state
  elseif etype == SDL.MOUSEBUTTONDOWN or etype == SDL.MOUSEBUTTONUP then
    new_event.x = evt.button.x
    new_event.y = evt.button.y
    new_event.flags = evt.button.button
  elseif etype == SDL.MOUSEWHEEL then
    new_event.x = evt.wheel.x
    new_event.y = evt.wheel.y
    new_event.flags = evt.wheel.which
  elseif etype == SDL.WINDOWEVENT then
    new_event.flags = evt.window.event
  elseif etype == SDL.TEXTINPUT then
    limited_string_copy(new_event.keyname, evt.text.text, 4)
    -- IMPORTANT: scancode comes immediately after keyname in the struct,
    --            so setting it to zero also null-terminates keyname
    new_event.scancode = 0
  elseif etype == SDL.DROPFILE then
    limited_string_copy(self.filedrop_path, evt.drop.file, 256)
  else
    return
  end
  self:_push_event(new_event)
end

terra Windowing:get_filedrop_path(): SizedString
  return wrap_c_str(self.filedrop_path)
end

terra Windowing:get_keycode_name(keycode: uint32): SizedString
  return wrap_c_str(SDL.GetKeyName(keycode))
end

terra Windowing:get_base_path(): SizedString
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

terra Windowing:get_event_ref(idx: uint32): &Evt
  if idx < self.evt_count then
    return &(self.evt_list[idx])
  else
    return nil
  end
end

terra Windowing:get_clipboard(): SizedString
  if self.last_clipboard ~= nil then
    SDL.free(self.last_clipboard)
    self.last_clipboard = nil
  end
  var ret: SizedString
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

terra Windowing:create_window(w: int32, h: int32, title: &int8, fullscreen: bool, display: int32): bool
  SDL.SetMainReady() -- is this needed?
  var res = SDL.Init(SDL.INIT_VIDEO)
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
  var res = SDL.Init(SDL.INIT_VIDEO)
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

  if not bgfx.init(&init_data) then
    c.io.printf("BGFX init error?\n")
    return false
  end
  bgfx.set_debug(bgfx.DEBUG_TEXT)
  return true
end

m.Windowing = Windowing

function m.build(options)
  return {Windowing = Windowing}
end

function m.create()
  local ret = terralib.new(Windowing)
  ret:init()
  return ret
end

local TRUSS_TO_SDL_MAP = {
  [1] = SDL.KEYDOWN,
  [2] = SDL.KEYUP,
  [3] = SDL.MOUSEBUTTONDOWN,
  [4] = SDL.MOUSEBUTTONUP,
  [5] = SDL.MOUSEMOTION,
  [6] = SDL.MOUSEWHEEL,
  [7] = SDL.WINDOWEVENT,
  [8] = SDL.TEXTINPUT,
  [9] = SDL.JOYDEVICEADDED,    
  [10] = SDL.JOYDEVICEREMOVED,    
  [11] = SDL.JOYAXISMOTION,   
  [12] = SDL.JOYBUTTONDOWN, 
  [13] = SDL.JOYBUTTONUP,
  [14] = SDL.DROPFILE      
}

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

function m.create_sdl_demo()
  local terra sdlmain(): int
    c.io.printf("Entering main?\n")
    SDL.SetMainReady() -- is this needed?
    var res = SDL.Init(SDL.INIT_VIDEO)
    if res ~= 0 then
      c.io.printf("Some kind of SDL init error?\n")
      return -1
    end
    var flags: uint32 = SDL.WINDOW_SHOWN
    var xpos: int32 = SDL.WINDOWPOS_CENTERED
    var ypos: int32 = SDL.WINDOWPOS_CENTERED
    var window = SDL.CreateWindow(
      "Self-compiled application", xpos, ypos, 720, 720, flags
    )
    if not set_bgfx_window_data(window) then
      c.io.printf("Error setting window data?\n")
      return -1
    end

    var renderer_type = bgfx.RENDERER_TYPE_COUNT
    var init_data: bgfx.init_t

    bgfx.init_ctor(&init_data)
    init_data.debug = false
    init_data.profile = false
    init_data.resolution.width = 720
    init_data.resolution.height = 720
    init_data.resolution.reset = bgfx.RESET_VSYNC

    c.io.printf("Initializing BGFX?\n")
    if not bgfx.init(&init_data) then
      c.io.printf("BGFX init error????\n")
      return -1
    end
    bgfx.set_debug(bgfx.DEBUG_TEXT)

    c.io.printf("Initialized fine?\n")
    
    var frame: uint32 = 0
    c.io.printf("Entering render loop?\n")

    while handle_minimal_window_events() do
      -- while SDL.PollEvent(&evt) > 0 do
      --   if evt.type == SDL.WINDOWEVENT and evt.window.event == SDL.WINDOWEVENT_CLOSE then
      --     c.io.printf("Closing?\n")
      --     closing = true
      --     break
      --   end
      -- end
      -- if closing then break end

      -- draw bgfx
      bgfx.set_view_rect(0, 0, 0, 1280, 720)
      bgfx.set_view_clear(
        0, 
        bgfx.CLEAR_COLOR or bgfx.CLEAR_DEPTH or bgfx.CLEAR_STENCIL,
        0xff0000ff, 1.0, 0
      )
      bgfx.touch(0)

      bgfx.dbg_text_clear(0, false)
      bgfx.dbg_text_printf(0, 1, 0x4f, "We did it")
      bgfx.dbg_text_printf(0, 2, 0x6f, "frame: %d", frame)

      bgfx.frame(false)
      frame = frame + 1
    end

    bgfx.shutdown()
    SDL.Quit()

    return 0
  end

  return sdlmain
end

return m