-- util/state.t
--
-- utilities for turning state changes into events

local m = {}

function m.compare(old_state, new_state)
  local old_changed = {}
  local new_changed = {}
  local has_changes = false

  for k, v in pairs(new_state) do
    local old_v = old_state[k]
    vtype = type(v)
    if vtype == "number" then
      if v ~= old_v then
        old_changed[k] = old_v
        new_changed[k] = v
        has_changes = true
      end
    else -- assume table, recurse
      old_changed[k], new_changed[k] = m.compare(old_v, v)
      has_changes = has_changes or (new_changed[k] ~= nil)
    end
  end

  if has_changes then
    return old_changed, new_changed
  else
    return nil
  end
end

function m.threshold(v, thresh)
  if v > thresh then return 1.0 else return 0.0 end
end

return m