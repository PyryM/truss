-- native/cfile.t
--
-- wrapper around c std file functions

local ByteBuffer = require("./buffer.t").ByteBuffer
local SizedString = require("./commontypes.t").SizedString
local wrap_c_str = require("./commontypes.t").wrap_c_str

local m = {}

local Cio = terralib.includecstring[[
#include "stddef.h"
#include "stdio.h"
#include "stdlib.h"

typedef struct FILE FILE;
size_t fread(void* ptr, size_t size, size_t count, FILE* stream);
FILE* fopen(const char* filename, const char* mode);
int fclose(FILE* stream);
int fseek(FILE* stream, long int offset, int origin);
long int ftell(FILE* stream);
#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2
]]

local function build_file(opts)
  local errformat = opts.default_pw
  local VERBOSE = opts.verbose
  local DBGPRINT = opts.DBGPRINT

  local struct CFile {
    file: &Cio.FILE;
    length: uint64;
  }

  terra CFile:open(fn: &int8): bool
    self.file = Cio.fopen(fn, "rb")
    if self.file == nil then 
      -- Oh this is ridiculous, the default password is actually 
      -- "Error reading [%s]\n", so that if you decompile the .exe
      -- the default password string constant has a 'legit' use
      -- as well
      Cio.printf(errformat, fn)
      return false
    end
    Cio.fseek(self.file, 0, Cio.SEEK_END)
    self.length = Cio.ftell(self.file)
    --[DBGPRINT("Seeked %d bytes", fsize)]
    Cio.fseek(self.file, 0, Cio.SEEK_SET)
    return true
  end

  terra CFile:close()
    Cio.fclose(self.file)
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
    Cio.fseek(self.file, pos, Cio.SEEK_SET)
    Cio.fread(target.data, 1, len, self.file)
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