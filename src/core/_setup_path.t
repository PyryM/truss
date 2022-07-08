terralib.includepath = "include;include/compat"

local use_ryzen_hack = false
if use_ryzen_hack then
  print("Using Ryzen hack. Unclear on performance implications.")
  -- AMD Ryzen incorrectly reports its CPU as "generic" somehow, so manually set
  -- the default compile target
  local triple = "x86_64-pc-win32"
  terralib.nativetarget = terralib.newtarget{Triple = triple}

  -- this is completely undocumented, but needs to be derived from the newly made
  -- native target or else linking structures will break things for some reason
  terralib.jitcompilationunit = terralib.newcompilationunit(terralib.nativetarget, true)
end

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
  log.info("Linking " .. fullpath)
  terralib.linklibrary(fullpath)
end
