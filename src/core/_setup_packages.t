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

  function core.create_root(options)
    local fs = assert(core.fs, "fs is not optional!")

    local root = core.extend_table({}, core)
    root = core.extend_table(root, {
      core = core,
      config = options.config,
      loaded = options.loaded or {}, 
      packages = options.packages or {},
      package_env = core.core_env,
      module_env = core.bare_env,
      script_loaders = options.script_loaders or {
        t = terralib.load,
        lua = load
      }
    })

    function root.fork_root()
      local newroot = core.create_root({
        config = root.config,
        config_native = false,
        config_packages = true,
      })
      return newroot
    end

    function root.add_raw_package(name, info)
      assert(not root.packages[name], "package name collision on " .. name)
      root.packages[name] = info
    end

    function root.add_singleton_package(name, t, source_desc)
      local pkg = {
        name = name,
        body = core.singleton_package(name, t),
        source_desc = source_desc or "manually added"
      }
      root.add_raw_package(name, pkg)
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

    function root.load_package(name)
      local pkg = root.packages[name]
      if not pkg then return nil end
      local body = pkg.body
      if not body then
        local loader = assert(pkg.loader, "Missing .loader for " .. name)
        log.pkg('Loading [' .. name .. ']')
        body = assert(loader(), name .. " load failure!")
        pkg.body = body
      end
      return body
    end

    function root.resolve_package(path, notfound)
      local pkg_name, subpath = core.split_package_path(path)
      log.debug(("pkg: %s, subpath: %s"):format(pkg_name, subpath))
      local pkg = root.load_package(pkg_name)
      if not pkg then return nil, pkg_name, subpath end
      subpath = pkg.resolve_path(subpath)
      return pkg, pkg_name, subpath
    end

    function root.get_source(path)
      local pkg, pkg_name, subpath = root.resolve_package(path)
      if not pkg then return nil end
      return pkg.get_source(subpath)
    end

    function root._require(path, notfound)
      -- local pkg_name, subpath = core.split_package_path(path)
      -- log.debug(("pkg: %s, subpath: %s"):format(pkg_name, subpath))
      -- local pkg = root.load_package(pkg_name)
      -- if not pkg then 
      --   return notfound("No package [" .. pkg_name .. "]")
      -- end
      -- subpath = pkg.resolve_path(subpath)
      local pkg, pkg_name, subpath = root.resolve_package(path)
      if not pkg then
        return notfound("No package [" .. pkg_name .. "]")
      end
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
      return nil, msg
    end

    function root.try_require(path)
      return root._require(path, log_not_found)
    end

    local function infer_name(source)
      if type(source) == 'string' then
        local parts = core.fs.splitpath(source)
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

    function root.add_package(info)
      if type(info) == 'string' then info = {source_path = info} end
      if not info.name then
        info.name = assert(
          (info.body and info.body.name) or infer_name(info.source_path), 
          "Couldn't infer package name!"
        )
        log.debug("Inferred name:", info.name)
      end
      if not (info.body or info.loader) then
        local source = info.source or info.source_path
        if source then
          info.loader = dir_preload(info.name, source)
        else
          error("package " .. info.name .. " has no body or loader or source path!")
        end
      end
      root.packages[info.name] = info
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
          root.add_package{
            name = name, 
            source = dir,
            source_path = dir:realpath("")
          }
        end
      end
    end

    if options.include_default_libs ~= false then
      root.add_singleton_package("ffi", require("ffi"), "builtin")
      root.add_singleton_package("bit", require("bit"), "builtin")
    end

    if options.include_class ~= false then
      root.add_singleton_package("class", core.class, "builtin")
    end

    if options.config_native then
      options.config:apply_native_config(root)
    end
    if options.config_packages then
      options.config:apply_packages(root)
    end

    return root
  end
end

return {install = install}