-- download and extract truss libs
--
-- (mainly useful for CI situations, since you can use
--  truss itself to run this)

local LIB_URL_PATH = "https://github.com/PyryM/trusslibs/releases/download/v0.0.1-test3/"
local ZIP_NAMES = {
  Windows = "trusslibs_windows-latest.zip",
  Linux = "trusslibs_ubuntu-latest.zip"
}

local function exec_cmd(cmd)
  print(cmd, "-->")
  local f = io.popen(cmd, 'r')
  local s = f:read('*a')
  f:close()
  print(s)
end

function init()
  local libs_url = LIB_URL_PATH .. assert(ZIP_NAMES[truss.os], "No prebuilt libs for current OS!")
  exec_cmd(('curl -o libs.zip -L "%s"'):format(libs_url))
  exec_cmd('unzip libs.zip')
  if truss.os == "Windows" then
    exec_cmd('del libs.zip')
  else
    exec_cmd('rm libs.zip')
  end
end