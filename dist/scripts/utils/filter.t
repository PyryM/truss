-- utils/filter.t
--
-- utilities for creating filtering functions

local m = {}

function m.subkey(keylist)
  return function(t)
    for _, k in ipairs(keylist) do
      t = t[k]
      if not t then return false end
    end
    return t
  end
end

-- e.g., tagged("mat", "transparent")
function m.tagged(k1, k2)
  return m.subkey({k1, "tags", k2})
end

-- e.g., not_tagged("mat", "transparent")
function m.not_tagged(k1, k2)
  local f = m.tagged(k1, k2)
  return function(t)
    return not f(t)
  end
end

return m
