-- core.t
-- defines core library functions, sets up require system

local GLOBALS = setmetatable({}, {
  __index = function(t, k) return rawget(_G, k) end
})

local bare_env = {}
local core_env = {}
for k, v in pairs(_G) do 
  bare_env[k] = v 
  core_env[k] = v
end

local core = {}
core.ffi = require("ffi")
core.bare_env = bare_env
core.core_env = core_env
core.version = GLOBALS._TRUSS_VERSION
core.version_emoji = GLOBALS._TRUSS_VERSION_EMOJI
core.GLOBALS = GLOBALS
core._builtins = {}
core_env.core = core

function core._declare_builtin(name, libtable)
  libtable = libtable or {}
  core._builtins[name] = libtable
  core[name] = libtable
  return libtable
end

function core.TODO()
  error("TODO not implemented!")
end

-- core.retain_source = false
-- core.source_map = {}

function core.loadstring(str, strname, loader)
  local s = str
  local generator_func = function()
    local s2 = s
    s = nil
    return s2
  end
  local fname = '@' .. strname
  --if core.retain_source then core.source_map[fname] = str end
  return (loader or terralib.load)(generator_func, fname)
end

core._COREPATH = GLOBALS._COREPATH or "src/core/"
core._COREFILES = {}
local embeds = GLOBALS._TRUSS_EMBEDDED
local function _docore(fn)
  local interned = embeds and embeds[fn]
  local func, err
  if interned then
    func, err = core.loadstring(interned, "core/" .. fn)
  else
    func, err = terralib.loadfile(core._COREPATH .. fn)
  end
  table.insert(core._COREFILES, fn)
  assert(func, "Core load failure: " .. fn .. " -> " .. (err or ""))
  local res = func()
  if res.install then res.install(core) end
  return res
end

if not (core.version and core.version_emoji) then
  _docore("VERSION.lua")
end
_docore("_setup_utils.t")
core.class = _docore("30log.lua")
_docore("_setup_log.t")
_docore("_setup_fs.t")
_docore("_setup_base_package.t")
_docore("_setup_packages.t")
_docore("_setup_user_config.t")
local entry = _docore("_entry.t").entry

local truss = core.create_root{
  config = core.load_config(),
  config_native = true,
  config_packages = true,
}
if embeds then
  rawset(_G, "truss", core)
end

entry(truss)

return truss