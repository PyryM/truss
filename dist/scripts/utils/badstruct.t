-- utils/badstruct.t
--
-- deal with misaligned structures
-- (I'm looking at you, VALVE)

local class = require("class")

local m = {}

local BadStruct = class("BadStruct")
m.BadStruct = BadStruct

local function make_getter(ttype, offset, is_arr)
  local g
  if is_arr then
    g = terra (data: &uint8): &ttype
      return [&ttype](data + offset)
    end
  else
    g = terra (data: &uint8): ttype
      return @[&ttype](data + offset)
    end
  end
  return g
end

local function make_setter(ttype, offset)
  local g = terra (data: &uint8, val: ttype)
    @[&ttype](data + offset) = val
  end
  return g
end

function BadStruct:init(def)
  if not def then return end
  self._size = 0
  self._fields = {}
  for fieldname, field in pairs(def) do
    local fsize = field.offset + (sizeof(field.ttype) * (field.count or 1))
    self._size = math.max(self._size, fsize)
    self._fields[fieldname] = {get = make_getter(field.ttype, field.offset, field.is_arr),
                               set = make_setter(field.ttype, field.offset)}
  end
  if def.size and def.size < self._size then
    truss.error("BadStruct too small: " .. def.size .. " < " .. self._size)
  end
  self._size = def.size or self._size
  self._data = terralib.new(uint8[self._size])
end

function BadStruct:decode()
  for fname, field in pairs(self._fields) do
    self[fname] = field.get(self._data)
  end
end

function BadStruct:encode()
  for fname, field in pairs(self._fields) do
    field.set(self._data, self[fname])
  end
end

function BadStruct:clone()
  local ret = BadStruct()
  ret._size = self._size
  ret._fields = self._fields
  ret._data = terralib.new(uint8[ret._size])
  for i = 0, ret._size-1 do
    ret._data[i] = self._data[i]
  end
  return ret
end

function BadStruct:print_ints()
  local ret = ""
  for i = 0, self._size - 1 do
    ret = ret .. " " .. number(self._data[i])
  end
  return ret
end

return m