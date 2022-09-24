local m = {}

local cfg = {}
local frozen = false

local function NOOP()
  return quote end
end

local function _make_assert()
  local clib = require("./clib.t")
  return function(condition, message)
    local fullmsg = "Assertion failure: " .. (message or "") .. "\n"
    return quote 
      if not condition then
        clib.io.printf(fullmsg)
        clib.std.quit(2)
      end
    end
  end
end

local function _fill_defaults(cfg)
  if not cfg.ASSERT then
    if cfg.no_asserts then
      cfg.ASSERT = NOOP
    else
      cfg.ASSERT = _make_assert()
    end
  end

  if not (cfg.ALLOCATE and cfg.FREE) then
    local alloc = require("./alloc.t").default_allocators(cfg)
    cfg.ALLOCATE, cfg.FREE = alloc.ALLOCATE, alloc.FREE
  end

  if not cfg.LOG then
    cfg.LOG = require("./log.t").default_log(cfg)
  end
end

function m.freeze()
  if not frozen then
    _fill_defaults(cfg)
    frozen = true
  end
  return cfg
end

function m.configure(options)
  assert(not frozen, "substrate cannot be configured twice!")
  truss.extend_table(cfg, options)
end

return m