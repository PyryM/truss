local m = {}

function m.make_enum(name, vals)
  local struct e {
    value: uint32;
  }
  e:setname(name)

  local sorted_values = {}
  for name, val in pairs(vals) do
    table.insert(sorted_values, {name=name, value=val})
  end
  table.sort(sorted_values, function(a, b)
    return a.value < b.value
  end)

  local function _constant_map_vals(self_q, f)
    local cases = {}
    for _, v in ipairs(sorted_values) do
      table.insert(cases, quote
        case [v.value] then
          return [f(v)]
        end
      end)
    end
    return quote
      switch self_q.value do
      [cases]
      end
    end
  end

  terra e:to_cstring(): &int8
    [_constant_map_vals(self, function(v)
      return v.name
    end)]
    return nil
  end

  terra e:is_valid(): bool
    [_constant_map_vals(self, function(v)
      return true
    end)]
    return false
  end

  return e
end

return m