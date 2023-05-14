local m = {}

function m.repl_load(cmd)
  local res = loadstring("return " .. cmd)
  if res then return res end
  return loadstring(cmd)
end

function m.eval(cmd)
  local func, err = m.repl_load(cmd)
  if not func then
    log.fatal(err)
    return 1
  end
  local happy, res = pcall(func)
  if not happy then
    log.fatal(res)
    return 1
  else
    log.crit(cmd, "->", res)
    return 0
  end
end

function m.main()
  if not truss.args[3] then
    log.fatal("No input provided to dev/eval.t!")
    return 1
  end
  return m.eval(truss.args[3])
end

return m