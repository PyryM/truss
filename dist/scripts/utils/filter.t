-- utils/filter.t
--
-- utilities for creating filtering functions

local m = {}

local function subkey(keylist, t)
  for _, k in ipairs(keylist) do
    t = t[k]
    if not t then return t end -- returns nil or false
  end
  return t
end

-- e.g., tagged("mat", "transparent")
function m.tagged(k1, k2)
  return function(t)
    local v = subkey({k1, "tags", k2}, t)
    return v
  end
end

-- e.g., not_tagged("mat", "transparent")
function m.not_tagged(k1, k2)
  return function(t)
    local v = subkey({k1, "tags", k2}, t)
    return not v
  end
end

function m.material_tagged(k)
  return function(t)
    if not t.mat then return true end
    return t.mat.tags and t.mat.tags[k]
  end
end

function m.material_not_tagged(k)
  return function(t)
    if not t.mat then return true end
    return not (t.mat.tags and t.mat.tags[k])
  end
end

return m
