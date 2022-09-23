-- substrate/derive.t
--
-- functions for manipulating types

local m = {}
local intrinsics = require("./intrinsics.t")
local clib = require("./clib.t")

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
function m.is_plain_data(T)
  if T:ispointer() then return false end
  if T:isprimitive() then return true end
  for _, ftype in m.ifields(T) do
    if not m.is_plain_data(ftype) then return false end
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

m.FORMATS = {
  [int8] = "%hhd", [int16] = "%hd", [int32] = "%d", [int64] = "%lld",
  [uint8] = "%hhu", [uint16] = "%hu", [uint32] = "%u", [uint64] = "%llu",
  [float] = "%g", [double] = "%g", [&int8] = "%s"
}

function m.dump_value(val, fname, ftype) 
  if ftype == bool then
    return quote 
      if val.[fname] then
        clib.io.printf("%s: true\n", fname)
      else
        clib.io.printf("%s: false\n", fname)
      end
    end
  end

  local fmt = m.FORMATS[ftype]
  if (not fmt) and ftype:ispointer() then
    fmt = "%p"
  end

  if fmt then
    local pstr = fname .. ": " .. fmt .. "\n"
    return quote clib.io.printf(pstr, val.[fname]) end
  else
    local pstr = fname .. ": ?\n"
    return quote clib.io.printf(pstr) end
  end
end

function m.clear_fields(val)
  return m.call_on_fields(val, "clear", m.init_default)
end

function m.init_fields(val)
  return m.call_on_fields(val, "init", m.init_default)
end

function m.dump_fields(val)
  return m.call_on_fields(val, "dump", m.dump_value)
end

function m.copy_fields(dest, src)
  local statements = {}
  local T = dest.type or dest:gettype()
  if T:ispointer() then T = T.type end
  for fname, ftype in m.ifields(T) do
    if ftype.methods then
      assert(ftype.methods["copy"], tostring(ftype) .. " missing :copy!")
      table.insert(statements, quote 
        dest.[fname]:copy(&(src.[fname]))
      end)
    else
      -- assume primitive
      assert(not ftype:ispointer(), "Tried to shallow copy a pointer in " .. tostring(T) .. "." .. fname)
      table.insert(statements, quote
        dest.[fname] = src.[fname]
      end)
    end
  end
  return statements
end

function m.copy(dest, src)
  local T = dest.type or dest:gettype()
  assert(T:ispointer(), "derive.copy expects dest and src as pointers!")
  T = T.type
  if m.is_plain_data(T) then
    return quote @dest = @src end
  else
    assert(T.methods and T.methods["copy"], tostring(T) .. " missing :copy!")
    return quote dest:copy(src) end
  end
end

function m.copy_array(dest, src, count)
  local T = dest.type or dest:gettype()
  assert(T:ispointer(), "derive.copy_array expects dest and src as pointers!")
  T = T.type
  if m.is_plain_data(T) then
    return quote
      intrinsics.memcpy(dest, src, count * sizeof(T))
    end
  else
    assert(T.methods and T.methods["copy"], tostring(T) .. " missing :copy!")
    return quote
      for idx = 0, count do
        dest[idx]:copy(src + idx)
      end
    end
  end
end

function m.clear_array(dest, count)
  local T = dest.type or dest:gettype()
  assert(T:ispointer(), "derive.clear_array expects dest as pointer!")
  T = T.type
  if m.is_plain_data(T) then
    return quote
      intrinsics.memset(dest, 0, count * sizeof(T))
    end
  else
    assert(T.methods and T.methods["clear"], tostring(T) .. " missing :clear!")
    return quote
      for idx = 0, count do
        dest[idx]:clear()
      end
    end
  end
end

function m.fill_array(dest, val, count)
  local T = dest.type or dest:gettype()
  assert(T:ispointer(), "derive.fill_array expects dest as pointer!")
  T = T.type
  if m.is_plain_data(T) then
    return quote
      for idx = 0, count do
        dest[idx] = val
      end
    end
  else
    assert(T.methods and T.methods["copy"], tostring(T) .. " missing :copy!")
    local VT = val.type or val:gettype()
    if VT:ispointer() then
      return quote
        for idx = 0, count do
          dest[idx]:copy(val)
        end
      end
    else
      return quote
        for idx = 0, count do
          dest[idx]:copy(&val)
        end
      end
    end
  end
end

function m.derive_init(T)
  assert(not T.methods.init, tostring(T) .. " already has :init!")
  terra T.methods.init(self: &T)
    [m.init_fields(self)]
  end
end

function m.derive_clear(T)
  assert(not T.methods.clear, tostring(T) .. " already has :clear!")
  terra T.methods.clear(self: &T)
    [m.clear_fields(self)]
  end
end

function m.derive_dump(T)
  assert(not T.methods.dump, tostring(T) .. " already has :dump!")
  terra T.methods.dump(self: &T)
    [m.dump_fields(self)]
  end
end

function m.derive_copy(T)
  assert(not T.methods.copy, tostring(T) .. " already has :copy!")
  terra T.methods.copy(self: &T, rhs: &T)
    [m.copy_fields(self, rhs)]
  end
end

function m.add_method(T, methodname, method)
  method:setname(methodname)
  T.methods[methodname] = method
end

return m

return m