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

  local struct CFile {
    file: &c.io.FILE;
    length: uint64;
  }

  terra CFile:open(fn: &int8): bool
    self.file = c.io.fopen(fn, "rb")
    if self.file == nil then 
      c.io.printf(errformat, fn)
      return false
    end
    c.io.fseek(self.file, 0, c.io.SEEK_END)
    self.length = c.io.ftell(self.file)
    c.io.fseek(self.file, 0, c.io.SEEK_SET)
    return true
  end

  terra CFile:close()
    c.io.fclose(self.file)
    self.file = nil
  end

  terra CFile:read_into(target: &ByteBuffer, pos: uint64, len: uint64): bool
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

  local terra open_file(fn: &int8): CFile
    var ret: CFile
    ret:open(fn)
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