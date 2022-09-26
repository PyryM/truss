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
        clib.std.exit(2) 
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
    local allocator = cfg.allocator
    if not allocator then allocator = "libc_allocator" end
    if type(allocator) == 'string' then
      local modulename = "./allocators/" .. allocator .. ".t"
      allocator = assert(require(modulename), "Couldn't load allocator " .. modulename)
    end
    if type(allocator) == 'function' then
      allocator = allocator(cfg)
    end
    cfg.allocator = allocator
    cfg.ALLOCATE = assert(allocator.ALLOCATE, "allocator module has no ALLOCATE!")
    cfg.ALLOCATE_ZEROED = assert(allocator.ALLOCATE_ZEROED, "allocator module has no ALLOCATE_ZEROED!")
    cfg.FREE = assert(allocator.FREE, "allocator module has no FREE!")
  end

  if not cfg.LOG then
    cfg.LOG = require("./log.t").default_log(cfg)
  end

  if not cfg.size_t then
    cfg.size_t = assert(require("./clib.t").std.size_t)
  end
end

function m._freeze()
  _fill_defaults(cfg)
  frozen = true
end

function m.configure(...)
  local nargs = select('#', ...)
  local options = select(1, ...)
  if nargs == 0 then
    if not frozen then
      log.warn("substrate never configured; using default config")
      m._freeze()
    end
    return cfg
  end
  assert(options, "substrate.configure passed nil configuration!")
  assert(not frozen, "substrate cannot be configured twice!")
  truss.extend_table(cfg, options)
  m._freeze()
  
  return cfg
end

m.exported_names = {"configure"}

return m