-- gfx/imgui.t
--
-- imgui

local build = require("build/build.t")
local modutils = require("core/module.t")
local class = require("class")
local substrate = require("substrate")
local libc = substrate.libc
local m = {}

local imgui_c_raw = build.includec("bgfx/cimgui_terra.h")
m.C_raw = imgui_c_raw

local C = {}
m.C = C
local IG = C
m.IG = IG

-- Renames:
--  igFunctionName --> FunctionName
--  ImThing        --> Thing
--  ImGuiWhatever  --> Whatever
--  somethingElse  --> somethingElse
--
-- Note that nested structs will still have obnoxious names:
-- ImVector_ImGuiID --> Vector_ImGuiID
modutils.reexport_renamed(imgui_c_raw, {Im="", ImGui="", ig=""}, true, C)

function m.build(options)
  local FONTCOUNT = 2

  local struct ImGuiContext {
    width: int32;
    height: int32;
    viewid: uint16;
    fontsize: float;
    mouse_pressed: bool[3];
    clipboard_text: &int8;
    fonts: IG.bgfx_imgui_font_info[FONTCOUNT];
    fontcount: uint32;
    reference_colors: float[16]; -- TODO: dehardcode?
    n_reference_colors: uint32;
    key_map: substrate.Array(int32);
  }

  if options.SDL then
    local SDL = options.SDL
    
    local terra get_clipboard_text(_userdata: &opaque): &int8
      var userdata = [&ImGuiContext](_userdata)
      if userdata.clipboard_text ~= nil then
        SDL.free(userdata.clipboard_text)
      end
      userdata.clipboard_text = SDL.GetClipboardText()
      return userdata.clipboard_text
    end

    local terra set_clipboard_text(userdata: &opaque, text: &int8)
      SDL.SetClipboardText(text)
    end

    -- These functions that interface with SDL are largely ported
    -- from the imgui C++ SDL backend:
    -- https://github.com/ocornut/imgui/blob/master/backends/imgui_impl_sdl.cpp
    terra ImGuiContext:_init_bindings()
      -- Keyboard mapping. 
      self.key_map:init()
      self.key_map:allocate(1024)
      self.key_map:fill(self.key_map.capacity, 0)
      var map = self.key_map.data
      map[SDL.SCANCODE_TAB] = IG.Key_Tab 
      map[SDL.SCANCODE_LEFT] = IG.Key_LeftArrow 
      map[SDL.SCANCODE_RIGHT] = IG.Key_RightArrow 
      map[SDL.SCANCODE_UP] = IG.Key_UpArrow 
      map[SDL.SCANCODE_DOWN] = IG.Key_DownArrow 
      map[SDL.SCANCODE_PAGEUP] = IG.Key_PageUp 
      map[SDL.SCANCODE_PAGEDOWN] = IG.Key_PageDown 
      map[SDL.SCANCODE_HOME] = IG.Key_Home 
      map[SDL.SCANCODE_END] = IG.Key_End 
      map[SDL.SCANCODE_INSERT] = IG.Key_Insert 
      map[SDL.SCANCODE_DELETE] = IG.Key_Delete 
      map[SDL.SCANCODE_BACKSPACE] = IG.Key_Backspace 
      map[SDL.SCANCODE_SPACE] = IG.Key_Space 
      map[SDL.SCANCODE_RETURN] = IG.Key_Enter 
      map[SDL.SCANCODE_ESCAPE] = IG.Key_Escape 
      --map[SDL.SCANCODE_KP_ENTER] = IG.Key_KeyPadEnter 
      map[SDL.SCANCODE_A] = IG.Key_A 
      map[SDL.SCANCODE_C] = IG.Key_C 
      map[SDL.SCANCODE_V] = IG.Key_V 
      map[SDL.SCANCODE_X] = IG.Key_X 
      map[SDL.SCANCODE_Y] = IG.Key_Y 
      map[SDL.SCANCODE_Z] = IG.Key_Z 
      --SDL.SetHint(SDL.HINT_MOUSE_FOCUS_CLICKTHROUGH, "1")
      var io = IG.GetIO()
      io.ClipboardUserData = self
      io.GetClipboardTextFn = get_clipboard_text
      io.SetClipboardTextFn = set_clipboard_text
    end

    terra ImGuiContext:_pre_frame_update()
      var mx: int32
      var my: int32
      var mouse_buttons = SDL.GetMouseState(&mx, &my)
      var io = IG.GetIO()
      -- If a mouse press event came, always pass it as "mouse held this frame", so we don't miss click-release events that are shorter than 1 frame.
      io.MouseDown[0] = self.mouse_pressed[0] or (mouse_buttons and SDL.BUTTON_LMASK) ~= 0  
      io.MouseDown[1] = self.mouse_pressed[1] or (mouse_buttons and SDL.BUTTON_RMASK) ~= 0
      io.MouseDown[2] = self.mouse_pressed[2] or (mouse_buttons and SDL.BUTTON_MMASK) ~= 0
      for i = 0, 3 do
        self.mouse_pressed[i] = false
      end
      io.MousePos.x = mx
      io.MousePos.y = my
    end

    terra ImGuiContext:handle_sdl_event(io: &IG.IO, event: &SDL.Event): bool
      var etype = event.type
      if etype == SDL.MOUSEWHEEL then
        if event.wheel.x > 0 then io.MouseWheelH = io.MouseWheelH - 1 end
        if event.wheel.x < 0 then io.MouseWheelH = io.MouseWheelH + 1 end
        if event.wheel.y > 0 then io.MouseWheel = io.MouseWheel + 1 end
        if event.wheel.y < 0 then io.MouseWheel = io.MouseWheel - 1 end
        return true
      elseif etype == SDL.MOUSEBUTTONDOWN then
        if event.button.button == SDL.BUTTON_LEFT then 
          self.mouse_pressed[0] = true
        elseif event.button.button == SDL.BUTTON_RIGHT then 
          self.mouse_pressed[1] = true
        elseif event.button.button == SDL.BUTTON_MIDDLE then 
          self.mouse_pressed[2] = true 
        end
        return true
      elseif etype == SDL.TEXTINPUT then
        IG.IO_AddInputCharactersUTF8(io, event.text.text)
        return true
      elseif etype == SDL.KEYDOWN or etype == SDL.KEYUP then
        var key = event.key.keysym.scancode
        if key >= 0 and key < 512 then
          -- assume legacy SDL keys "just work" (handle mapping later)

          var mapped = self.key_map.data[key]
          if mapped == 0 then mapped = key end
          IG.IO_AddKeyEvent(io, mapped, (event.type == SDL.KEYDOWN))

          var modstate = SDL.GetModState()
          IG.IO_AddKeyEvent(io, IG.Key_ModCtrl, (modstate and SDL.KMOD_CTRL) ~= 0)
          IG.IO_AddKeyEvent(io, IG.Key_ModShift, (modstate and SDL.KMOD_SHIFT) ~= 0)
          IG.IO_AddKeyEvent(io, IG.Key_ModAlt, (modstate and SDL.KMOD_ALT) ~= 0)
          escape
            if truss.os ~= 'Windows' then
              emit quote 
                IG.IO_AddKeyEvent(io, IG.Key_ModSuper, (modstate and SDL.KMOD_GUI) ~= 0)
              end
            end
          end
        end
        return true
      end
      return false
    end
  else
    terra ImGuiContext:_init_bindings()
      -- don't do anything
    end

    terra ImGuiContext:_pre_frame_update()
      -- don't do anything
    end
  end

  if options.Windowing and options.SDL then
    local Windowing = options.Windowing
    local SDL = options.SDL
    terra ImGuiContext:poll_events(windowing: &Windowing): bool
      windowing.evt_count = 0
      var evt: SDL.Event
      var not_closed = true
      var io = IG.GetIO()
      var capturing = io.WantCaptureMouse or io.WantCaptureKeyboard
      while SDL.PollEvent(&evt) > 0 do
        if evt.type == SDL.WINDOWEVENT and evt.window.event == SDL.WINDOWEVENT_CLOSE then
          not_closed = false
        end
        var handled = self:handle_sdl_event(io, &evt)
        if not capturing then
          windowing:_convert_and_push(&evt)
        end
      end
      return not_closed
    end
  end

  if options.style == false then
    terra ImGuiContext:_init_style()
      -- don't do anything
    end
    terra ImGuiContext:_init_colors()
      -- also don't do anything
    end
  else
    local styling = require("./styling.t")
    terra ImGuiContext:_init_style()
      styling.set_truss_style_defaults()
    end
    local color_setter = styling.build_color_setter()
    local colorspaces = require("math/colorspaces.t")
    terra ImGuiContext:_init_colors()
      if self.n_reference_colors == 0 then return end
      color_setter(self.reference_colors)
    end
    terra ImGuiContext:push_color(color: &float)
      if self.n_reference_colors >= 4 then return end
      var startidx = self.n_reference_colors*4
      for offset = 0, 4 do
        self.reference_colors[startidx + offset] = color[offset]
      end
      colorspaces.rgb2lab(self.reference_colors + startidx, 
                          self.reference_colors + startidx, true)
      self.n_reference_colors = self.n_reference_colors + 1
    end
  end

  terra ImGuiContext:init()
    self.clipboard_text = nil
    for i = 0, 3 do self.mouse_pressed[i] = false end
    for i = 0, FONTCOUNT do
      self.fonts[i].data = nil
      self.fonts[i].datasize = 0
      self.fonts[i].fontsizemod = 0.0
      self.fonts[i].fontname = nil
    end
    self.fontcount = 0
    self.n_reference_colors = 0
    for i = 0, 16 do self.reference_colors[i] = 0.0 end
  end

  terra ImGuiContext:push_font(data: &uint8, datasize: uint32, sizemod: float)
    var idx = self.fontcount
    if idx >= FONTCOUNT then return end
    self.fonts[idx].data = data
    self.fonts[idx].datasize = datasize
    self.fonts[idx].fontsizemod = sizemod
    self.fontcount = self.fontcount + 1
  end

  terra ImGuiContext:create(width: int32, height: int32, fontsize: float, viewid: uint16)
    self.width = width
    self.height = height
    self.viewid = viewid
    self.fontsize = fontsize
    if self.fontcount > 0 then
      IG.BGFXCreateWithFonts(self.fontsize, self.fonts, self.fontcount)
    else
      IG.BGFXCreate(self.fontsize)
    end
    self:_init_bindings()
    self:_init_style()
    self:_init_colors()
  end

  terra ImGuiContext:begin_frame()
    self:_pre_frame_update()
    IG.BGFXBeginFrame(self.width, self.height, self.viewid)
  end

  terra ImGuiContext:end_frame()
    IG.BGFXEndFrame()
  end

  return ImGuiContext
