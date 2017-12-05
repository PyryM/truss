-- devtools/debug.t
--
-- helpful debuggin utilities

local m = {}

function m.install_access_guard(target_class, tag, crash_on_nil)
  target_class.__index = function (t,k)
    local v = (t.class or {})[k]
    if not v then
      log.debug(tag .. " nil access on '" .. k .. "'")
      if crash_on_nil then truss.error("nil access") end
    end
    return v
  end
end

-- deprecate a function to print a warning if it is called
-- e.g., bla.old_func = deprecate(bla.old_func, "old_func", "new_func")
function m.deprecate(func, oldname, newname)
  local called = false
  return function(...)
    if not called then
      local msg = fname .. " is deprecated."
      if newname then 
        msg = msg .. " Use " .. newname .. " instead."
      end
      truss.warn(msg)
      called = true
    end
    return func(...)
  end
end

return m