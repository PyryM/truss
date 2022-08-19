truss._module_env = truss.extend_table({}, _G)
local disallow_globals_mt = {
  __newindex = function (t,k,v)
    error("Module " .. t._module_name .. " tried to create global '" .. k .. "'")
  end,
  __index = function (t,k)
    error("Module " .. t._module_name .. " tried to access nil global '" .. k .. "'")
  end
}

local function find_path(file_name)
  local spos = 0
  for i = #file_name, 1, -1 do
    if file_name:sub(i, i) == "/" then
      spos = i - 1
      break
    end
  end
  return file_name:sub(1, spos)
end

local function expand_name(name, path)
  if name:sub(1,2) == "./" then
    return path .. "/" .. name:sub(3)
  elseif name:sub(1,1) == "/" then
    return name:sub(2)
  else
    return name
  end
end

local function create_module_require(path)
  return function(_modname, options)
    local expanded_name = expand_name(_modname, path)
    return truss.require(expanded_name, options)
  end
end

local function create_module_env(module_name, file_name, options)
  local modenv = truss.extend_table({}, truss._module_env)
  modenv._module_name = module_name
  local path = find_path(file_name)
  modenv._path = path
  modenv._modroot = false
  modenv.require = create_module_require(path)
  modenv._env = modenv
  if not options.allow_globals then
    setmetatable(modenv, disallow_globals_mt)
  end
  return modenv
end

truss.loaders = {
  [".t"] = terralib.load,
  [".lua"] = load,
  [".moon"] = function(...) 
    return truss.require("moonscript").load(...)
  end
}

function truss.select_loader(fn)
  for extension, loader in pairs(truss.loaders) do
    if fn:sub(-(#extension)) == extension then 
      return loader 
    end
  end
  return truss.loaders.default
end

truss.tic = truss.tic or function() return 0 end
truss.toc = truss.toc or function() return 0 end

local loaded_libs = {}
truss._loaded_libs = loaded_libs
truss.script_path = _SCRIPT_PATH or "src/"

function truss.require(modname, options)
  options = options or {}
  if loaded_libs[modname] == false then
    error("require [" .. modname .. "] : cyclical require")
    return nil
  end
  if loaded_libs[modname] == nil or options.force then
    local oldmodule = loaded_libs[modname] -- only relevant if force==true
    loaded_libs[modname] = false -- prevent possible infinite recursion

    -- if the filename is actually a directory, try to load init.t
    local filename = modname
    local fullpath = truss.script_path .. filename
    if truss.is_dir(fullpath) then
      fullpath = truss.joinpath(fullpath, "init.t")
      filename = truss.joinpath(filename, "init.t")
      log.info("Required directory; trying to load [" .. fullpath .. "]")
    end

    local t0 = truss.tic()
    local funcsource = truss.read_script(fullpath)
    if not funcsource then
      error("require('" .. filename .. "'): file does not exist.")
      return nil
    end
    local loader = truss.select_loader(fullpath)
    if not loader then
      error("No loader for " .. fullpath)
    end
    local module_def, loaderror = truss.loadstring(funcsource, filename, loader)
    if not module_def then
      error("require('" .. modname .. "'): syntax error: " .. loaderror)
      return nil
    end
    local modenv = options.env or create_module_env(modname, filename, options)
    rawset(modenv, "_preregister", function(v)
      if loaded_libs[modname] then
        error("Multiple preregs for [" .. modname .. "]")
      end
      loaded_libs[modname] = v
      return v
    end)
    setfenv(module_def, modenv)
    local evaluated_module = module_def()
    rawset(modenv, "_preregister", nil)
    if not (evaluated_module or options.allow_globals) then 
      error("Module [" .. modname .. "] did not return a table!")
    end
    local modtab = evaluated_module or modenv
    if loaded_libs[modname] and (loaded_libs[modname] ~= modtab) then
      error("Module [" .. modname .. "] did not return preregistered table!")
    end
    loaded_libs[modname] = modtab
    log.info(("Loaded [%s] in %.2f ms"):format(modname, truss.toc(t0) * 1000))
  end
  return loaded_libs[modname]
end
truss._module_env.require = truss.require

function truss.check_module_exists(filename)
  if loaded_libs[filename] then return true end
  local fullpath = truss.joinpath(truss._script_path, filename)
  return truss.check_file(fullpath) ~= 0
end

function truss.require_as(filename, libname, options)
  log.info("Loading [" .. filename .. "] as [" .. libname .. "]")
  local temp = truss.require(filename, options)
  loaded_libs[libname] = temp
  return temp
end

-- just directly inserts a module
function truss.insert_module(libname, libtable)
  loaded_libs[libname] = assert(libtable, "Missing library " .. libname)
end

-- alias standard lua/luajit libraries so they can be 'required'
truss.insert_module("ffi", require("ffi"))
truss.insert_module("bit", require("bit"))
truss.insert_module("jit", jit)
truss.insert_module("string", string)
truss.insert_module("io", io)
truss.insert_module("os", os)
truss.insert_module("table", table)
-- hmmm: should 3rd party libraries requiring math get truss math?
truss.insert_module("luamath", math)
truss.insert_module("package", package)
truss.insert_module("debug", debug)
truss.insert_module("coroutine", coroutine)

-- alias core/30log.lua to class so we can just require("class")
truss.require_as("core/30log.lua", "class")

local modutils = truss.require("core/module.t")
modutils.reexport(truss.require("core/memory.t"), truss)

-- replace lua require with truss require
lua_require = require
require = truss.require
