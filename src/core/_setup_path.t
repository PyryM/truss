local ffi = require("ffi")
if jit.os == "Windows" and #terralib.includepath <= 1 then
  -- assume Linux/OSX will have header files available
  -- assume include path is empty and add compat includes
  log.info("No system headers on include path: using bundled compat headers")
  terralib.includepath = terralib.includepath .. ";include;include/compat"
  truss.using_system_headers = false
else
  terralib.includepath = terralib.includepath .. ";include"
  truss.using_system_headers = true
end
log.info("Include path:", terralib.includepath)

truss.os = ffi.os

local library_extensions = {Windows = ".dll", Linux = ".so", OSX = ".dylib", 
                            BSD = ".so", POSIX = ".so", Other = ""}
local libary_prefixes = {Windows = "", Linux = "lib", OSX = "lib",
                         BSD = "lib", POSIX = "lib", Other = ""}
truss.library_extension = library_extensions[truss.os] or ""
truss.library_prefix = libary_prefixes[truss.os] or ""

function truss.link_library(basedir, libname)
  if not libname then
    libname, basedir = basedir, ""
  end
  if #basedir > 0 then basedir = basedir .. "/" end
  local fullpath = basedir .. truss.library_prefix .. 
                   libname .. truss.library_extension
  log.build("Linking " .. fullpath)
  terralib.linklibrary(fullpath)
end
