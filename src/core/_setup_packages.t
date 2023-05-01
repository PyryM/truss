

function core.canonize_package_path(path)
  return path
end

function core.create_root(core, options)
  local fs = assert(core.fs, "fs is not optional!")

  local root = {
    core = core,
    loaded = options.loaded or {}, 
    packages = options.packages or {},
    preload = options.preload or {},
  }
  loaded['core'] = core

  local CYCLICAL_SENTRY = {} -- just needs to be a unique table

  function root.require(path)
    path = core.canonize_package_path(path)
    local loaded = root.loaded[path]
    if loaded == CYCLICAL_SENTRY then 
      error("Cyclical require for [" .. path .. "]")
    elseif loaded then 
      return loaded 
    end
    root.loaded[path] = CYCLICAL_SENTRY
    local pkg, subpath = root.resolve_package(path)
    if pkg then loaded = pkg.internal_require(subpath) end
    root.loaded[path] = loaded
    return loaded
  end

  function root.readfile(path)
  end

  function root.listdir(path)
  end

  function root.fork(options)
  end

  function root.get_package(name)
    local package = root.packages[name]
    if package then return package end
    local loader = root.preload[name]
    if not loader then return nil end
    log.pkg('Loading [' .. name .. ']')
    package = loader()
    root.packages[name] = package
    return package
  end

  function root.add_package(source, name)
    if type(source) == 'string' then
      name = name or infer_name(source)
      root.preload[name] = function()
        local fs = core.fs.mount(source)
        return core.create_package(root, fs, name)
      end
    elseif type(source) == 'function' then
      assert(name, "A package defined as a function must be given an explicit name")
      root.preload[name] = source
    elseif type(source) == 'table' then
      name = name or source.name
      assert(name, "A package defined by a table must either have a .name or be given one")
      root.packages[name] = source
    else
      error("Can't add a package of type " .. type(package))
    end
  end

  function root.add_packages_dir(path)
    -- could path be a zip?
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