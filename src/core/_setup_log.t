local function install(core)
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
  local term = core._declare_builtin("term")
  core.term = term

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

  local log = core._declare_builtin("log", {
    enabled = {all = true}, --debug = false, path = false, perf = false}, 
    _enabled_stack = core.Stack(),
    printing_to_term = true
  })

  function log.push_scope()
    log._enabled_stack:push(log.enabled)
    log.enabled = core.extend_table({}, log.enabled)
  end

  function log.pop_scope()
    log.enabled = log._enabled_stack:pop() or {}
  end

  function log.clear_enabled()
    log.enabled = {}
  end

  function log.set_enabled(enabled)
    for _, level in ipairs(enabled) do
      if level:sub(1,1) == "~" then
        log.enabled[level:sub(2,-1)] = false
      else
        log.enabled[level] = true
      end
    end
  end

  core.log = log
  log.colors = {
    alert = term.color(term.BLACK, term.WHITE),
    warn = term.color(term.YELLOW),
    bigwarn = term.color(term.BLACK, term.YELLOW),
    build = term.color(term.YELLOW),
    xbuild = term.color(term.BLACK, term.YELLOW),
    error = term.color(term.RED),
    fatal = term.color(term.BLACK, term.RED),
    todo = term.color(term.BLACK, term.YELLOW),
    info = term.boldcolor(term.CYAN),
    crit = term.color(term.BLACK, term.CYAN),
    debug = term.color(term.MAGENTA),
    path = term.color(term.MAGENTA),
    perf = term.color(term.CYAN),
    pkg = term.color(term.MAGENTA)
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

  function log.pcall(f, ...)
    local args = {...}
    local _err = nil
    local _res = {xpcall(
      function()
        return f(unpack(args))
      end,
      function(err)
        _err = err
        log.fatal(err)
        log.fatal(debug.traceback())
      end
    )}
    if not _res[1] then
      _res[2] = _err
    end
    return unpack(_res)
  end

  -- use default lua error handling
  core.error = error

  local fancy_tag = term.color(term.BLACK, term.CYAN) .. 
    "[ truss " .. core.version .. " " .. core.version_emoji .. " ]" .. term.RESET
  log("crit", fancy_tag .. " on Terra " .. terralib.version .. " / " .. jit.version)
  log.info(
    "OS: " .. (jit.os or "?") .. 
    "; ARCH: " .. (jit.arch or "?") .. 
    "; LLVM: " .. (terralib.llvm_version or 0)/10)

end

return {install = install}
