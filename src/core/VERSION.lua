local VERSION = {
  VERSION = "0.3.1",
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

return VERSION
