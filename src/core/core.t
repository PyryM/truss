-- core.t
-- defines truss library functions, sets up require system

truss = {}

-- from luajit
ffi = require("ffi")
bit = require("bit")

function TODO()
  error("TODO not implemented!")
end

local COREPATH = _COREPATH or "src/core/"
local function _docore(fn, optional)
  local func = (_load_internal and _load_internal(fn))
             or terralib.loadfile(COREPATH .. fn)
  assert(func, "core load failure: " .. fn)
  func()
end

_docore("_setup_path.t")
_docore("_setup_api.t")
_docore("_setup_log.t")
_docore("_setup_fs.t")
_docore("_setup_utils.t")
_docore("_setup_require.t")
_docore("_entry.t")
