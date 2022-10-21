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

function m.lazy_table(existing_items, lazy_items)
  existing_items._items = lazy_items
  return setmetatable(existing_items, lazy_mt)
end

return m