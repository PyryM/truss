if _MAIN_MODULE then
  truss.main = require(_MAIN_MODULE)
end

if not truss.main then 
  log.info("No main module to run.")
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
  end
  os.exit(_quit_code)
end

local _core_init, _core_update

-- gracefully quit truss with an optional error code
function truss.quit(code)
  log.info("Shutdown requested from Lua")
  _quit_code = code
  _core_update = _truss_quit
  _fallback_update = _truss_quit
end

_core_init = function()
  truss.main.init()
end

_core_update = function()
  truss.main.update()
end
