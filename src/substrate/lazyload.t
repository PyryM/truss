local m = {}

local lazy_mt = {
  __index = function(t, k)
    local items = rawget(t, "_items")
    if items[k] then
      local val = items[k]()
      rawset(t, k, val)
      return val
    end
  end
}

function m.lazy_table(items)
  return setmetatable({_items = items}, lazy_mt)
end

return m