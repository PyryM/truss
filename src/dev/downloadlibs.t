-- download and extract truss libs
--
-- (mainly useful for CI situations, since you can use
--  truss itself to run this)

local LIB_URL_PATH = "https://github.com/PyryM/trusslibs/releases/download/v0.0.7-pre3/"
local ARCHIVE_NAMES = {
  Windows = "trusslibs_windows-latest.zip",
  Linux = "trusslibs_ubuntu-latest.zip"
}

local futil = require("util/file.t")

local function exec_cmd(cmd)
  log.debug(cmd, "-->")
  local f = io.popen(cmd, 'r')
  local s = f:read('*a')
  f:close()
  log.debug("result", s)
end

local function init()
  local libs_url = LIB_URL_PATH .. assert(ARCHIVE_NAMES[truss.os], "No prebuilt libs for current OS!")
  exec_cmd(('curl -o libs.zip -L "%s"'):format(libs_url))
  futil.extract_archive("libs.zip")
  if truss.os == "Windows" then
    exec_cmd('del libs.zip')
  else
    exec_cmd('rm libs.zip')
  end
 
  if jit.os == "Linux" then
    exec_cmd('chmod +x bin/*')
  end
end

return {init = init}