-- build/binexport.t
--
-- utilities for exporting binaries

local m = {}

local function unique_merge(dest, addition)
  local seen = {}
  for _, v in ipairs(dest) do
    seen[v] = true
  end
  for i, v in ipairs(addition) do
    if not seen[v] then
      table.insert(dest, v)
      seen[v] = true
    end
  end
end

function m.merge_sets(dest, addition)
  if not addition then return dest end
  for k, v in pairs(addition) do
    if dest[k] then
      unique_merge(dest[k], v)
    else
      dest[k] = v
    end
  end
  return dest
end

local EXE_SUFFIXES = {
  Windows = ".exe"
}

local function extend_libs(target, addition, prefix, suffix)
  for _, s in ipairs(addition) do
    table.insert(target, prefix .. s .. suffix)
  end
end

function m.linker_flags(target, libpath, platform_opts, libs, syslibs)
  local linker_opts = {}
  if target == "OSX" then
    local minver = platform_opts.min_osx_version or "12.0"
    table.insert(linker_opts, "-mmacosx-version-min=" .. minver)
    if platform_opts.rpath then
      local rpath = "@executable_path/" .. (platform_opts.rpath or "")
      log.debug("rpath:", rpath)
      table.insert(linker_opts, "-Wl,-rpath,"..rpath)
    end
    truss.extend_list(linker_opts, {"-L", libpath})
  elseif target == "Linux" then
    if platform_opts.rpath then
      local rpath = "$ORIGIN/" .. (platform_opts.rpath or "")
      log.debug("rpath:", rpath)
      table.insert(linker_opts, "-Wl,-rpath,"..rpath)
    end
    -- TODO: worry about -Wl,-E export symbols flag?
    truss.extend_list(linker_opts, {"-L", libpath})
  end

  local libprefix, syslibprefix, libsuffix = "", "", ""
  if target == "Windows" then
    libprefix = truss.normpath(libpath .. "\\", true)
    libsuffix = ".lib"
  else
    libprefix = "-l"
    syslibprefix = "-l"
  end

  extend_libs(linker_opts, libs, libprefix, libsuffix)
  extend_libs(linker_opts, syslibs, syslibprefix, libsuffix)

  if target == "Windows" then
    if not platform_opts.no_legacy then
      table.insert(linker_opts, "\\legacy_stdio_definitions.lib")
    end
    if platform_opts.no_terminal then
      truss.extend_list(linker_opts, {"/SUBSYSTEM:windows", "/ENTRY:mainCRTStartup"})
    end
  end

  return linker_opts
end

local function gather_libs(target, libs_opts)
  libs_opts = libs_opts or {}
  local libs = truss.extend_list({}, libs_opts.all or {})
  return truss.extend_list(libs, libs_opts[target] or {})
end

function m.export_binary(options)
  local target = options.target or jit.os
  local binname = assert(options.name, ".name must be provided!")
  local symbols = assert(options.symbols, ".symbols must be provided!")
  local libpath = options.libpath or "lib"
  binname = binname .. (EXE_SUFFIXES[jit.os] or "")


  local _plat = options.platform or {}
  local platform_opts = truss.extend_table({}, _plat.all or {}, _plat[jit.os] or {})
  local libs = gather_libs(target, options.libs)
  local syslibs = gather_libs(target, options.syslibs)

  local linker_opts = m.linker_flags(target, libpath, platform_opts, libs, syslibs)

  log.debug("Linker options:", table.concat(linker_opts, " "))
  log.crit("Exporting binary:", binname)
  terralib.saveobj(binname, "executable", symbols, linker_opts)
  log.crit("Success.")
end

return m