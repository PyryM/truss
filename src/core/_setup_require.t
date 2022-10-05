-- TODO: move path manipulation stuff into fs?
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

if not truss.tic then
  function truss.tic() return 0 end
  function truss.toc(_t0) return 0 end
end

local function logged_pcall(f, ...)
  local args = {...}
  local _err = nil
  local _res = {xpcall(
    function()
      return f(unpack(args))
    end,
    function(err)
      _err = err
      log.fatal(err)
      log.fatal(debug.traceback())
    end
  )}
  if not _res[1] then
    _res[2] = _err
  end
  return unpack(_res)
end

function truss.create_require_root(options)
  options = options or {}
  local root = options.root or {}
  root._module_env = options.module_env or truss.extend_table({}, _G)
  root._loaders = options.loaders or {
    [".t"] = terralib.load,
    [".lua"] = load,
  }
  local loaded_libs, load_stack, load_tree = {}, {}, {}
  root._loaded_libs = loaded_libs
  root._load_tree = load_tree
  root._script_path = options.script_path or "src/"
  local error = options.error or error

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

  -- sentinel value to detect cyclical requires
  local CYCLICAL = {} 

  function root.require(modname, options)
    options = options or {}
    modname = truss.normpath(modname, false)
    if loaded_libs[modname] == CYCLICAL then
      error("require [" .. modname .. "] : cyclical require")
      return nil
    elseif loaded_libs[modname] == false then
      error("require [" .. modname .. "] : module previously had errors")
    end
    if loaded_libs[modname] == nil or options.force then
      local oldmodule = loaded_libs[modname] -- only relevant if force==true
      loaded_libs[modname] = CYCLICAL -- prevent possible infinite recursion

      -- if the filename is actually a directory, try to load init.t
      local filename = modname
      local fullpath = truss.joinvpath(root._script_path, filename)
      if truss.is_dir(fullpath) then
        fullpath = truss.joinvpath(fullpath, "init.t")
        filename = truss.joinvpath(filename, "init.t")
      end

      local loadmeta = {name = modname, t0 = truss.tic(), children = {}}
      load_tree[modname] = loadmeta
      if #load_stack > 0 then
        table.insert(load_stack[#load_stack].children, loadmeta)
      end
      
      local funcsource = truss.read_script(fullpath)
      if not funcsource then
        loadmeta.error = "missing"
        loaded_libs[modname] = false
        error("require('" .. filename .. "'): file does not exist.")
      end
      local loader = select_loader(fullpath)
      if not loader then
        loadmeta.error = "no_loader"
        loaded_libs[modname] = false
        error("No loader for " .. fullpath)
      end
      local module_def, loaderror = truss.loadstring(funcsource, filename, loader)
      if not module_def then
        loadmeta.error = "syntax"
        loaded_libs[modname] = false
        error("require('" .. modname .. "'): syntax error: " .. loaderror)
      end
      local modenv = options.env or create_module_env(modname, filename, options)
      rawset(modenv, "_preregister", function(v)
        if loaded_libs[modname] and loaded_libs[modname] ~= CYCLICAL then
          error("Multiple preregs for [" .. modname .. "]")
        end
        loaded_libs[modname] = v
        return v
      end)
      setfenv(module_def, modenv)
      load_stack[#load_stack + 1] = loadmeta
      local happy, evaluated_module = logged_pcall(module_def)
      load_stack[#load_stack] = nil
      loadmeta.dt = truss.toc(loadmeta.t0)
      if not happy then
        loaded_libs[modname] = false
        error("Module [" .. modname .. "] error:\n" .. tostring(evaluated_module))
      end
      rawset(modenv, "_preregister", nil)
      if not (evaluated_module or options.allow_globals) then 
        loaded_libs[modname] = false
        error("Module [" .. modname .. "] did not return a table!")
      end
      local modtab = evaluated_module or modenv
      local _loaded = loaded_libs[modname]
      if _loaded and (_loaded ~= CYCLICAL) and (_loaded ~= modtab) then
        loaded_libs[modname] = false
        error("Module [" .. modname .. "] did not return preregistered table!")
      end
      loaded_libs[modname] = modtab
      if #load_stack == 0 then
        root.dump_load_perf(modname)
      end
    end
    return loaded_libs[modname]
  end
  root._module_env.require = root.require

  function root.dump_load_perf(modname, indent)
    indent = indent or 0
    local indentstr = ("  "):rep(indent)
    local meta = load_tree[modname]
    if not meta then
      log.warn("no load metadata for", modname)
      return
    end
    local timestr = ("%0.1fms"):format(meta.dt*1000.0)
    if #timestr < 6 then 
      timestr = (" "):rep(6 - #timestr) .. timestr
    end
    log.perf(indentstr, timestr, meta.name)
    for _, child in ipairs(meta.children) do
      root.dump_load_perf(child.name, indent+1)
    end
  end

  function root.require_as(filename, libname, options)
    log.path("Loading [" .. filename .. "] as [" .. libname .. "]")
    local temp = root.require(filename, options)
    loaded_libs[libname] = temp
    return temp
  end

  -- call a function within this root
  function root.pcall(f, ...)
    if type(f) == 'string' then
      local loaded, err = truss.loadstring(f, "[string]")
      if not loaded then return false, err end
      f = loaded
    end
    setfenv(f, create_module_env("[anonymous_module]", "[anon]", {}))
    return logged_pcall(f, ...)
  end

  -- directly inserts a module
  function root.insert_module(libname, libtable)
    loaded_libs[libname] = assert(libtable, "Missing module: " .. libname)
  end

  if not options.no_default_libs then
    -- alias standard lua/luajit libraries so they can be 'required'
    root.insert_module("ffi", require("ffi"))
    root.insert_module("bit", require("bit"))
    root.insert_module("jit", jit)
    root.insert_module("string", string)
    root.insert_module("io", io)
    root.insert_module("os", os)
    root.insert_module("table", table)
    -- hmmm: should 3rd party libraries requiring math get truss math?
    root.insert_module("luamath", math)
    root.insert_module("package", package)
    root.insert_module("debug", debug)
    root.insert_module("coroutine", coroutine)

    -- make 'builtins' requireable
    for name, builtin in pairs(truss._builtins) do
      root.insert_module(name, builtin)
    end

    -- alias core/30log.lua to class so we can just require("class")
    root.require_as("core/30log.lua", "class")
  end

  return root
end

truss.root = truss.create_require_root()
truss.require = truss.root.require

local modutils = truss.require("core/module.t")
modutils.reexport(truss.require("core/memory.t"), truss)

-- replace lua require with truss require
lua_require = require
require = truss.require
