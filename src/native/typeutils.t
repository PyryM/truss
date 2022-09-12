-- typeutils.t
--
-- misc utilities for dealing w/ terra types

local m = {}

function m.has_method(T, name)
  return T.methods[name] ~= nil
end

function m.iterfields(T)
  local pos = 1
  return function()
    local curfield = T.entries[pos]
    if not curfield then return nil, nil end
    local name = curfield.field or curfield[1]
    local kind = curfield.type or curfield[2]
    pos = pos + 1
    return name, kind
  end
end
m.ifields = m.iterfields -- for compat?

function m.iterargs(f)
  local pos = 1
  return function()
    local arg = f.definition.parameters[pos]
    if not arg then return nil, nil end
    pos = pos + 1
    return arg.name, arg.type
  end
end

-- checks whether a type T is an aggregate of types
-- without any pointers/dynamic allocations
function m.is_trivially_serializable(T)
  if T:ispointer() then return false end
  if T:isprimitive() then return true end
  for _, ftype in m.ifields(T) do
    if not m.is_trivially_serializable(ftype) then return false end
  end
  return true
end

function m.call_if_present(val, fname, args)
  args = args or {}
  local T = val:gettype()
  if T.methods[fname] then
    return quote
      val:[fname]([args])
    end
  else
    return quote end
  end
end

function m.call_on_fields(val, func_names, default_gen)
  if type(func_names) == "string" then func_names = {func_names} end
  local statements = {}
  local T = val.type or val:gettype()
  if T:ispointer() then T = T.type end
  for fname, ftype in m.ifields(T) do
    local generated = false
    if ftype.methods then
      local f = nil
      for _, func in ipairs(func_names) do
        if ftype.methods[func] then
          f = ftype.methods[func]
          break
        end
      end
      if f then
        generated = true
        table.insert(statements, quote f(&val.[fname]) end)
      end
    end
    if (not generated) and default_gen then
      local s = default_gen(val, fname, ftype)
      if s then table.insert(statements, s) end
    end
  end
  return statements
end

m.DEFAULTS = {
  [int8] = 0, [int16] = 0, [int32] = 0, [int64] = 0,
  [uint8] = 0, [uint16] = 0, [uint32] = 0, [uint64] = 0,
  [float] = 0, [double] = 0,
  [bool] = false,
}

function m.init_default(val, fname, ftype, defaults)
  defaults = defaults or m.DEFAULTS
  local default_val = defaults[ftype] or m.DEFAULTS[ftype]
  -- note explicit nil check because false is a valid default
  if default_val ~= nil then 
    return quote val.[fname] = default_val end
  end
end

function m.clear_fields(val)
  return m.call_on_fields(val, "clear", m.init_default)
end

function m.init_fields(val)
  return m.call_on_fields(val, "init", m.init_default)
end

return m
