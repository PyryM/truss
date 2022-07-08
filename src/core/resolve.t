-- creates a require system
-- TODO: have main require use this
local m = {}

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

local disallow_globals_mt = {
  __newindex = function (t,k,v)
    error("Module " .. t._module_name .. " tried to create global '" .. k .. "'")
  end,
  __index = function (t,k)
    error("Module " .. t._module_name .. " tried to access nil global '" .. k .. "'")
  end
}

function m.create_root(options)
  options = options or {}
  local root = options.root or {}
  root._module_env = options.module_env or truss.extend_table({}, _G)
  root._loaders = options.loaders or {
    [".t"] = terralib.load,
    [".lua"] = load,
  }
  local loaded_libs = {}
  root._loaded_libs = loaded_libs
  root._script_path = options.script_path or "scripts/"
  local error = options.error or truss.error

  local function create_module_require(path)
    return function(_modname, options)
      local expanded_name = expand_name(_modname, path)
      return root.require(expanded_name, options)
    end
  end

  local function create_module_env(module_name, file_name, options)
    local modenv = truss.extend_table({}, root._module_env)
    modenv._module_name = module_name
    local path = find_path(file_name)
    modenv._path = path
    modenv.require = create_module_require(path)
    modenv._env = modenv
    modenv._modroot = root
    if not options.allow_globals then
      setmetatable(modenv, disallow_globals_mt)
    end
    return modenv
  end

  local function select_loader(fn)
    for extension, loader in pairs(root._loaders) do
      if fn:sub(-(#extension)) == extension then 
        return loader 
      end
    end
    return root._loaders.default
  end

  function root.require(modname, options)
    options = options or {}
    if type(options) == 'boolean' then
      error("Require now takes options table: require(fn, {force=true})")
    end
    if loaded_libs[modname] == false then
      error("require [" .. modname .. "] : cyclical require")
      return nil
    end
    if loaded_libs[modname] == nil or options.force then
      local oldmodule = loaded_libs[modname] -- only relevant if force==true
      loaded_libs[modname] = false -- prevent possible infinite recursion

      -- if the filename is actually a directory, try to load init.t
      local filename = modname
      local fullpath = root._script_path .. filename
      if truss.C.check_file(fullpath) == 2 then
        fullpath = fullpath .. "/init.t"
        filename = filename .. "/init.t"
        log.info("Required directory; trying to load [" .. fullpath .. "]")
      end

      local t0 = truss.tic()
      local funcsource = truss.load_script_from_file(fullpath)
      if not funcsource then
        error("require('" .. filename .. "'): file does not exist.")
        return nil
      end
      local loader = select_loader(fullpath)
      if not loader then
        error("No loader for " .. fullpath)
      end
      local module_def, loaderror = truss.load_named_string(funcsource, filename, loader)
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
      log.info(string.format("Loaded [%s] in %.2f ms",
                            modname, truss.toc(t0) * 1000.0))
    end
    return loaded_libs[modname]
  end
  root._module_env.require = root.require

  function root.check_module_exists(filename)
    if loaded_libs[filename] then return true end
    local fullpath = root._script_path .. filename
    return truss.C.check_file(fullpath) ~= 0
  end

  function root.require_as(filename, libname, options)
    log.info("Loading [" .. filename .. "] as [" .. libname .. "]")
    local temp = root.require(filename, options)
    loaded_libs[libname] = temp
    return temp
  end

  -- just directly inserts a module
  function root.insert_module(libname, libtable)
    loaded_libs[libname] = libtable
  end

  if not options.no_default_libs then
    -- alias standard lua/luajit libraries so they can be 'required'
    root.insert_module("ffi", ffi)
    root.insert_module("bit", bit)
    root.insert_module("string", string)
    root.insert_module("io", io)
    root.insert_module("os", os)
    root.insert_module("table", table)
    -- hmmm: should 3rd party libraries requiring math get truss math?
    root.insert_module("luamath", math)
    root.insert_module("package", package)
    root.insert_module("debug", debug)
    root.insert_module("coroutine", coroutine)
    root.insert_module("jit", jit)

    -- alias core/30log.lua to class so we can just require("class")
    root.require_as("core/30log.lua", "class")
  end

  return root
end

return m
