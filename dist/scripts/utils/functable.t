-- utils/functable.t
--
-- wraps a function (and optionally table) into a 'functable'
-- (e.g., a callable table)

local function functable(f, t)
  t = t or {}
  local mt = {
    __call = function(_t, ...)
      return f(...)
    end
  }
  setmetatable(t, mt)
  return t
end

return functable