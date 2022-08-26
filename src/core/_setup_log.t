if jit.os == "Windows" then
  -- change to unicode codepage so that unicode prints work!
  os.execute("chcp 65001")
end

-- "Control Sequence Inducer"
local term = {}
truss.term = term

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

local function padtag(s)
  if #s < 7 then
    local pre = 1
    local post = (7 - #s) - pre
    s = (" "):rep(pre) .. s .. (" "):rep(post)
  end
  return "[" .. s .. "]"
end

log = {ignored = {}}
log.colors = {
  warn = term.color(term.YELLOW),
  build = term.color(term.YELLOW),
  error = term.color(term.RED),
  fatal = term.color(term.BLACK, term.RED),
  todo = term.color(term.BLACK, term.YELLOW),
  info = term.color(term.CYAN),
  crit = term.color(term.BLACK, term.CYAN),
  debug = term.color(term.MAGENTA),
}
log.colortags = {}
for name, color in pairs(log.colors) do
  log.colortags[name] = color .. padtag(name) .. term.RESET
end

local function stringify_args(...)
  local nargs = select('#', ...)
  local frags = {}
  for i = 1, nargs do
    frags[i] = tostring(select(i, ...))
  end
  return table.concat(frags, " ")
end

function truss.log(level, ...)
  if log.ignored[level] then return end
  if log.logfile then
    log.logfile:write("[" .. level .. "] " .. table.concat({...}, " "))
  end
  local tag = log.colortags[level] or ("[" .. level .. "]")
  print(tag, ...)
end

for level, _ in pairs(log.colors) do
  log[level] = function(...) truss.log(level, stringify_args(...)) end
end

-- use default lua error handling
truss.error = error

local fancy_tag = term.color(term.BLACK, term.CYAN) .. 
  "[ truss " .. truss.version .. " ]" .. term.RESET
log.crit(fancy_tag, "on Terra", terralib.version, "/", jit.version)
