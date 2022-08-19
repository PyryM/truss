-- core.t
-- defines truss library functions, sets up require system

-- remove strict mode if running in terra
setmetatable(_G, nil)

truss = {}
truss.version = _TRUSS_VERSION or "0.0.3"

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
  local interned = _INTERNAL and _INTERNAL[fn]
  local func
  if interned then
    func = truss.loadstring(interned, fn)
  else
    func = terralib.loadfile(truss._COREPATH .. fn)
  end
  table.insert(truss._COREFILES, fn)
  assert(func, "Core load failure: " .. fn)
  func()
end

_docore("_setup_log.t")
_docore("_setup_path.t")
--_docore("_setup_api.t")
_docore("_setup_fs.t")

for _, fn in ipairs(truss.fs:list_archive("test.zip")) do
  print(fn)
end

_docore("_setup_utils.t")
_docore("_setup_require.t")
_docore("_entry.t")
