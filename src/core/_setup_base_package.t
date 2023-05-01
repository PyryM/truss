core.disallow_globals_mt = {
  __newindex = function (t,k,v)
    error("Module " .. t._module_name .. " tried to create global '" .. k .. "'")
  end,
  __index = function (t,k)
    error("Module " .. t._module_name .. " tried to access nil global '" .. k .. "'")
  end
}

function core.fixscript(script)
  if not str then return nil end
  return str:gsub("\r", "")
end

local function pkg_init()
  function pkg.create_module_require(subpath)
    return function(path)
      local realpath = root.resolve_path(pkg.name, subpath, path)
      return root.require(realpath)
    end
  end

  function pkg.create_module_env(subpath)
    local modenv = root.core.extend_table({}, root.module_env)
    modenv._module_name = module_name
    modenv._path = pkg.name .. "/" .. subpath
    modenv.require = pkg.create_module_require(subpath)
    modenv._G = modenv
    modenv._root = root
    setmetatable(modenv, core.disallow_globals_mt)
    return modenv
  end

  function pkg.internal_require(subpath)
    -- if the filename is actually a directory, try to load init.t
    if pkg.fs:isdir(subpath) then
      subpath = subpath .. "/init.t"
    end
    local modname = pkg.name .. "/" .. subpath
    
    local funcsource = root.core.fixscript(pkg.fs:read(subpath))
    if not funcsource then
      error(("Module [%s] does not exist."):format(modname))
    end
    local loader = root.select_lang_loader(subpath)
    if not loader then 
      error(("No loader for [%s]"):format(modname))
    end
    local module_def, loaderror = core.loadstring(funcsource, subpath, loader)
    if not module_def then
      error(("Module [%s]: syntax error: %s"):format(modname, loaderror))
    end
    local modenv = pkg.create_module_env(subpath)
    setfenv(module_def, modenv)
    local happy, evaluated_module = core.logged_pcall(module_def)
    if not happy then
      error(("Module [%s] error:\n%s"):format(modname, tostring(evaluated_module)))
    end
    if not evaluated_module then
      error(("Module [%s] did not return a table!"):format(modname))
    end
    return evaluated_module
  end
end

function core.create_package(root, fs, name)
  local pkg = {
    fs = fs,
    name = name,
    root = root
  }
  setmetatable(pkg, {__index = assert(root.package_env)}) --?
  pkg.pkg = pkg
  setfenv(pkg_init, pkg)
  pkg_init()
  local package_dot_t = fs:readfile("package.t")
  if package_dot_t then
    core.dostring(core.fixscript(package_dot_t), name .. "/package.t", pkg)
  end
  return pkg
end