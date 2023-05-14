local VERSION = {
  VERSION = "0.4.0α",
  VERSION_EMOJI = "⚗️",
}

function VERSION:check()
  if self.VERSION ~= truss.version then
    log.bigwarn("truss binary is out of date! Consider rebuilding!")
    log.bigwarn("compiled version:", truss.version, truss.version_emoji)
    log.bigwarn("loose version:", self.VERSION, self.VERSION_EMOJI)
    return false
  end
  return true
end

function VERSION.install(core)
  core.version, core.version_emoji = VERSION.VERSION, VERSION.VERSION_EMOJI
end

function VERSION.main()
  log.push_scope()
  log.set_enabled{"~debug", "~pkg"}
  if VERSION:check() then
    log.crit("truss binary and packages are consistent")
  end
end

return VERSION
