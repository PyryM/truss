-- utils/badstruct.t
--
-- deal with misaligned structures
-- (I'm looking at you, VALVE)

local class = require("class")

local m = {}

local BadStruct = class("BadStruct")
m.BadStruct = BadStruct

local function make_getter(ttype, offset)
  local g = terra (data: &uint8): ttype
    return @[&ttype](data + offset)
  end
  return g
end

local function make_setter(ttype, offset)
  local g = terra (data: &uint8, val: ttype)
    @[&ttype](data + offset) = val
  end
end

function BadStruct:init(def)
  if not def then return end
  self._size = 0
  self._fields = {}
  for fieldname, field in pairs(def) do
    self._size = math.max(self._size, field.offset + sizeof(field.ttype))
    self._fields[fieldname] = {get = make_getter(field.ttype, field.offset),
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

return m