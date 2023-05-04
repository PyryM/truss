local function install(core)
  local log = core.log

  core.disallow_globals_mt = {
    __newindex = function (t,k,v)
      local mname = rawget(t, "_path") or "???"
      error("Module " .. mname .. " tried to create global '" .. k .. "'")
    end,
    __index = function (t,k)
      local mname = rawget(t, "_path") or "???"
      error("Module " .. mname .. " tried to access nil global '" .. k .. "'")
    end
  }

  function core.fixscript(str)
    if not str then return nil end
    return str:gsub("\r", "")
  end

  local function pkg_init()
    pkg.script_loaders = assert(truss.script_loaders)

    function pkg.create_module_require(package_filepath)
      return function(path)
        return truss.relative_require(pkg.name, package_filepath, path)
      end
    end

    function pkg.create_module_env(package_filepath)
      local modenv = truss.extend_table({}, assert(truss.module_env))
      modenv._module_name = package_filepath
      modenv._path = pkg.name .. "/" .. package_filepath
      modenv.require = pkg.create_module_require(package_filepath)
      modenv._G = modenv
      modenv.truss = truss
      modenv.log = truss.log
      setmetatable(modenv, truss.disallow_globals_mt)
      return modenv
    end

    function pkg.resolve_path(subpath)
      -- if the filename is actually a directory, try to load init.t
      if subpath == "" then return "init.t" end
      if pkg.fs:isdir(subpath) then return subpath .. "/init.t" end
      return subpath
    end

    function pkg.select_loader(subpath)
      local ext = truss.fs.file_extension(subpath)
      return pkg.assert(pkg.script_loaders[ext], subpath, "No loader for " .. ext)
    end

    function pkg.error(path, msg)
      error(table.concat{"[", pkg.name, "/", path, "]: ", msg})
    end

    function pkg.assert(val, path, msg)
      if val == nil then
        pkg.error(path, msg)
      end
      return val
    end

    function pkg.internal_require(canonical_subpath)
      local modname = pkg.name .. "/" .. canonical_subpath
      local source = pkg.fs:read(canonical_subpath)
      if not source then 
        return nil 
      end
      source = truss.fixscript(source)
      local loader = pkg.select_loader(canonical_subpath)
      local module_def, loaderror = truss.loadstring(source, canonical_subpath, loader)
      if not module_def then 
        pkg.error(canonical_subpath, loaderror) 
      end
      local modenv = pkg.create_module_env(canonical_subpath)
      setfenv(module_def, modenv)
      local happy, evaluated_module = log.pcall(module_def)
      if not happy then 
        pkg.error(canonical_subpath, evaluated_module) 
      end
      if not evaluated_module then 
        pkg.error(canonical_subpath, "did not return a table!") 
      end
      return evaluated_module
    end
  end

  function core.singleton_package(name, t)
    local pkg = {name = name, t = t}
    function pkg.resolve_path(path) 
      return path 
    end
    function pkg.internal_require(path)
      if path == "" or path == "init.t" then return pkg.t end
      return nil
    end
    return pkg
  end

  function core.create_package(root, fs, name)
    local pkg = {
      fs = fs,
      name = name,
    }
    local pkg_env = {
      truss = root,
      pkg = pkg,
    }
    setmetatable(pkg_env, {
      __index = assert(root.package_env),
    }) --?
    setfenv(pkg_init, pkg_env)
    pkg_init()
    local package_dot_t = fs:read("package.t")
    if package_dot_t then
      log.debug("Found package.t")
      core.dostring(core.fixscript(package_dot_t), name .. "/package.t", pkg_env)
    else
      log.debug("Did not find a package.t")
    end
    return pkg
  end
end

return {install = install}