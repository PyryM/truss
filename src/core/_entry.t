local function entry(truss)
  local log = truss.log
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

  if not truss.GLOBALS._TRUSS_RUNNING then return end
  if not truss.config then
    log.warn("truss not configured, not running entry")
    _TRUSS_RUNNING = false
    return
  end

  local args = truss.GLOBALS._TRUSS_ARGS or {}
  truss.args = args

  local entry_name = args[2] or "DEFAULT"
  log.info("entrypoint:", tostring(entry_name))
  local entry_runner = truss.config.entry_runner
  if truss.config.entrypoints[entry_name] then
    entry_name = truss.config.entrypoints[entry_name]
  end
  if type(entry_name) == 'function' then
    entry_runner = entry_name
  end
    
  -- register a function to be called right before truss quits
  truss._cleanup_functions = {}
  function truss.on_quit(f)
    truss._cleanup_functions[f] = f
  end

  function truss.on_update(f)
    truss._update_func = f
  end

  -- the true quit function
  local function _truss_quit()
    log.info("Shutdown: calling cleanup functions")
    for _, f in pairs(truss._cleanup_functions) do f() end
    if _TRUSS_RETURN_CODE ~= 0 then
      log.error("Error code: [" .. tostring(_TRUSS_RETURN_CODE) .. "]")
    end
    _TRUSS_RUNNING = false
    truss.on_update(nil)
    log.info("💤 Goodbye.")
  end

  -- gracefully quit truss with an optional error code
  function truss.quit(code)
    log.info("Shutdown requested from Lua")
    if code then _TRUSS_RETURN_CODE = code end
    truss.on_update(_truss_quit)
  end

  rawset(_G, '_core_update', function(...)
    if truss._update_func then
      guarded_call(truss._update_func, ...)
    end
  end)


  local happy, init_retval = pcall(entry_runner, entry_name)
  if not happy then
    log.fatal("Error in entrypoint:" .. tostring(init_retval))
    _TRUSS_RUNNING = false
    return
  elseif init_retval == false then
    _TRUSS_RUNNING = false
    return
  end

  if not truss._update_func then
    log.info("No on_update was set, stopping.")
    truss.quit(init_retval)
  end
end

return {entry = entry}
