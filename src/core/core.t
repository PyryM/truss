-- core.t
-- defines truss library functions, sets up require system

-- remove strict mode if running in terra
setmetatable(_G, nil)

local bare_env = {}
for k, v in pairs(_G) do bare_env[k] = v end

truss = {}
truss.bare_env = bare_env
truss.version = _TRUSS_VERSION or "0.3.0"
truss.version_emoji = _TRUSS_VERSION_EMOJI or "🦴"
truss._builtins = {}

function truss._declare_builtin(name, libtable)
  libtable = libtable or {}
  truss._builtins[name] = libtable
  truss[name] = libtable
  return libtable
end

function TODO()
  error("TODO not implemented!")
end

function truss.loadstring(str, strname, loader)
  local s = str
  local generator_func = function()
    local s2 = s
    s = nil
    return s2
  end
  return (loader or terralib.load)(generator_func, '@' .. strname)
end

truss._COREPATH = _COREPATH or "src/core/"
truss._COREFILES = {}
local function _docore(fn, optional)
  local interned = _TRUSS_EMBEDDED and _TRUSS_EMBEDDED[fn]
  local func, err
  if interned then
    func, err = truss.loadstring(interned, fn)
  else
    func, err = terralib.loadfile(truss._COREPATH .. fn)
  end
  table.insert(truss._COREFILES, fn)
  assert(func, "Core load failure: " .. fn .. " -> " .. (err or ""))
  func()
end

_docore("_setup_utils.t")
_docore("_setup_log.t")
_docore("_setup_path.t")
--_docore("_setup_api.t")
_docore("_setup_fs.t")
_docore("_setup_user_config.t")
_docore("_setup_require.t")
if not truss.config.no_auto_libraries then
  require("native/timing.t").install(truss)
end
_docore("_entry.t")
