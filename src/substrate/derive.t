-- substrate/derive.t
--
-- functions for manipulating types

local m = {}
local intrinsics = require("./intrinsics.t")
local libc = require("./libc.t")

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
-- (results are cached for performance reasons)
local queried_pod_types = {}
function m.is_plain_data(T)
  if queried_pod_types[T] == nil then
    queried_pod_types[T] = m._is_plain_data(T)
  end
  return queried_pod_types[T]
end

function m._is_plain_data(T)
  if T.field then
    -- a union?
    print("Union?", T.field, T.type)
    return m.is_plain_data(T.type)
  end
  if T:ispointer() then return false end
  if T:isprimitive() then return true end
  if T:isarray() then return m.is_plain_data(T.type) end
  for _, ftype in m.ifields(T) do
    if not m.is_plain_data(ftype) then return false end
  end
  return true
end

function m.can_init_by_zeroing(T)
  if T.methods and T.methods["init"] then 
    return false 
  end
  return T:ispointer() or m.is_plain_data(T)
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
  if ftype:ispointer() then
    return quote val.[fname] = nil end
  end
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

function m.dump_value(val, T)
  if not T then
    T = assert(val.type or val:gettype(),
      "Coulnd't determine type of " .. tostring(val))
  end
  if T == bool then
    return quote 
      if val == true then
        libc.io.printf("true\n")
      else
        libc.io.printf("false\n")
      end
    end
  end

  local fmt = m.FORMATS[T]
  if (not fmt) and T:ispointer() then
    fmt = "%p"
  end

  if fmt then
    local pstr = fmt .. "\n"
    return quote libc.io.printf(pstr, val) end
  elseif T:isstruct() then
    if T.methods.dump then
      return quote val:dump() end
    else
      return quote 
        [m.dump_fields(val)]
      end
    end
  else
    local typestr = (tostring(T) or "?") .. "\n"
    return quote libc.io.printf(typestr) end
  end  
end

function m.dump_field_value(val, fname, ftype)
  local statements = {
    quote libc.io.printf("%s: ", fname) end,
    m.dump_value(`val.[fname], ftype)
  }
  return quote [statements] end
end

function m.init_fields(val)
  return m.call_on_fields(val, "init", m.init_default)
end

function m.release_fields(val)
  return m.call_on_fields(val, "release")
end

function m.clear_fields(val)
  return m.call_on_fields(val, "clear", m.init_default)
end

function m.dump_fields(val)
  return m.call_on_fields(val, "dump", m.dump_field_value)
end

function m.copy(dest, src)
  local T = dest.type or dest:gettype()
  assert(T:ispointer(), "derive.copy expects dest and src as pointers!")
  T = T.type
  if T.methods and T.methods["copy"] then
    return quote dest:copy(src) end
  elseif m.is_plain_data(T) then
    return quote @dest = @src end
  else
    error("Don't know how to copy " .. tostring(T) .. ": type is not POD and has no .copy!")
  end
end

function m.copy_fields(dest, src)
  local statements = {}
  local T = dest.type or dest:gettype()
  if T:ispointer() then T = T.type end
  for fname, ftype in m.ifields(T) do
    if ftype.methods and ftype.methods["copy"] then
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

-- TOOD: refactor w/ above
function m.move_fields(dest, src)
  local statements = {}
  local T = dest.type or dest:gettype()
  if T:ispointer() then T = T.type end
  for fname, ftype in m.ifields(T) do
    if ftype.methods and ftype.methods["move"] then
      table.insert(statements, quote 
        dest.[fname]:move(&(src.[fname]))
      end)
    elseif ftype:ispointer() or m.is_plain_data(ftype) then
      table.insert(statements, quote
        dest.[fname] = src.[fname]
      end)
    end
  end
  return statements
end

function m.map_array_method(dest, src, count, methodname, fallback)
  local T = dest.type or dest:gettype()
  assert(T:ispointer(), "derive.map_array expects dest and src as pointers!")
  T = T.type
  if T.methods and T.methods[methodname] then
    return quote
      for idx = 0, count do
        var item = &dest[idx]
        item:[methodname](&src[idx])
      end
    end
  else
    assert(fallback, "No fallback array mapper!")
    return fallback(T, dest, src, count)
  end
end

function m.iter_array_method(dest, count, methodname, fallback)
  local T = dest.type or dest:gettype()
  assert(T:ispointer(), "derive.iter_array_method expects dest!")
  T = T.type
  if T.methods and T.methods[methodname] then
    return quote
      for idx = 0, count do
        var item = &dest[idx]
        item:[methodname]()
      end
    end
  else
    assert(fallback, "No fallback array mapper!")
    return fallback(T, dest, count)
  end
end

function m.copy_array(dest, src, count)
  return m.map_array_method(dest, src, count, "copy", function(T, dest, src, count)
    local copyable = m.is_plain_data(T) or T:ispointer() 
      or (T.substrate and T.subtrate.allow_copy_by_memcpy)
    assert(copyable, "Unable to determine how to copy type " .. tostring(T))
    return quote
      intrinsics.memcpy([&uint8](dest), [&uint8](src), count * sizeof(T))
    end
  end)
end

function m.move_array(dest, src, count)
  return m.map_array_method(dest, src, count, "move", function(T, dest, src, count)
    local copyable = m.is_plain_data(T) or T:ispointer() 
      or (T.substrate and T.subtrate.allow_move_by_memcpy)
    assert(copyable, "Unable to determine how to move type " .. tostring(T))
    return quote
      intrinsics.memcpy([&uint8](dest), [&uint8](src), count * sizeof(T))
    end
  end)
end

function m.release_array_contents(dest, count)
  return m.iter_array_method(dest, count, "release", function(T, dest, count)
    local does_not_need_release = m.is_plain_data(T) or T:ispointer() -- eh?
    assert(does_not_need_release, "Unable to determine how to release type " .. tostring(T))
    return quote end
  end)
end

function m.init_array_contents(dest, count)
  return m.iter_array_method(dest, count, "init", function(T, dest, count)
    local init_by_zero = m.is_plain_data(T) or T:ispointer()
    assert(init_by_zero, "Unable to determine how to init type " .. tostring(T))
    return quote
      intrinsics.memset([&uint8](dest), 0, count * sizeof(T))
    end
  end)
end

-- HMM
function m.fill_array(dest, val, count)
  local T = dest.type or dest:gettype()
  assert(T:ispointer(), "derive.fill_array expects dest as pointer!")
  T = T.type
  if T.methods and T.methods["copy"] then
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
  elseif m.is_plain_data(T) or T:ispointer() then
    return quote
      for idx = 0, count do
        dest[idx] = val
      end
    end
  else
    error("Unsure how to fill array of type " .. tostring(T))
  end
end

function m.derive_init(T)
  assert(not T.methods.init, tostring(T) .. " already has :init!")
  terra T.methods.init(self: &T)
    [m.init_fields(self)]
  end
end

function m.derive_release(T)
  assert(not T.methods.release, tostring(T) .. " already has :release!")
  terra T.methods.release(self: &T)
    [m.release_fields(self)]
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

function m.derive_move(T)
  assert(not T.methods.move, tostring(T) .. " already has :move!")
  terra T.methods.move(self: &T, rhs: &T)
    [m.move_fields(self, rhs)]
  end
end

function m.add_method(T, methodname, method)
  method:setname(methodname)
  T.methods[methodname] = method
end

return m
