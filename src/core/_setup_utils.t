local ffi = require("ffi")
core.os = ffi.os

function core.nanoclass(t)
  t = t or {}
  t.__index = t
  function t:new(...)
    ret = setmetatable({}, t)
    ret:init(...)
    return ret
  end
  return t
end

local library_extensions = {Windows = ".dll", Linux = ".so", OSX = ".dylib", 
                            BSD = ".so", POSIX = ".so", Other = ""}
local libary_prefixes = {Windows = "", Linux = "lib", OSX = "lib",
                         BSD = "lib", POSIX = "lib", Other = ""}
core.library_extension = library_extensions[core.os] or ""
core.library_prefix = libary_prefixes[core.os] or ""

function core.dostring(source, name, env)
  local func, err = core.loadstring(source, name)
  if not func then error(err) end
  if env then setfenv(func, env) end
  return func()
end

function core.link_library(basedir, libname)
  if not libname then
    libname, basedir = basedir, ""
  end
  if #basedir > 0 then basedir = basedir .. "/" end
  local fullpath = basedir .. core.library_prefix .. 
                   libname .. core.library_extension
  log.build("Linking " .. fullpath)
  terralib.linklibrary(fullpath)
end

function core.parse_version_int(v, base)
  base = base or 100
  local patch = v % base
  local minor = math.floor(v / base) % base
  local major = math.floor(v / (base*base))
  return {maj=major, min=minor, pat=patch}
end

function core.format_version(v)
  return ("%d.%d.%d"):format(v.maj or 0, v.min or 0, v.pat or 0)
end

function core.assert_compatible_version(libname, actual, target)
  local incompatible = false
  if actual.maj ~= target.maj or actual.min ~= target.min then
    incompatible = true
  elseif actual.pat < target.pat then
    incompatible = true
  end
  if incompatible then
    error(("Version mismatch for %s: wanted %s, got %s"):format(
      libname, core.format_version(target), core.format_version(actual)
    )
  end
end

function core.extend_table(dest, ...)
  for idx = 1, select("#", ...) do
    local addition = select(idx, ...)
    for k,v in pairs(addition) do dest[k] = v end
  end
  return dest
end
core.copy_table = function(t) return core.extend_table({}, t) end

function core.extend_list(dest, addition)
  for _, v in ipairs(addition) do
    dest[#dest+1] = v
  end
  return dest
end

function core.slice_list(src, start_idx, stop_idx)
  local dest = {}
  if stop_idx < 0 then
    stop_idx = #src + 1 + stop_idx
  end
  for i = start_idx, stop_idx do
    dest[i - start_idx + 1] = src[i]
  end
  return dest
end
