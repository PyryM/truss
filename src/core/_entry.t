truss.args = _TRUSS_ARGS or {}

if _TRUSS_ARGS then
  _MAIN_MODULE = _TRUSS_ARGS[2] or "main.t"
end

if _MAIN_MODULE then
  truss.main = require(_MAIN_MODULE)
end

if not truss.main then 
  log.info("No main module to run.")
  _TRUSS_RUNNING = false
  return 
end

-- register a function to be called right before truss quits
truss._cleanup_functions = {}
function truss.on_quit(f)
  truss._cleanup_functions[f] = f
end

-- the true quit function
local _quit_code
local function _truss_quit()
  log.info("Shutdown: calling cleanup functions")
  for _, f in pairs(truss._cleanup_functions) do f() end
  if _quit_code and type(_quit_code) == "number" then
    log.info("Error code: [" .. tostring(_quit_code) .. "]")
    _TRUSS_RETURN_CODE = _quit_code
  end
  _TRUSS_RUNNING = false
end

-- gracefully quit truss with an optional error code
function truss.quit(code)
  log.info("Shutdown requested from Lua")
  _quit_code = code
  _core_update = _truss_quit
  _fallback_update = _truss_quit
  _TRUSS_RUNNING = false
end

local function guarded_call(f, ...)
  local happy, err = pcall(f, ...)
  if not happy then
    log.fatal(err)
    truss.quit(-1)
  end
end

guarded_call(truss.main.init)

if truss.main.update then
  _core_update = function()
    guarded_call(truss.main.update)
  end
else
  log.info("Main has no 'update', just stopping.")
  _TRUSS_RUNNING = false
end
