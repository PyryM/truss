local ffi = require("ffi")
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

function truss.extend_table(dest, ...)
  for idx = 1, select("#", ...) do
    local addition = select(idx, ...)
    for k,v in pairs(addition) do dest[k] = v end
  end
  return dest
end
truss.copy_table = function(t) return truss.extend_table({}, t) end

function truss.extend_list(dest, addition)
  for _, v in ipairs(addition) do
    dest[#dest+1] = v
  end
  return dest
end

function truss.slice_list(src, start_idx, stop_idx)
  local dest = {}
  if stop_idx < 0 then
    stop_idx = #src + 1 + stop_idx
  end
  for i = start_idx, stop_idx do
    dest[i - start_idx + 1] = src[i]
  end
  return dest
end
