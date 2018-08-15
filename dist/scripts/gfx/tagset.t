-- gfx/tagset.t
--
-- represents a set of tags that 'hashes' to a string

local m = {}

local function sort_tags(tags)
  local keys = {}
  for k, _ in pairs(tags) do table.insert(keys, k) end
  table.sort(keys)
  return keys
end

local function hash(tags)
  local t = {}
  for idx, tname in ipairs(sort_tags(tags)) do
    t[idx] = string.format("%s=%s", tname, tostring(tags[tname]))
  end
  return table.concat(t, "|")
end

local function clone(outer)
  return m.tagset(rawget(outer, '_inner'))
end

local function extend(outer, other)
  local i1 = rawget(outer, '_inner')
  -- allow 'other' to be a plain table
  local i2 = rawget(other, '_inner') or other
  for k, v in pairs(i2) do i1[k] = v end
  rawset(outer, 'hash', nil) -- dirty ourselves
end

local inner_funcs = {
  hash = function(outer, inner)
    local h = hash(inner) 
    rawset(outer, 'hash', h)
    return h
  end,
  clone = function(outer, inner)
    return clone
  end,
  extend = function(outer, inner)
    return extend
  end
}

-- using metatable tricks makes it inconvenient to use the standard 30log
local mt = {
  __index = function(outer, k)
    local inner = rawget(outer, '_inner')
    local ifunc = inner_funcs[k]
    if ifunc then return ifunc(outer, inner) end
    return inner[k]
  end,
  __newindex = function(outer, k, v)
    local inner = rawget(outer, '_inner')
    inner[k] = v
    rawset(outer, 'hash', nil)
  end
}

function m.tagset(tags)
  local tset = {_inner = truss.extend_table({}, tags)}
  setmetatable(tset, mt)
  return tset
end

return m