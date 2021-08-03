-- gfx/imgui.t
--
-- imgui

local modutils = require("core/module.t")
local class = require("class")
local clib = require("native/clib.t")
local m = {}

local imgui_c_raw = terralib.includec("bgfx/cimgui.h")
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
  local struct ImGuiContext {
    width: int32;
    height: int32;
    viewid: uint16;
    fontsize: float;
    mouse_pressed: bool[3];
    clipboard_text: &int8;
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
      -- Dear ImGui will use those indices to peek into the io.KeysDown[] array.
      var io = IG.GetIO()
      io.KeyMap[IG.Key_Tab] = SDL.SCANCODE_TAB
      io.KeyMap[IG.Key_LeftArrow] = SDL.SCANCODE_LEFT
      io.KeyMap[IG.Key_RightArrow] = SDL.SCANCODE_RIGHT
      io.KeyMap[IG.Key_UpArrow] = SDL.SCANCODE_UP
      io.KeyMap[IG.Key_DownArrow] = SDL.SCANCODE_DOWN
      io.KeyMap[IG.Key_PageUp] = SDL.SCANCODE_PAGEUP
      io.KeyMap[IG.Key_PageDown] = SDL.SCANCODE_PAGEDOWN
      io.KeyMap[IG.Key_Home] = SDL.SCANCODE_HOME
      io.KeyMap[IG.Key_End] = SDL.SCANCODE_END
      io.KeyMap[IG.Key_Insert] = SDL.SCANCODE_INSERT
      io.KeyMap[IG.Key_Delete] = SDL.SCANCODE_DELETE
      io.KeyMap[IG.Key_Backspace] = SDL.SCANCODE_BACKSPACE
      io.KeyMap[IG.Key_Space] = SDL.SCANCODE_SPACE
      io.KeyMap[IG.Key_Enter] = SDL.SCANCODE_RETURN
      io.KeyMap[IG.Key_Escape] = SDL.SCANCODE_ESCAPE
      io.KeyMap[IG.Key_KeyPadEnter] = SDL.SCANCODE_KP_ENTER
      io.KeyMap[IG.Key_A] = SDL.SCANCODE_A
      io.KeyMap[IG.Key_C] = SDL.SCANCODE_C
      io.KeyMap[IG.Key_V] = SDL.SCANCODE_V
      io.KeyMap[IG.Key_X] = SDL.SCANCODE_X
      io.KeyMap[IG.Key_Y] = SDL.SCANCODE_Y
      io.KeyMap[IG.Key_Z] = SDL.SCANCODE_Z
      --SDL.SetHint(SDL.HINT_MOUSE_FOCUS_CLICKTHROUGH, "1")
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
          io.KeysDown[key] = (event.type == SDL.KEYDOWN)
          io.KeyShift = ((SDL.GetModState() and SDL.KMOD_SHIFT) ~= 0)
          io.KeyCtrl = ((SDL.GetModState() and SDL.KMOD_CTRL) ~= 0)
          io.KeyAlt = ((SDL.GetModState() and SDL.KMOD_ALT) ~= 0)
          escape
            if truss.os == 'Windows' then
              emit quote io.KeySuper = false end
            else
              emit quote 
                io.KeySuper = ((SDL.GetModState() and SDL.KMOD_GUI) ~= 0) 
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

  terra ImGuiContext:init(width: int32, height: int32, fontsize: float, viewid: uint16)
    self.width = width
    self.height = height
    self.viewid = viewid
    self.fontsize = fontsize
    self.clipboard_text = nil
    for i = 0, 3 do self.mouse_pressed[i] = false end
    IG.BGFXCreate(self.fontsize)
    self:_init_bindings()
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

function m.create_default_context(w, h, fontsize, viewid)
  local ImGuiContext = m.build{
    Windowing = require("input/windowing.t").Windowing,
    SDL = require("input/sdl.t") 
  }
  local ctx = terralib.new(ImGuiContext)
  ctx:init(w, h, fontsize or 18, viewid or 255)
  return ctx
end

return m