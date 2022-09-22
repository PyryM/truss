truss.args = _TRUSS_ARGS or {}

if _TRUSS_ARGS then
  _MAIN_MODULE = _TRUSS_ARGS[2] or "main"
  if truss.config and truss.config.entrypoints[_MAIN_MODULE] then
    _MAIN_MODULE = truss.config.entrypoints[_MAIN_MODULE]
  end
  log.info("Main entrypoint:", tostring(_MAIN_MODULE))
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
local function _truss_quit()
  log.info("Shutdown: calling cleanup functions")
  for _, f in pairs(truss._cleanup_functions) do f() end
  if _TRUSS_RETURN_CODE ~= 0 then
    log.error("Error code: [" .. tostring(_TRUSS_RETURN_CODE) .. "]")
  end
  _TRUSS_RUNNING = false
  _core_update = nil
  log.info("💤 Goodbye.")
end

-- gracefully quit truss with an optional error code
function truss.quit(code)
  log.info("Shutdown requested from Lua")
  if code then _TRUSS_RETURN_CODE = code end
  _core_update = _truss_quit
  _fallback_update = nil
end

local function guarded_call(f, ...)
  local args = {...}
  local happy, err = xpcall(
    function()
      return f(unpack(args))
    end,
    function(err)
      log.fatal(err)
      log.fatal(debug.traceback())
    end
  )
  if not happy then
    log.fatal("Uncaught exception at top level; stopping.")
    truss.quit(1)
  else
    return err
  end
end

local init_retval = guarded_call(truss.main.init)

if truss.main.update then
  _core_update = function()
    guarded_call(truss.main.update)
  end
else
  log.info("Main has no 'update', just stopping.")
  truss.quit(init_retval)
end
