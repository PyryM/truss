-- core/loader.t
--
-- create proxy/mock require/env

local sutil = require("utils/stringutils.t")
local m = {}

function m.create_prefix_resolver(prefix, suffix)
  return function(modname)
    local parts = sutil.split("%.", modname) -- need to escape .
    return "scripts/" .. prefix .. table.concat(parts, "/") .. (suffix or ".lua")
  end
end

function m.create_env_gen(base_environment, clone)
  base_environment = base_environment or truss.extend_table({}, truss.clean_subenv)
  return function(modname, fn)
    if clone then
      return truss.extend_table({}, base_environment)
    else
      return base_environment
    end
  end
end

function m.create_lua_require(resolver, loader, envgen, preload)
  local _loaded = preload or {}
  local function _require(modname)
    if _loaded[modname] then return _loaded[modname] end
    local fn = resolver(modname)
    local funcsource = truss.load_script_from_file(fn)
    if not funcsource then
      truss.error("require('" .. fn .. "'): file does not exist.")
    end
    local module_def, loaderror = truss.load_named_string(funcsource, fn, loader)
    if not module_def then
      truss.error("require('" .. modname .. "'): syntax error: " .. loaderror)
    end
    local _env = envgen(modname, fn)
    _env.require = _require
    setfenv(module_def, _env)
    local evaluated_module = module_def()
    if not evaluated_module then 
      truss.error("Module [" .. modname .. "] did not return a table!")
    end
    _loaded[modname] = evaluated_module
    return evaluated_module
  end
  return _require, _loaded
end

return m