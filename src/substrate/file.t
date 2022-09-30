-- substrate/file.t
--
-- wrapper around c std file functions

local m = {}
local lazy = require("./lazyload.t")
local util = require("./util.t")

local _built = nil

function m._build(options)
  if _built then return _built end

  options = options or {}
  local cfg = options.cfg or require("./cfg.t").configure()
  local size_t = assert(cfg.size_t, "No size_t!")
  local libc = require("./libc.t")
  local derive = require("./derive.t")
  local ByteBuffer = require("./array.t").ByteBuffer
  local ByteSlice = require("./array.t").ByteSlice
  local ASSERT = cfg.ASSERT
  local LOG = cfg.LOG

  local struct File {
    file: &libc.io.FILE;
    size: size_t;
  }
  derive.derive_init(File)

  terra File:close()
    c.io.fclose(self.file)
    self.file = nil
    self.size = 0
  end

  terra File:release()
    self:close()
  end

  terra File:open(fn: &int8, write: bool): bool
    [ASSERT(`self.file == nil and self.size == 0, "File already open!")]
    if write then
      self.file = c.io.fopen(fn, "wb")
    else
      self.file = c.io.fopen(fn, "rb")
    end
    if self.file == nil then 
      [LOG("Error reading [%s]", fn)]
      return false
    end
    if not write then
      c.io.fseek(self.file, 0, c.io.SEEK_END)
      self.size = c.io.ftell(self.file)
      c.io.fseek(self.file, 0, c.io.SEEK_SET)
    end
    return true
  end

  terra File:seek_end(): size_t
    if self.file == nil then return 0 end
    c.io.fseek(self.file, 0, c.io.SEEK_END)
    return c.io.ftell(self.file)
  end

  terra File:read_raw(target: &uint8, targetsize: size_t, nread: size_t): size_t
    if self.file == nil then
      [LOG("Tried to read from nil file")]
      return 0
    end
    if nread > self.size then
      [LOG("Out of bounds read: %d > %d", nread, `self.size)]
      return 0 
    end
    if nread > targetsize then
      [LOG("Buffer too small: %d < %d", `targetsize, nread)]
      return 0
    end
    c.io.fread(target, 1, nread, self.file)
    return nread
  end

  terra File:read_into(target: &ByteBuffer, pos: size_t, len: size_t): bool
    if self.file == nil then
      [LOG("Tried to read from nil file")]
      return false
    end
    if pos + len > self.size then
      [LOG("Out of bounds read: %d + %d > %d", pos, len, `self.size)]
      return false 
    end
    if len > target.capacity then
      [LOG("Buffer too small: %d < %d", `target.datasize, len)]
      return false
    end
    c.io.fseek(self.file, pos, c.io.SEEK_SET)
    c.io.fread(target.data, 1, len, self.file)
    target.size = len
    return true
  end

  terra File:read_all_into(target: &ByteBuffer, zero_terminate: bool)
    if zero_terminate then
      target:allocate(self.size+1)
    else
      target:allocate(self.size)
    end
    self:read_into(target, 0, self.size)
    if zero_terminate then
      target.data[self.size] = 0
    end
  end

  terra File:seek(pos: size_t)
    [ASSERT(`self.file ~= nil, "File is not open!")]
    c.io.fseek(self.file, pos, c.io.SEEK_SET)
  end

  terra File:write_append(data: &uint8, datasize: size_t)
    [ASSERT(`self.file ~= nil, "File is not open!")]
    c.io.fseek(self.file, 0, c.io.SEEK_END)
    self.size = c.io.ftell(self.file)
    c.io.fwrite(data, 1, datasize, self.file)
    self.size = self.size + datasize
  end

  terra File:write(data: &uint8, datasize: size_t)
    [ASSERT(`self.file ~= nil, "File is not open!")]
    c.io.fwrite(data, 1, datasize, self.file)
  end

  terra File:write_slice(data: ByteSlice)
    self:write(data.data, data.size)
  end

  _built = {File = File}
  return _built
end

local lazy_items = {
  File = function() return m._build().File end,
}
  
m.exported_names = {
  "File",
}

return lazy.lazy_table(m, lazy_items)