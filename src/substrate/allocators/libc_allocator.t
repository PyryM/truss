-- substrate/allocators/libc_allocator.t
--
-- basic libc-based allocator

local function build(cfg)
  local c = require("substrate/libc.t")
  local alloc = {}

  function alloc.ALLOCATE(T, count)
    if not count then
      return `[&T](c.std.malloc(sizeof(T)))
    else
      return `[&T](c.std.malloc(count * sizeof(T)))
    end
  end

  function alloc.ALLOCATE_ZEROED(T, count)
    if not count then
      return `[&T](c.std.calloc(1, sizeof(T)))
    else
      return `[&T](c.std.calloc(count, sizeof(T)))
    end
  end

  function alloc.FREE(ptr)
    return quote c.std.free(ptr) end
  end

  return alloc
end

return build