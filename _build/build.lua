local TERRA_OS, ARCHIVE_EXT
local TERRA_RELEASE = "https://github.com/terralang/terra/releases/download/release-1.0.6"
local TERRA_HASH = "6184586"

if jit.os == "Windows" then
  -- https://github.com/terralang/terra/releases/download/release-1.0.6/terra-Windows-x86_64-6184586.7z
  TERRA_OS = "Windows-x86_64"
  ARCHIVE_EXT = "7z"
elseif jit.os == "Linux" and jit.arch == "x64" then
  -- https://github.com/terralang/terra/releases/download/release-1.0.6/terra-Linux-x86_64-6184586.tar.xz
  TERRA_OS = 
  ARCHIVE_EXT = "tar.xz"
else
  error("No Terra release for " .. jit.os .. " / " .. jit.arch)
end

local TERRA_NAME = ("terra-%s-%s"):format(TERRA_OS, TERRA_HASH)
local TERRA_URL = ("%s/%s.%s"):format(TERRA_RELEASE, TERRA_NAME, ARCHIVE_EXT)
print("Terra url:", TERRA_URL)

local function cmd(...)
  local str = table.concat({...}, " ")
  print("exec:", str)
  os.execute(str)
end

local function cd(path)
  cmd('cd', path)
end

local function mkdir(path)
  cmd('mkdir', path)
end

local function cp(src, dest)
  if jit.os == 'Windows' then
    cmd('xcopy /E', src, dest)
  else
    cmd('cp -r', src, dest)
  end
end

local function run(bin, ...)
  if jit.os = 'Windows' then
    cmd(bin, ...)
  else
    cmd("./" .. bin, ...)
  end
end

cmd 'sudo apt-get update -qq -y'
cmd 'sudo apt-get install -qq -y libtinfo-dev'
mkdir '_deps'
cd '_deps'
cmd(('curl -o terra.%s -L %s'):format(ARCHIVE_EXT, TERRA_URL))
if jit.os == "Windows" then
  cmd("7z e terra." .. ARCHIVE_EXT)
else
  cmd("tar -xvf terra." .. ARCHIVE_EXT)
end
cmd 'git clone https://github.com/pyrym/trussfs'
cd 'trussfs'
cmd 'cargo build --release'
cd '..'
cd '..'
mkdir 'include/terra'
cp('_deps/' .. TERRA_NAME .. '/include/*',  'include/')
cp('_deps/' .. TERRA_NAME .. '/lib/*', 'lib/')
cp('_deps/' .. TERRA_NAME .. '/bin/*', 'bin/')
cp('bin/terra', '.')
if jit.os == 'Windows' then
  cp('_deps/trussfs/target/release/*.dll', 'lib/')
  cp('_deps/trussfs/target/release/*.lib', 'lib/')
  -- unsure whether exp and pdb are actually useful in windows
  --[[
  cp('_deps/trussfs/target/release/*.exp', 'lib/')
  cp('_deps/trussfs/target/release/*.pdb', 'lib/')
  ]]
elseif jit.os == 'Linux' then
  cp('_deps/trussfs/target/release/*.so', 'lib/')
else
  -- OSX?
end
run('terra', 'src/build/selfbuild.t')
run('truss', 'dev/downloadlibs.t')
run('truss', 'dev/buildshaders.t')