-- dev/miniconsole.t
--
-- a console that displays using the bgfx debug text

local m = {}
local stringutils = require("util/string.t")
local class = require("class")
local bgfx = require("gfx/bgfx.t")

m.colors = {
  default = 0x8f,
  error = 0x83,
  edit = 0x70,
  edit_inverse = 0x07,
  command = 0x87,
  header = 0x6f
}

m.header_size = 3
m.scroll_char = string.char(254)

local function bg_print(x, y, color, string)
  bgfx.dbg_text_printf(x, y, color, "%s", string)
end

-- take over view 0
function m.hijack_bgfx()
  local gfx = require("gfx")
  local window_w, window_h = gfx.backbuffer_width, gfx.backbuffer_height
  m.width, m.height = window_w, window_h

  m.fb_backbuffer = terralib.new(bgfx.frame_buffer_handle_t)
  m.fb_backbuffer.idx = bgfx.INVALID_HANDLE
  bgfx.set_view_rect(0, 0, 0, window_w or 640, window_h or 480)
  bgfx.set_view_clear(0, -- viewid 0
          bgfx.CLEAR_COLOR + bgfx.CLEAR_DEPTH,
          0x000000ff, -- clearcolor (black)
          1.0, -- cleardepth (in normalized space: 1.0 = max depth)
          0)
  bgfx.set_view_frame_buffer(0, m.fb_backbuffer)
  bgfx.set_debug(bgfx.DEBUG_TEXT)
end

function m._keydown(keyname, modifiers)
  local keybinds = {
    Backspace = m._backspace,
    Return = m._execute,
    Left = m._left,
    Right = m._right,
    Up = m._up,
    Down = m._down,
    PageUp = m._pageup,
    PageDown = m._pagedown
  }
  if keybinds[keyname] then keybinds[keyname]() end
end

function m._up()
  if m._history_pos <= 0 then
    m._history_pos = #(m._edit_history)
  else
    m._history_pos = math.max(1, m._history_pos - 1)
  end

  m._editline = m._edit_history[m._history_pos] or ""
  m._cursor_pos = #(m._editline)
end

function m._down()
  m._history_pos = m._history_pos + 1
  if m._history_pos <= 0 or m._history_pos > #(m._edit_history) then
    m._history_pos = -1
    m._editline = ""
  else
    m._editline = m._edit_history[m._history_pos] or ""
  end
  m._cursor_pos = #(m._editline)
end

function m._pageup()
  m._buffer_pos = math.max(0, m._buffer_pos - 10)
end

