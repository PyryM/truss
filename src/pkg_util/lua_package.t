-- pkg_util/lua_package.t
--
-- utilities for wrapping regular Lua packages
-- (including TSTL and LuaRocks [TODO])

local m = {}

function m.setup_lua_package(pkg, options)
  assert(pkg and pkg.name, "Didn't provide a package!")
  assert(pkg.fs, "pkg must have an fs!")
  options = options or {}

  pkg._builtin_modules = options.builtin_modules or {
    truss = truss,
    ffi = require("ffi"),
    bit = require("bit")
  }

  -- basically the only change is how requires are handled
  function pkg.create_module_require(_package_filepath)
    -- Regular Lua does not do relative requires
    -- so we ignore the base package path
    return function(path)
      -- path here is a Lua require path like "utils.functional"
      -- corresponding to "utils/functional.lua"
      if pkg._builtin_modules[path] then
        return pkg._builtin_modules[path]
      end
      local truss_path = pkg.name .. "/" .. path:gsub("%.", "/") .. ".lua"
      log.debug("MODIFIED PATH:", path, "->", truss_path)
      return truss.require(truss_path)
    end
  end

  local _super_create_env = pkg.create_module_env
  local function base_create_env(path)
    local env = _super_create_env(path)
    if options.globals then
      env = truss.extend_table(env, options.globals)
    end
    if options.allow_globals then
      setmetatable(env, nil)
    end
    return env
  end

  if options.unified_environment ~= false then
    log.debug("Creating Lua package", pkg.name, "with a unified environment")
    pkg._environment = base_create_env("")
    function pkg.create_module_env()
      return pkg._environment
    end
  else
    pkg.create_module_env = base_create_env
  end
end

return m