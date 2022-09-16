-- build/system_compiler_version.t
--
-- get information about system compiler on various platforms
-- can also be executed as a main script in which case it just
-- prints the information to the terminal

local build = require("build/build.t")
local m = {}

local info = nil

function m.get_compiler_info()
  if info then return info end
  info = {}
  local jit = require("jit")
  if build.is_native() and jit.os == "Windows" then
    local c = build.includecstring[[
    int msvc_version() {
      return _MSC_VER;
    }
    ]]
    info.compiler = "MSVC"
    info.version = c.msvc_version()
  else
    error("Compiler info NYI for " .. jit.os)
  end

  return info
end

function m.init()
  local info = m.get_compiler_info()
  log.crit(info.compiler, info.version)
end

return m
