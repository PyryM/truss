local function install(truss)
  local log = truss.log
  if not truss.GLOBALS._TRUSS_RUNNING then return end

  local args = truss.GLOBALS._TRUSS_ARGS
  truss.args = args or {}

  local main_module
  if args then
    main_module = args[2] or "main"
    if truss.config and truss.config.entrypoints[main_module] then
      main_module = truss.config.entrypoints[main_module]
    end
    log.info("Main entrypoint:", tostring(main_module))
  end

  if main_module then
    truss.main = truss.require(main_module)
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

  local function on_update(f)
    rawset(_G, '_core_update', f)
  end

  -- the true quit function
  local function _truss_quit()
    log.info("Shutdown: calling cleanup functions")
    for _, f in pairs(truss._cleanup_functions) do f() end
    if _TRUSS_RETURN_CODE ~= 0 then
      log.error("Error code: [" .. tostring(_TRUSS_RETURN_CODE) .. "]")
    end
    _TRUSS_RUNNING = false
    on_update(nil)
    log.info("💤 Goodbye.")
  end

  -- gracefully quit truss with an optional error code
  function truss.quit(code)
    log.info("Shutdown requested from Lua")
    if code then _TRUSS_RETURN_CODE = code end
    on_update(_truss_quit)
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
    on_update(function() guarded_call(truss.main.update) end)
  else
    log.info("Main has no 'update', just stopping.")
    truss.quit(init_retval)
  end
end

return {install = install}
