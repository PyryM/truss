local function install(core)
  local log = core.log

  function core.split_package_path(path)
    local pkg_name, subpath = path:match("^([^/]+)/(.*)$")
    if pkg_name then
      return pkg_name, subpath
    else
      return path, ""
    end
  end

  function core.create_root(core, options)
    local fs = assert(core.fs, "fs is not optional!")

    local root = {
      core = core,
      loaded = options.loaded or {}, 
      packages = options.packages or {},
      preload = options.preload or {},
      package_env = core.core_env,
      module_env = core.bare_env,
    }

    function root.add_raw_package(pkg, name)
      name = assert(name or pkg.name, "package requires name")
      assert(not root.packages[name], "package name collision on " .. name)
      root.packages[name] = pkg
    end

    function root.add_singleton_package(name, t)
      root.add_raw_package(core.singleton_package(name, t))
    end

    if options.include_core ~= false then
      root.add_singleton_package('truss', core)
    end

    if options.include_default_libs ~= false then
      -- hmmmmmmm
      root.add_singleton_package("ffi", require("ffi"))
      root.add_singleton_package("lua.bit", require("bit"))
      root.add_singleton_package("lua.jit", jit)
      root.add_singleton_package("lua.string", string)
      root.add_singleton_package("lua.io", io)
      root.add_singleton_package("lua.os", os)
      root.add_singleton_package("lua.table", table)
      root.add_singleton_package("lua.math", math)
      root.add_singleton_package("lua.package", package)
      root.add_singleton_package("lua.debug", debug)
      root.add_singleton_package("lua.coroutine", coroutine)
    end

    if options.include_builtins ~= false then
      -- make 'builtins' requireable
      for name, builtin in pairs(core._builtins) do
        root.add_singleton_package("truss." .. name, builtin)
      end
    end

    -- unique tables to indicate load conditions
    local CYCLICAL_SENTRY = {} 
    local ERROR_SENTRY = {}

    function root.relative_require(package_name, package_filepath, require_path)
      local reqstack = core.fs.splitpath(require_path)
      if (reqstack[1] ~= ".") and (reqstack[1] ~= "..") then
        -- assume regular absolute require path?
        return root.require(require_path)
      end
      local package_dir, _ = core.fs.splitbase(package_filepath)
      local basepath = package_name .. "/" .. package_dir
      local newpath = core.fs.resolve_relative_path(basepath, require_path)
      newpath = table.concat(newpath, "/")
      log.debug("resolved relative path ->", newpath)
      return root.require(newpath)
    end

    function root.resolve_package(name)
      local package = root.packages[name]
      if package then return package end
      local loader = root.preload[name]
      if not loader then return nil end
      log.pkg('Loading [' .. name .. ']')
      package = loader()
      root.packages[name] = package
      return package
    end

    function root._require(path, notfound)
      local pkg_name, subpath = core.split_package_path(path)
      log.debug(("pkg: %s, subpath: %s"):format(pkg_name, subpath))
      local pkg = root.resolve_package(pkg_name)
      if not pkg then 
        return notfound("No package [" .. pkg_name .. "]")
      end
      subpath = pkg.resolve_path(subpath)
      local canonical_path = pkg_name .. "/" .. subpath
      local loaded = root.loaded[canonical_path]
      if loaded == CYCLICAL_SENTRY then 
        error("Cyclical require for [" .. canonical_path .. "]")
      elseif loaded == ERROR_SENTRY then 
        error(("require('%s'): previous errors"):format(canonical_path))
      elseif loaded ~= nil then
        return loaded 
      end
      root.loaded[canonical_path] = CYCLICAL_SENTRY
      loaded = pkg.internal_require(subpath)
      root.loaded[canonical_path] = loaded or ERROR_SENTRY
      if loaded then
        log.debug("Successfully loaded:", canonical_path)
        return loaded
      else
        return notfound("No module [" .. canonical_path .. "]")
      end
    end

    function root.require(path)
      return root._require(path, error)
    end

    local function log_not_found(msg)
      log.warn(msg)
      return nil, msg
    end

    function root.try_require(path)
      return root._require(path, log_not_found)
    end

    function root.readfile(path)
    end

    function root.listdir(path)
    end

    function root.fork(options)
    end

    local function infer_name(source)
      if type(source) == 'string' then
        local parts = core.fs.splitpath(filename)
        return parts[#parts]
      elseif type(source) == 'table' then
        return assert(source.name, "package doesn't have a .name!")
      else
        error("cannot infer name for this kind of package!")
      end
    end

    local function dir_preload(name, dir)
      if type(dir) == 'string' then
        dir = core.fs.mount(dir)
      end
      return function()
        return core.create_package(root, dir, name)
      end
    end

    function root.add_package(name, source)
      if not source then
        source = name
        name = infer_name(source)
        log.debug("Inferred name:", source, "->", name)
      end

      if type(source) == 'string' then
        log.debug("Adding package from dir:", name, source)
        root.preload[name] = dir_preload(name, source)
      elseif type(source) == 'function' then
        log.debug("Adding package from function:", name)
        root.preload[name] = source
      elseif type(source) == 'table' then
        log.debug("Adding package directly:", name)
        root.packages[name] = source
      else
        error("Can't add a package of type " .. type(package))
      end
    end

    function root.add_packages_dir(path)
      log.debug("Adding packages path:", path)
      local base = core.fs.mount(path)
      local listing = base:listdir("", false)
      for _, item in ipairs(listing) do
        if not item.is_file then
          -- assume dir (symlinks??)
          local dir = base:mountdir(item.path)
          local name = item.file
          log.debug("Adding package:", name, item.path)
          root.add_package(name, dir_preload(name, dir))
        end
      end
    end

    -- root.file_loaders = {}
    -- root.file_loaders.file = function(_, path)
      
    -- end
    function root.parse_truss_path(path)
      local proto, proto_path = path:match("^([^:]+):(.*)$")
      if proto then
        local fchar = proto_path:sub(1,1)
        if jit.os == "Windows" and fchar == "\\" then
          -- a path like "C:\foo\bar.txt"
          return "file", path
        end
        return proto, proto_path
      else -- assume file
        return "file", path
      end
    end

    function root.resolve(path)
      local proto, subpath = root.parse_truss_path(fn)
      local loader = root.data_sources[proto]
      return loader, subpath
    end

    function root.readfile(fn)
      local loader, subpath = root.resolve(fn)
      if not loader then return nil end
      return loader:read(subpath)
    end

    function root.listdir(path, recursive)
      local loader, subpath = root.resolve(path)
      if not loader then return nil end
      return loader:listdir(subpath, recursive)
    end

    function root.string_as_buffer(str)
      if not str then return nil end
      return {data = terralib.cast(&uint8, str), str = str, size = #str}
    end

    function root.read_file_buffer(fn)
      return root.string_as_buffer(root.read_file(fn))
    end

    return root
  end

  core.root = core.create_root(core, {})
  core.require = core.root.require
  core.add_package = core.root.add_package
end

return {install = install}