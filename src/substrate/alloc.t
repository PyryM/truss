local m = {}

function m.default_allocators(cfg)
  local c = require("./clib.t")

  local alloc = {}
  function alloc.ALLOCATE(T, count)
    if count then
      return `[&T](c.std.malloc(sizeof(T)))
    else
      return `[&T](c.std.malloc(sizeof(T) * count))
    end
  end

  function alloc.FREE(ptr)
    return quote c.std.free(v) end
  end

  return alloc
end

return m