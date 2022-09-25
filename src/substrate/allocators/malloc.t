-- substrate/allocators/malloc.t
--
-- basic malloc/free based allocator

local function build(cfg)
  local c = require("substrate/clib.t")
  local alloc = {}

  function alloc.ALLOCATE(T, count)
    if count then
      return `[&T](c.std.malloc(sizeof(T)))
    else
      return `[&T](c.std.malloc(sizeof(T) * count))
    end
  end

  function alloc.FREE(ptr)
    return quote c.std.free(ptr) end
  end

  return alloc
end

return build