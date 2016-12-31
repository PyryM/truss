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

return m