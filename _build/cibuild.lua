local TERRA_OS, ARCHIVE_EXT
local TERRA_RELEASE = "https://github.com/terralang/terra/releases/download/release-1.1.0"
local TERRA_HASH = "be89521"
local OUTSCRIPT = "_build/build_generated.sh"

local TRUSSFS_URL = "https://github.com/PyryM/trussfs/releases/download/v0.2.0/"

if jit.os == "Windows" then
  -- https://github.com/terralang/terra/releases/download/release-1.0.6/terra-Windows-x86_64-6184586.7z
  TERRA_OS = "Windows-x86_64"
  ARCHIVE_EXT = "7z"
  TRUSSFS_URL = TRUSSFS_URL .. "trussfs_windows-latest.zip"
elseif jit.os == "Linux" and jit.arch == "x64" then
  -- https://github.com/terralang/terra/releases/download/release-1.0.6/terra-Linux-x86_64-6184586.tar.xz
  TERRA_OS = "Linux-x86_64"
  ARCHIVE_EXT = "tar.xz"
  TRUSSFS_URL = TRUSSFS_URL .. "trussfs_ubuntu-latest.zip"
else
  error("No Terra release for " .. jit.os .. " / " .. jit.arch)
end

local TERRA_NAME = ("terra-%s-%s"):format(TERRA_OS, TERRA_HASH)
local TERRA_URL = ("%s/%s.%s"):format(TERRA_RELEASE, TERRA_NAME, ARCHIVE_EXT)
print("Terra url:", TERRA_URL)

local outfile = io.open(OUTSCRIPT, "wt")

local function cmd(...)
  local str = table.concat({...}, " ")
  outfile:write(str .. "\n")
end

local function cd(path)
  cmd('cd', path)
end

local function mkdir(path)
  cmd('mkdir', path)
end

local function cp(src, dest)
  cmd('cp -r', src, dest)
end

local function run(bin, ...)
  -- if jit.os == 'Windows' then
  --   cmd(bin, ...)
  -- else
  cmd("./" .. bin, ...)
  -- end
end

if jit.os == "Linux" then
  cmd 'sudo apt-get update -qq -y'
  cmd 'sudo apt-get install -qq -y libtinfo-dev'
end
mkdir '_deps'
cd '_deps'
cmd(('curl -o terra.%s -L %s'):format(ARCHIVE_EXT, TERRA_URL))
cmd(('curl -o trussfs.zip -L %s'):format(TRUSSFS_URL))
if jit.os == "Windows" then
  cmd("7z x terra." .. ARCHIVE_EXT)
  cmd("7z x trussfs.zip")
else
  cmd("tar -xvf terra." .. ARCHIVE_EXT)
  cmd("unzip trussfs.zip")
end
cd '..'
mkdir 'include/terra'
mkdir 'lib'
mkdir 'bin'
cp('_deps/' .. TERRA_NAME .. '/include/*',  'include/')
cp('_deps/' .. TERRA_NAME .. '/lib/*', 'lib/')
cp('_deps/' .. TERRA_NAME .. '/bin/*', 'bin/')
cp('_deps/include/*',  'include/')
cp('_deps/lib/*', 'lib/')
if jit.os == 'Windows' then
  cmd('mv bin/terra.exe', '.')
  cmd('mv bin/terra.dll', '.')
  cmd('mv bin/lua51.dll', '.')
elseif jit.os == 'Linux' then
  cmd('mv bin/terra', '.')
else
  -- OSX?
end
run('terra', 'src/build/selfbuild.t')
run('truss', 'dev/downloadlibs.t')

outfile:close()

os.execute("chmod +x " .. OUTSCRIPT)
os.execute("bash " .. OUTSCRIPT)