function m._pagedown()
  m._buffer_pos = math.min(#(m._linebuffer), m._buffer_pos + 10)
end

function m._textinput(tstr)
  if m._cursor_pos >= #(m._editline) then
    m._editline = m._editline .. tstr
    m._cursor_pos = #m._editline
  else
    local prev = m._editline:sub(1,m._cursor_pos)
    local rem = m._editline:sub(m._cursor_pos+1, -1)
    m._editline = prev .. tstr .. rem
    m._cursor_pos = m._cursor_pos + 1
  end
end

function m._backspace()
  if m._editline:len() <= 0 or m._cursor_pos <= 0 then return end

  if m._cursor_pos >= #(m._editline) then
    m._editline = string.sub(m._editline, 1, -2)
    m._cursor_pos = #m._editline
  else
    local prev = m._editline:sub(1,m._cursor_pos-1)
    local rem = m._editline:sub(m._cursor_pos+1, -1)
    m._editline = prev .. rem
    m._cursor_pos = m._cursor_pos - 1
  end
end

function m._left()
  m._cursor_pos = math.max(0, m._cursor_pos - 1)
end

function m._right()
  m._cursor_pos = math.min(m._cursor_pos + 1, #m._editline)
end

m.downkeys = {}

function m.handle_inputs()
  local SDL = require("input/sdl.t")
  if not m._raw_evt then
    m._raw_evt = terralib.new(SDL.Event)
  end
  local evt = m._raw_evt
  while SDL.PollEvent(evt) > 0 do
    local etype = evt.type
    if etype == SDL.WINDOWEVENT and evt.window.event == 14 then
      truss.quit()
    elseif etype == SDL.KEYDOWN or etype == SDL.KEYUP then
      local keyname = ffi.string(SDL.GetKeyName(evt.key.keysym.sym))
      if etype == SDL.KEYDOWN then
        if not m.downkeys[keyname] then
          m.downkeys[keyname] = true
          m._keydown(keyname, evt.flags)
        end
      else -- keyup
        m.downkeys[keyname] = false
      end
    elseif etype == SDL.TEXTINPUT then
      local input = ffi.string(evt.text.text) -- length limit?
      m._textinput(input)
    end
  end
end

function m.print_colors()
  for i = 0,15 do
    m.print(tostring(i), nil, i)
  end
end

function m._draw_position_bar()
  local fp = m._buffer_pos / (#(m._linebuffer) - m.height)
  local p = math.min(m.height - 1, math.ceil(m.height * fp))
  local nheader = #(m._headerlines)
  local bar = string.char(179)
  for i = 0,(m.height-1) do
    local c = bar
    if i == p then c = m.scroll_char end
    bg_print(m.width-1, i + nheader + 1, m.colors.edit_inverse, c)
  end
end

function m.debug_print_lines()
  bgfx.dbg_text_clear(0, false)
  local headersize = #(m._headerlines) + 1
  for idx, headerline in ipairs(m._headerlines) do
    bg_print(0, idx-1, m.colors.header, headerline or "?")
  end
  for i = 0,m.height-1 do
    local lineinfo = m._linebuffer[m._buffer_pos + i] or {}
    local text, color = lineinfo[1] or "", lineinfo[2] or m.colors.default
    local ppos = text:len()
    local padding = m._paddings[m.width - ppos] or ""
    bg_print(0, i+headersize, color, text)
    bg_print(ppos, i+headersize, color, padding)
  end
  local fp = m._editline:sub(1, m._cursor_pos)
  local cp = m._editline:sub(m._cursor_pos+1, m._cursor_pos+1)
  if not cp or cp == "" then cp = " " end
  local rp = m._editline:sub(m._cursor_pos+2,-1)
  local editpad = m._paddings[m.width - (fp:len()+cp:len()+rp:len()+2)] or ""
  bg_print(0, m.height+headersize, m.colors.edit, ">" .. fp .. editpad)
  bg_print(#(fp)+1, m.height+headersize, m.colors.edit_inverse, cp)
  bg_print(#(fp)+2, m.height+headersize, m.colors.edit, rp .. editpad)
  m._draw_position_bar()
end

function m.update()
  m.handle_inputs()
  m.debug_print_lines()
  if m.webconsole then m.webconsole.update() end
  bgfx.touch(0)
  bgfx.frame(false)
end

function m.attach_webconsole()
  if m.webconsole then return true end
  local webconsole = require("dev/webconsole.t")
  if webconsole then
    local connected = webconsole.start()
    if connected then
      m.webconsole = webconsole
      m.divider()
      m.print("Webconsole connected")
      m.divider()
    else
      m.print("Webconsole: connection error", m.colors.error)
    end
  else
    m.print("Webconsole: dev/webconsole.t not present", m.colors.error)
  end
end

function m._wrap_overlong(s, ret)
  local remainder = s
  local lw = m.width - 1
  while remainder:len() > lw do
    local front = remainder:sub(1,lw)
    remainder = remainder:sub(lw+1,-1)
    table.insert(ret, front)
  end
  table.insert(ret, remainder)
end

function m._wrap_lines(s)
  local ret = {}
  local lines = stringutils.split_lines(s)
  for _, line in ipairs(lines) do
    m._wrap_overlong(line, ret)
  end
  return ret
end

function m.set_header(line)
  m._headerlines = m._wrap_lines(line)
  m.height = m.totalHeight - 2 - #(m._headerlines)
end

function m.print_same_line(line)
  local info = m._linebuffer[#m._linebuffer]
  info[1] = info[1] .. line
end

function m.print(line, fg, bg)
  local color = fg or m.colors.default
  if bg then
    color = (fg or 0) + 16*(bg or 8)
  end
  local splitlines = m._wrap_lines(tostring(line))
  for _, line in ipairs(splitlines) do
    table.insert(m._linebuffer, {line, color})
  end
  if #m._linebuffer >= m.height-1 then
    m._buffer_pos = m._buffer_pos + #(splitlines)
  end
end

function m.repl_load(code)
  local print_wrapped_code = "print('=> ' .. tostring((" .. code .. ") or nil))"
  local codefunc, loaderror = terralib.loadstring(print_wrapped_code)
  if codefunc then 
    return codefunc 
  else -- can't do 'codefunc or loadstring' because multiple return values
    return terralib.loadstring(code)
  end
end

function m.eval(code)
  local codefunc, loaderror = m.repl_load(code) --terralib.loadstring(code)
  if codefunc then
    setfenv(codefunc, m.env)
    local succeeded, ret = pcall(codefunc)
    if succeeded then
      if ret then m.print(tostring(ret)) end
    else
      m.print("Error: " .. tostring(ret), m.colors.error)
    end
  else
    m.print("Parse error: " .. loaderror, m.colors.error)
  end
end

function m.divider()
  m.print(string.rep("-", m.width-1))
end

function m.print_mini_help()
  m.print("Miniconsole")
  m.divider()
  m.print("help() for help [this message]")
  m.print("info(thing) to pretty-print info")
  m.print("print(str, fg_color, bg_color) to print to this console")
  m.print("gfx_features() to list supported bgfx caps on this device")
  m.print("colors() for pretty colors")
  m.print("truss.quit() or quit() to quit [or just close the window]")
  m.print("remote() or rc() to connect to remote console")
  m.print("resume() to resume [warning! very wonky!]")
  m.print("log() to show the log")
  m.print("pageup / pagedown to see history")
  m.print("clear() to clear")
  m.print("div() or divider() to create a divider")
  m.print("trace() to get traceback at error")
  m.print("save([filename]) to save this console buffer to a text file")
  m.divider()
end

function m.print_chars()
    for i = 0,255 do m.print(i .. " = " .. string.char(i)) end
end

function m.create_env()
  m.ct = require("dev/consoletools.t").ConsoleTools{print = m.print,
                                                         width = m.width}

  m.env = {}
  m.env.mainobj = truss.mainobj
  m.env.mainenv = truss.mainenv
  m.env.loaded_libs = truss._loaded_libs
  m.env.G = _G

  -- copy over the 'clean' subenvironment
  for k,v in pairs(truss.clean_subenv) do
    m.env[k] = v
  end

  -- make print be our remote print
  m.env.raw_print = print
  m.env.print = m.print
  m.env.info = m.ct:wrap("info")
  m.env.gfx_features = m.ct:wrap("gfx_features")
  m.env.colors = m.print_colors
  m.env.chars = m.print_chars
  m.env.help = m.print_mini_help
  m.env.rc = m.attach_webconsole
  m.env.remote = m.attach_webconsole
  m.env.resume = truss.resume_from_error
  m.env.quit = truss.quit
  m.env.printlog = m.dumplog
  m.env.log = m.dumplog
  m.env.clear = m.clear
  m.env.div = m.divider
  m.env.divider = m.divider
  m.env.trace = m.trace
  m.env.save = m.save_console_buffer
  m.env.m = truss.mainenv
  m.env.app = (truss.mainenv or {}).app
  m.env.minicon = m
end

function m.trace()
  m.print(truss.error_trace)
end

function m.clear()
  m._buffer_pos = 0
  m._linebuffer = {}
end

m._logcolors = {
  ["[0]"] = 0x90,
  ["[1]"] = 0x89,
  ["[2]"] = 0x83,
  ["[3]"] = 0x8c,
  ["[4]"] = 0x8a
}

function m.dumplog()
  local loglines = truss.load_string_from_file("trusslog.txt")
  if not loglines then
    m.print("Couldn't load trusslog.txt", m.colors.error)
    return
  end
  local lines = stringutils.split_lines(loglines)
  for _, line in ipairs(lines) do
    local prefix = line:sub(1,3)
    m.print(line, m._logcolors[prefix])
  end
end

function m.save_console_buffer(filename)
  filename = filename or "console_log.txt"
  truss.C.set_fs_savedir("/")
  local lines = {}
  for i,line in ipairs(m._linebuffer) do
    lines[i] = line[1]
  end
  local str = table.concat(lines, "\n")
  truss.C.save_data(filename, str, str:len())
end

function m._execute()
  m.print(">>" .. m._editline, m.colors.command)
  m._buffer_pos = math.max(0, #m._linebuffer - m.height + 1)
  if m.exec_callback then
    m.exec_callback(m._editline)
  else
    m.eval(m._editline)
  end
  if m._editline ~= m._edit_history[#(m._edit_history)] then
    table.insert(m._edit_history, m._editline)
  end
  m._history_pos = -1
  m._editline = ""
  m._cursor_pos = 0
end

function m.init(width, height)
  m.width = width or 80
  m._headerlines = {}
  m.totalHeight = height or 30
  m.height = m.totalHeight - 2 - #(m._headerlines)
  m._buffer_pos = 0
  m._linebuffer = {}
  m._history_pos = -1
  m._edit_history = {}
  m._editline = ""
  m._paddings = {}
  m._cursor_pos = 0
  local padding = ""
  for i = 0,m.width do
    m._paddings[i] = padding
    padding = padding .. " "
  end
  m.create_env()
  local SDL = require("input/sdl.t")
  SDL.StartTextInput()
end

function m.install()
  if truss.mainenv.fallback_update then
    log.info("miniconsole.install : fallback already present.")
    return
  end

  truss.mainenv.fallback_update = m.fallback_update
end

function m.fallback_update()
  local gfx = require('gfx')
  if not gfx.backend_name then
    log.info("No graphics initted, no choice but to quit.")
    log.info(truss.error_trace)
    truss.quit()
    return
  end

  if not m._booted then
    m.hijack_bgfx()
    m.init(math.floor(m.width / 8), math.floor(m.height / 16))
    m.set_header("Something broke: " .. truss.crash_message, 0x83)
    m.print_mini_help()
    m.trace()
    m._booted = true
  end

  m.update()
end

local ConsoleApp = class("ConsoleApp")
m.ConsoleApp = ConsoleApp

function ConsoleApp:init(options)
  options = options or {}
  self.window = require("input/windowing.t").create()
  self.window:create_window(
    options.width or 1280,
    options.height or 720,
    options.title or "Console",
    false, -- fullscreen
    0      -- display
  )
  local gfx = require("gfx")
  gfx.init_gfx({debugtext = true, window = self.window})
  m.hijack_bgfx()
  m.init(math.floor(m.width / 8), math.floor(m.height / 16))
  m.set_header(options.title or "Console", options.header_color or 0x83)
  if options.print_help ~= false then m.print_mini_help() end
  self.env = m.env
end

function ConsoleApp:print_same_line(text)
  m.print_same_line(text)
end

function ConsoleApp:print(text, fg, bg)
  m.print(text, fg, bg)
end

function ConsoleApp:clear()
  m.clear()
end

function ConsoleApp:update()
  m.update()
end

return m
