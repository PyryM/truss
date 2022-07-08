-- native/cfile.t
--
-- wrapper around c std file functions

local ByteBuffer = require("./buffer.t").ByteBuffer
local SizedString = require("./commontypes.t").SizedString
local wrap_c_str = require("./commontypes.t").wrap_c_str

local m = {}

local c = require("./clib.t")

local function default_print(fmt, ...)
  fmt = fmt .. "/n" -- convention is that dbgprint is always on newline
  local args = {...} -- can't do this inline in quote below for reasons
  return quote 
    c.io.printf(fmt, [args])
  end
end

local function build_file(opts)
  opts = opts or {}
  local errformat = opts.error_format or "Error reading [%s]"
  local VERBOSE = opts.verbose
  local DBGPRINT = opts.DBGPRINT or default_print

  local size_t = c.io.size_t

  local struct CFile {
    file: &c.io.FILE;
    length: size_t;
  }

  terra CFile:init()
    self.file = nil
    self.length = 0
  end

  terra CFile:open(fn: &int8, write: bool): bool
    self.length = 0
    if write then
      self.file = c.io.fopen(fn, "wb")
    else
      self.file = c.io.fopen(fn, "rb")
    end
    if self.file == nil then 
      c.io.printf(errformat, fn)
      return false
    end
    if not write then
      c.io.fseek(self.file, 0, c.io.SEEK_END)
      self.length = c.io.ftell(self.file)
      c.io.fseek(self.file, 0, c.io.SEEK_SET)
    end
    return true
  end

  terra CFile:seek_end(): size_t
    if self.file == nil then return 0 end
    c.io.fseek(self.file, 0, c.io.SEEK_END)
    return c.io.ftell(self.file)
  end

  terra CFile:close()
    c.io.fclose(self.file)
    self.file = nil
  end

  terra CFile:read_raw(target: &uint8, targetsize: size_t, nread: size_t): size_t
    if self.file == nil then
      [DBGPRINT("Tried to read from nil file")]
      return 0
    end
    if nread > self.length then
      [DBGPRINT("Out of bounds read: %d > %d", nread, `self.length)]
      return 0 
    end
    if nread > targetsize then
      [DBGPRINT("Buffer too small: %d < %d", `targetsize, nread)]
      return 0
    end
    c.io.fread(target, 1, nread, self.file)
    return nread
  end

  terra CFile:read_into(target: &ByteBuffer, pos: size_t, len: size_t): bool
    if self.file == nil then
      [DBGPRINT("Tried to read from nil file")]
      return false
    end
    if pos + len > self.length then
      [DBGPRINT("Out of bounds read: %d + %d > %d", pos, len, `self.length)]
      return false 
    end
    if len > target.datasize then
      [DBGPRINT("Buffer too small: %d < %d", `target.datasize, len)]
      return false
    end
    c.io.fseek(self.file, pos, c.io.SEEK_SET)
    c.io.fread(target.data, 1, len, self.file)
    target.used_count = len
    return true
  end

  terra CFile:read_all(zero_pad: bool): ByteBuffer
    var buff: ByteBuffer = ByteBuffer{0, 0, 0, nil}
    if zero_pad then
      buff:allocate(self.length+1)
    else
      buff:allocate(self.length)
    end
    self:read_into(&buff, 0, self.length)
    buff.used_count = self.length
    if zero_pad then
      buff.data[self.length] = 0
    end
    return buff
  end

  terra CFile:seek(pos: size_t)
    if self.file == nil then return end
    c.io.fseek(self.file, pos, c.io.SEEK_SET)
  end

  terra CFile:write_append(data: &uint8, datasize: size_t)
    if self.file == nil then return end
    c.io.fseek(self.file, 0, c.io.SEEK_END)
    self.length = c.io.ftell(self.file)
    c.io.fwrite(data, 1, datasize, self.file)
    self.length = self.length + datasize
  end

  terra CFile:write(data: &uint8, datasize: size_t)
    if self.file == nil then return end
    c.io.fwrite(data, 1, datasize, self.file)
  end

  local terra open_file(fn: &int8): CFile
    var ret: CFile
    ret:open(fn, false)
    return ret
  end

  local terra read_file(fn: &int8, zero_term: bool): ByteBuffer
    var f = open_file(fn)
    var ret = f:read_all(zero_term)
    f:close()
    return ret
  end

  return {CFile = CFile, open_file = open_file, read_file = read_file}
end

local m = build_file()
m.build_file = build_file
return m