end

-- imgui expects you to keep fonts resident in memory forever so do that
m._memory_leaked_fonts = {}

function m.create_default_context(options)
  options = options or {}
  local w, h = options.width, options.height
  if not (w and h) then
    local gfx = require("gfx")
    w, h = gfx.backbuffer_width, gfx.backbuffer_height
  end
  local fontsize = options.fontsize or 18
  local viewid = options.viewid or 255
  local ImGuiContext = m.build{
    Windowing = require("input/windowing.t").Windowing,
    SDL = require("input/sdl.t") 
  }
  local ctx = terralib.new(ImGuiContext)
  ctx:init()
  local fontpath = options.font
    or truss.fs.joinpath(truss.binary_dir, "font/FiraSans-Regular.ttf")
  local fira = assert(truss.fs.read_buffer(fontpath), 
                      "Couldn't read font: " .. fontpath)
  table.insert(m._memory_leaked_fonts, fira)
  log.debug("font:", fira.data, fira.size)
  ctx:push_font(fira.data, fira.size, 0.0)

  if options.colors then
    local colorspaces = require("math/colorspaces.t")
    assert(#options.colors == 4, "Need to provide exactly four colors!")
    local ccol = terralib.new(float[4])
    for idx, color in ipairs(options.colors) do
      local fcolor = colorspaces.parse_color_to_rgbf(color)
      for chan = 0, 3 do
        ccol[chan] = fcolor[chan+1] or 0.0
      end
      ctx:push_color(ccol)
    end
  end

  ctx:create(w, h, fontsize, viewid)
  return ctx
end

return m