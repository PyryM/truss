-- substrate/allocators/leaky_allocator.t
--
-- an allocator that never frees memory 
-- (for debugging)

local function build(cfg)
  log.bigwarn("Using leaky allocator!")
  local c = require("substrate/libc.t")
  local alloc = {}

  local LOG = assert(cfg.LOG)

  local function log_return(f)
    return function(...)
      local inner = f(...)
      return quote
        var _ret = [inner]
        [LOG("Allocation: %p", `_ret)]
      in
        _ret
      end
    end
  end

  alloc.ALLOCATE = log_return(function(T, count)
    if not count then
      return `[&T](c.std.malloc(sizeof(T)))
    else
      return `[&T](c.std.malloc(count * sizeof(T)))
    end
  end)

  alloc.ALLOCATE_ZEROED = log_return(function(T, count)
    if not count then
      return `[&T](c.std.calloc(1, sizeof(T)))
    else
      return `[&T](c.std.calloc(count, sizeof(T)))
    end
  end)

  function alloc.FREE(ptr)
    -- don't do anything!
    return quote 
      [LOG("Would have freed: %p", `ptr)]
    end
  end

  return alloc
end

return build