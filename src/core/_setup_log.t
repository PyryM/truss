if jit.os == "Windows" then
  -- Make sure the Windows console is set to use the Unicode codepage
  -- (so that we can print emojis)
  --
  -- This is equivalent to `os.execute("chcp 65001")` except it doesn't
  -- leave an annoying message in the terminal.
  local UNICODE_CODEPAGE = 65001
  local winapi = terralib.includecstring[[
  #include <stdint.h>
  typedef uint32_t UINT;
  typedef int BOOL;
  BOOL SetConsoleOutputCP(UINT wCodePageID);
  ]]
  winapi.SetConsoleOutputCP(UNICODE_CODEPAGE)
end

-- "Control Sequence Inducer"
local term = truss._declare_builtin("term")

local CSI = string.char(27) .. "["
function term.sgr(...)
  -- "Set Graphics Rendition"
  return CSI .. table.concat({...}, ";") .. "m"
end

term.RESET = term.sgr(0)

-- 16 color fg/bg
function term.color(fg, bg)
  return term.sgr(30 + fg, bg and (40 + bg))
end

function term.boldcolor(fg, bg)
  return term.sgr(1, 30 + fg, bg and (40 + bg))
end

function term.color_rgb(fg_rgb, bg_rgb)
  local c = term.sgr(38, 2, unpack(fg_rgb))
  if bg_rgb then c = c .. term.sgr(48, 2, unpack(bg_rgb)) end
  return c
end

local colornames = {
  "BLACK", "RED", "GREEN", "YELLOW", 
  "BLUE", "MAGENTA", "CYAN", "WHITE"
}
for idx, name in ipairs(colornames) do
  term[name] = idx-1
end

function term.pad(s, n, fill)
  fill = fill or " "
  if #s < n then
    local pre = 1
    local post = (n - #s) - pre
    s = fill:rep(pre) .. s .. fill:rep(post)
  end
  return s
end

function term.padtag(s, n)
  return "[" .. term.pad(s, n or 7) .. "]"
end

-- log can remain a global for now
log = truss._declare_builtin("log", {
  enabled = {all = true, debug = false, path = false, perf = false}, 
  printing_to_term = true
})
log.colors = {
  alert = term.color(term.BLACK, term.WHITE),
  warn = term.color(term.YELLOW),
  bigwarn = term.color(term.BLACK, term.YELLOW),
  build = term.color(term.YELLOW),
  error = term.color(term.RED),
  fatal = term.color(term.BLACK, term.RED),
  todo = term.color(term.BLACK, term.YELLOW),
  info = term.boldcolor(term.CYAN),
  crit = term.color(term.BLACK, term.CYAN),
  debug = term.color(term.MAGENTA),
  path = term.color(term.MAGENTA),
  perf = term.color(term.CYAN),
}
log.colortags = {}
for name, color in pairs(log.colors) do
  log.colortags[name] = color .. term.padtag(name) .. term.RESET
end

local function stringify_args(...)
  local nargs = select('#', ...)
  local frags = {}
  for i = 1, nargs do
    frags[i] = tostring(select(i, ...))
  end
  return table.concat(frags, " ")
end

function log.log(level, ...)
  local enabled = log.enabled[level]
  if enabled == nil then enabled = log.enabled['all'] end
  if not enabled then return end
  if log.logfile then
    log.logfile:write("[" .. level .. "] " .. table.concat({...}, " "))
  end
  if not log.printing_to_term then return end
  local tag = log.colortags[level] or ("[" .. level .. "]")
  print(tag, ...)
end

for level, _ in pairs(log.colors) do
  assert(level ~= "log", "A log level cannot be named 'log'!")
  log[level] = function(...) log.log(level, stringify_args(...)) end
end

setmetatable(log, {
  __call = function(_log, ...)
    return _log.log(...)
  end
})

-- use default lua error handling
truss.error = error

local fancy_tag = term.color(term.BLACK, term.CYAN) .. 
  "[ truss " .. truss.version .. " " .. truss.version_emoji .. " ]" .. term.RESET
log("crit", fancy_tag .. " on Terra " .. terralib.version .. " / " .. jit.version)
log.info("OS: " .. (jit.os or "?") .. "; ARCH: " .. (jit.arch or "?"))
