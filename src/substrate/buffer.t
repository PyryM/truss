local c = require("./clib.t")
local SizedString = require("./commontypes.t").SizedString

-- assume that LLVMs optimizations of a memcopy will outpeform
-- calling into the C standard library
local terra memcopy(dest: &uint8, src: &uint8, dsize: uint32)
  for i = 0, dsize do
    dest[i] = src[i]
  end
end

local Buffer = terralib.memoize(function(T)
  local struct _Buffer {
    count: uint32;
    used_count: uint32;
    datasize: uint64;
    data: &T;
  }

  terra _Buffer:as_bytes(): &uint8
    return [&uint8](self.data)
  end

  terra _Buffer:init()
    self.data = nil
    self.datasize = 0
    self.count = 0
    self.used_count = 0
  end

  terra _Buffer:slice_view(startpos: uint32, count: uint32): _Buffer
    if startpos + count > self.count then
      return _Buffer{0, 0, 0, nil}
    else
      return _Buffer{
        count, count, count*sizeof(T),
        self.data + startpos,
      }
    end
  end

  terra _Buffer:swap_data(rhs: &_Buffer)
    if rhs.datasize ~= self.datasize then return end
    if rhs.count ~= self.count then return end
    var temp_data: &T = self.data
    self.data = rhs.data
    rhs.data = temp_data
  end

  terra _Buffer:allocate(n: uint32)
    self:release()
    self.datasize = n * sizeof(T)
    self.count = n
    self.used_count = 0
    self.data = [&T](c.std.malloc(self.datasize))
    --c.io.printf("Allocation: %d -> %p\n", self.datasize, self.data)
  end

  terra _Buffer:copy_noalloc(data: &T, count: uint32)
    var copycount = count
    if copycount > self.count then
      copycount = self.count
    end
    -- TODO: memcopy this?
    for idx = 0, copycount do
      self.data[idx] = data[idx]
    end
    self.used_count = copycount
  end

  terra _Buffer:copy(data: &T, count: uint32)
    self:allocate(count)
    memcopy([&uint8](self.data), [&uint8](data), self.datasize)
    self.used_count = count
  end

  terra _Buffer:put(data: &T, count: uint32, offset: uint32)
    if offset + count > self.count then return end
    for idx = 0, count do
      self.data[idx+offset] = data[idx]
    end
  end

  terra _Buffer:fill(val: T)
    for i = 0, self.count do
      self.data[i] = val
    end
    self.used_count = self.count
  end

  terra _Buffer:clear()
    self.used_count = 0
  end

  terra _Buffer:poplar(): T
    self.used_count = self.used_count - 1
    if self.used_count < 0 then
      self.used_count = 0 -- HACK
    end
    return self.data[self.used_count]
  end

  terra _Buffer:push_new(): &T
    if self.used_count >= self.count then 
      return nil
    end
    var ret: &T = &(self.data[self.used_count])
    self.used_count = self.used_count + 1
    return ret
  end

  terra _Buffer:push_single(val: T): bool
    if self.used_count >= self.count then 
      return false 
    end
    self.data[self.used_count] = val
    self.used_count = self.used_count + 1
    return true
  end

  terra _Buffer:push(data: &T, count: uint32): bool
    if self.used_count + count > self.count then
      return false
    end
    memcopy([&uint8](self.data + self.used_count), 
            [&uint8](data), 
            count*sizeof(T))
    self.used_count = self.used_count + count
    return true
  end

  terra _Buffer:release()
    if self.data ~= nil then
      c.std.free(self.data)
    end
    self:init()
  end

  terra _Buffer:bgfx_copy(): &bgfx.memory_t
    return bgfx.copy(self.data, self.datasize)
  end

  terra _Buffer:bgfx_ref(): &bgfx.memory_t
    return bgfx.make_ref(self.data, self.datasize)
  end

  terra _Buffer:as_sized_string(): SizedString
    return SizedString{[&int8](self.data), self.used_count*sizeof(T)}
  end

  return _Buffer
end)

return {Buffer = Buffer, ByteBuffer = Buffer(uint8)}