local m = {}
local lazy = require("./lazyload.t")
local util = require("./util.t")

function m._Slice(T, options)
  assert(T, "No type provided!")

  options = options or {}
  local cfg = options.cfg or require("./cfg.t").configure()
  local size_t = assert(cfg.size_t, "No size_t!")

  local struct Slice {
    data: &T;
    size: size_t;
  }

  terra Slice:size_bytes(): size_t
    return self.size * sizeof(T)
  end

  terra Slice:as_u8(): &uint8
    return [&uint8](self.data)
  end

  Slice.substrate = {
    allow_move_by_memcpy = true
  }
  
  util.set_template_name(Slice, "Slice", T)

  return Slice
end
m.Slice = terralib.memoize(m._Slice)

function m._Array(T, options)
  options = options or {}
  local cfg = options.cfg or require("./cfg.t").configure()
  local derive = require("./derive.t")
  local intrinsics = require("./intrinsics.t")
  local libc = require("./libc.t")

  local size_t = cfg.size_t
  local ALLOCATE = cfg.ALLOCATE
  local FREE = cfg.FREE
  local ASSERT = cfg.ASSERT
  local LOG = cfg.LOG

  local Slice = options.slice_t or m.Slice(T)
  local ByteSlice = m.Slice(uint8)

  local struct Array {
    capacity: size_t;
    size: size_t;
    data: &T;
  }
  derive.derive_init(Array)

  terra Array:release()
    [derive.release_array_contents(`self.data, `self.size)]
    [FREE(`self.data)]
    self:init()
  end

  terra Array:allocate(n: size_t)
    self:release()
    self.capacity = n
    self.size = 0
    self.data = [ALLOCATE(T, `n)]
  end

  if options.allow_growth then
    terra Array:resize_capacity(new_capacity: size_t)
      if new_capacity == self.capacity then return end
      --[LOG("Resizing capacity to %d", `new_capacity)]
      -- TODO: realloc this?
      var new_data = [ALLOCATE(T, `new_capacity)]
      var ncopy = self.size
      if ncopy > new_capacity then ncopy = new_capacity end
      if ncopy > 0 then
        [derive.move_array(`new_data, `self.data, `ncopy)]
      end
      [derive.release_array_contents(`self.data, `self.size)]
      [FREE(`self.data)]
      self.data = new_data
      self.capacity = new_capacity
      if self.size > self.capacity then
        self.size = self.capacity
      end
    end

    terra Array:fit_capacity(needed_capacity: size_t)
      --[LOG("Fitting capacity to %d", `needed_capacity)]
      if needed_capacity < self.capacity / 2 then
        self:resize_capacity(needed_capacity)
      elseif needed_capacity > self.capacity then
        var newcap = self.capacity
        if newcap == 0 then newcap = needed_capacity end
        while newcap < needed_capacity do
          newcap = newcap * 2
        end
        self:resize_capacity(newcap)
      end
    end
  else
    terra Array:fit_capacity(needed_capacity: size_t)
      if self.capacity == 0 then
        self:allocate(needed_capacity)
      else
        [ASSERT(`needed_capacity <= self.capacity, "Exceeded capacity!")]
      end
    end
  end

  terra Array:as_bytes(): ByteSlice
    return ByteSlice{data = [&uint8](self.data), size = self.size*sizeof(T)}
  end

  terra Array:size_bytes(): size_t
    return self.size * sizeof(T)
  end

  terra Array:slice(start: size_t, stop: size_t): Slice
    [ASSERT(`start <= self.size and stop <= self.size, "OOB slice!")]
    [ASSERT(`stop >= start, "slice stop must come after start!")]
    return Slice{data = self.data+start, size = stop - start}
  end

  terra Array:as_slice(): Slice
    return Slice{data = self.data, size = self.size}
  end

  terra Array:swap(rhs: &Array)
    if rhs.capacity ~= self.capacity then return end
    if rhs.size ~= self.size then return end
    var temp_data: &T = self.data
    self.data = rhs.data
    rhs.data = temp_data
  end

  terra Array:copy_raw(data: &T, count: size_t)
    self:fit_capacity(count)
    [derive.copy_array(`self.data, `data, `count)]
    self.size = count
  end

  terra Array:copy(rhs: &Array)
    self:copy_raw(rhs.data, rhs.size)
  end

  terra Array:copy_slice(rhs: Slice)
    self:copy_raw(rhs.data, rhs.size)
  end

  if derive.is_plain_data(T) then
    -- Copying raw bytes only makes sense if this is a POD type
    terra Array:copy_raw_bytes(data: &uint8, nbytes: size_t)
      [ASSERT(`nbytes <= self.capacity * sizeof(T), "Tried to copy more bytes than capacity!")]
      intrinsics.memcpy([&uint8](self.data), data, nbytes)
      self.size = nbytes / sizeof(T)
    end
  end

  terra Array:resize(newsize: size_t)
    self:fit_capacity(newsize)
    if newsize < self.size then
      [derive.release_array_contents(`self.data + newsize, `self.size - newsize)]
    elseif newsize > self.size then
      [derive.init_array_contents(`self.data + self.size, `newsize - self.size)]
    end
    self.size = newsize
  end

  terra Array:resize_to_capacity()
    self:resize(self.capacity)
  end

  terra Array:fill(newsize: size_t, val: T)
    [ASSERT(`newsize >= self.size, "Must :fill to at least existing size!")]
    var startpos = self.size
    self:resize(newsize)
    [derive.fill_array(`self.data + startpos, `val, `newsize - startpos)]
  end

  terra Array:fill_to_capacity(val: T)
    self:fill(self.capacity, val)
  end

  terra Array:clear()
    self:resize(0)
  end

  terra Array:push_new(): &T
    self:fit_capacity(self.size + 1)
    var ret: &T = &(self.data[self.size])
    self.size = self.size + 1
    [derive.init_array_contents(`ret, 1)]
    return ret
  end

  -- Note: we're relying on return-type inference here
  terra Array:get_ref(idx: size_t)
    [ASSERT(`idx >= 0 and idx < self.size, "OOB array access!")]
    escape
      -- hmmmm
      if T.methods and T.methods.get_ref then
        emit(quote return self.data[idx]:get_ref() end)
      else
        emit(quote return self.data + idx end)
      end
    end
  end

  if derive.is_plain_data(T) or T:ispointer() then
    log.build("Plain data push?")
    terra Array:push_val(val: T)
      self:fit_capacity(self.size + 1)
      self.data[self.size] = val
      self.size = self.size + 1
    end

    terra Array:get_val(idx: size_t): T
      [ASSERT(`idx >= 0 and idx < self.size, "OOB array access!")]
      return self.data[idx]
    end

    terra Array:push_bytes(bytes: &uint8, len: size_t)
      [ASSERT(`len % sizeof(T) == 0, "len of pushed bytes is not a multiple of object type!")]
      var nitems: size_t = len / sizeof(T)
      self:fit_capacity(self.size + nitems)

      intrinsics.memcpy(
        [&uint8](self.data + self.size),
        bytes, 
        nitems * sizeof(T)
      )
      self.size = self.size + nitems
    end
  end

  Array.substrate = {
    -- not 100% sure about this inference
    allow_move_by_memcpy = (T.substrate and T.substrate.allow_move_by_memcpy)
                           or derive.is_plain_data(T) or T:ispointer() 
  }

  util.set_template_name(Array, options.typename or "Array", T)

  return Array
end

m.Array = terralib.memoize(function(T)
  return m._Array(T, {allow_growth = false, typename = "Array"})
end)

m.Vec = terralib.memoize(function(T)
  return m._Array(T, {allow_growth = true, typename = "Vec"})
end)

local lazy_items = {
  ByteArray = function() return m.Array(uint8) end,
  ByteSlice = function() return m.Slice(uint8) end,
}

m.exported_names = {
  "Vec", "Array", "Slice", "_Array", "_Slice", "ByteArray", "ByteSlice"
}

return lazy.lazy_table(m, lazy_items)