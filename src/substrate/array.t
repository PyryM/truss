local m = {}
local lazy = require("./lazyload.t")

m.Slice = terralib.memoize(function(T)
  local cfg = require("./cfg.t").freeze()
  local size_t = cfg.size_t

  local struct Slice {
    ptr: &T;
    size: size_t;
  }

  terra Slice:size_bytes(): size_t
    return self.size * sizeof(T)
  end

  return Slice
end)

m.Array = terralib.memoize(function(T)
  local cfg = require("./cfg.t").freeze()
  local derive = require("./derive.t")
  local intrinsics = require("./intrinsics.t")

  local size_t = cfg.size_t
  local ALLOCATE = cfg.ALLOCATE
  local FREE = cfg.FREE
  local ASSERT = cfg.ASSERT

  local Slice = m.Slice(T)
  local Bytes = m.Slice(uint8)

  local struct Array {
    capacity: size_t;
    size: size_t;
    data: &T;
  }
  derive.derive_init(Array)

  terra Array:release()
    [FREE(`self.data)]
    self:init()
  end

  terra Array:allocate(n: size_t)
    self:release()
    self.capacity = n
    self.size = 0
    self.data = [ALLOCATE(T, `n)]
  end

  terra Array:as_bytes(): Bytes
    return Bytes{ptr = [&uint8](self.data), len = self.size*sizeof(T)}
  end

  terra Array:slice(start: size_t, stop: size_t): Slice
    [ASSERT(`start <= self.size and stop <= self.size, "OOB slice!")]
    [ASSERT(`stop >= start, "slice stop must come after start!)]
    return Slice{ptr = self.data+start, len = stop - start}
  end

  terra Array:swap(rhs: &Array)
    if rhs.capacity ~= self.capacity then return end
    if rhs.size ~= self.size then return end
    var temp_data: &T = self.data
    self.data = rhs.data
    rhs.data = temp_data
  end

  terra Array:copy_raw(data: &T, count: size_t)
    [ASSERT(`count <= self.capacity, "Tried to copy more than capacity!")]
    [derive.copy_array(`self.data, `data, `count)]
    self.size = count
  end

  terra Array:copy(rhs: &Array)
    self:copy_raw(rhs.data, rhs.size)
  end

  terra Array:copy_slice(rhs: &Slice)
    self:copy_raw(rhs.ptr, rhs.size)
  end

  if derive.is_plain_data(T) then
    -- Copying raw bytes only makes sense if this is a POD type
    terra Array:copy_raw_bytes(data: &uint8, nbytes: size_t)
      [ASSERT(`nbytes <= self.capacity * sizeof(T), "Tried to copy more bytes than capacity!)]
      intrinsics.memcpy([&uint8]self.data, data, nbytes)
      self.size = nbytes / sizeof(T)
    end
  end

  if derive.is_plain_data(T) 
    terra Array:clear()
      self.size = 0
    end
  elseif T:ispointer() then
    terra Array:clear()
      intrinsics.memset(self.data, 0, self.size * sizeof(T))
      self.size = 0
    end
  else
    terra Array:clear()
      [derive.clear_array(`self.data, `self.size)]
      self.size = 0
    end
  end

  terra Array:fill(val: T, count: size_t)
    [ASSERT(`count <= self.capacity, "Tried to fill more than capacity!")]
    [derive.fill_array(`self.data, `val, `count)]
    self.size = count
  end

  terra Array:push_new(): &T
    [ASSERT(`self.size < self.count, "No capacity for a new element!")]
    var ret: &T = &(self.data[self.size])
    self.size = self.size + 1
    return ret
  end

  terra Array:push_val(val: T)
    [ASSERT(`self.size < self.count, "No capacity for a new element!")]
    self.data[self.size] = val
    self.size = self.size + 1
    return true
  end

  return Array
end)

local lazy_items = {
  ByteArray = function() return m.Array(uint8) end,
  ByteSlice = function() return m.Slice(uint8) end,
}

return lazy.lazy_table(m, lazy_items)