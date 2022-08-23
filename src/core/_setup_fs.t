-- sets up a minimal FS to allow reading of loose files

local ffi = require("ffi")

-- embed the header file so works w/o include dir
truss.link_library("lib", "trussfs")
local fs_c = terralib.includecstring[[
#include <stdint.h>
#include <stdbool.h>

typedef struct trussfs_ctx trussfs_ctx;

uint64_t trussfs_version();
trussfs_ctx* trussfs_init();
void trussfs_shutdown(trussfs_ctx* ctx);

const char* trussfs_working_dir(trussfs_ctx* ctx);
const char* trussfs_binary_dir(trussfs_ctx* ctx);

uint64_t trussfs_archive_mount(trussfs_ctx* ctx, const char* path);
void trussfs_archive_free(trussfs_ctx* ctx, uint64_t archive_handle);
uint64_t trussfs_archive_list(trussfs_ctx* ctx, uint64_t archive_handle);
uint64_t trussfs_archive_filesize_name(trussfs_ctx* ctx, uint64_t archive_handle, const char* name);
uint64_t trussfs_archive_filesize_index(trussfs_ctx* ctx, uint64_t archive_handle, uint64_t index);
int64_t trussfs_archive_read_name(trussfs_ctx* ctx, uint64_t archive_handle, const char* name, uint8_t* dest, uint64_t dest_size);
int64_t trussfs_archive_read_index(trussfs_ctx* ctx, uint64_t archive_handle, uint64_t index, uint8_t* dest, uint64_t dest_size);

uint64_t trussfs_list_dir(trussfs_ctx* ctx, const char* path, bool files_only, bool include_metadata);

void trussfs_list_free(trussfs_ctx* ctx, uint64_t list_handle);
uint64_t trussfs_list_length(trussfs_ctx* ctx, uint64_t list_handle);
const char* trussfs_list_get(trussfs_ctx* ctx, uint64_t list_handle, uint64_t index);
]]

local function split_version(v)
  local patch = v % 100
  local minor = math.floor(v / 100) % 100
  local major = math.floor(v / 10000)
  return {major, minor, patch}
end

local fs_version = split_version(tonumber(fs_c.trussfs_version()))
-- TODO: check version later here

local fs_ctx = fs_c.trussfs_init()
local fs = {archives = {}}

function fs:_list_and_free(list)
  assert(fs_ctx, "No FS context!")
  local entries = {}
  local nentries = tonumber(fs_c.trussfs_list_length(fs_ctx, list))
  for idx = 1, nentries do
    entries[idx] = ffi.string(fs_c.trussfs_list_get(fs_ctx, list, idx-1))
  end
  fs_c.trussfs_list_free(fs_ctx, list)
  return entries
end

function fs:list_dir(dirname, include_subdirs)
  assert(dirname, "No directory provided!")
  local list = fs_c.trussfs_list_dir(fs_ctx, dirname, not include_subdirs, false)
  return self:_list_and_free(list)
end

function fs:mount_archive(fn)
  if not self.archives[fn] then
    self.archives[fn] = fs_c.trussfs_archive_mount(fs_ctx, fn)
  end
  return self.archives[fn]
end

function fs:list_archive(fn)
  local handle = self:mount_archive(fn)
  local list = fs_c.trussfs_archive_list(fs_ctx, handle)
  return self:_list_and_free(list)
end

truss.fs = fs
truss.working_dir = ffi.string(fs_c.trussfs_working_dir(fs_ctx))
truss.binary_path = ffi.string(fs_c.trussfs_binary_dir(fs_ctx))

log.info("trussfs version:", table.concat(fs_version, "."))
log.info("Working dir:", truss.working_dir)
log.info("Binary:", truss.binary_path)

local function pathstr(path)
  if type(path) == 'table' then
    return table.concat(path, '/')
  end 
  return path
end

function truss.list_directory(path)
  return truss.fs:list_dir(pathstr(path))
end

function truss.file_extension(path)
  if type(path) == "table" then
    path = path[#path]
  end
  return path:match("^.*%.(.*)$")
end

function truss.is_file(path)
  return not not truss.file_extension(path)
end

function truss.is_dir(path)
  return not truss.file_extension(path)
end

function truss.joinpath(...)
  local args = {...}
  local path
  if #args == 1 then
    path = args[1]
  else
    path = args
  end
  if type(path) == 'table' then
    path = table.concat(path, "/")
  end
  -- Not sure if this replacement works!
  return path:gsub("//+", "/")
end

function truss.read_string(path)
  local rawpath = truss.joinpath(path)
  local f = assert(io.open(rawpath), "Couldn't open [" .. rawpath .. "]")
  local s = f:read("*a")
  f:close()
  return s
end

-- TODO: move this somewhere else
--[[
function truss.save(filename, data, datasize)
  local dtype = terralib.type(data)
  if dtype == "cdata" then
    local ttype = terralib.typeof(data)
    if ttype:isarray() then
      local dsize = terralib.sizeof(ttype) * ttype.N
      if not datasize then datasize = dsize end
      if datasize > dsize then
        truss.error("Provided datasize is too large! " .. datasize .. " > " .. dsize)
      end
    end
    truss.save_data(filename, terralib.cast(&int8, data), datasize)
  elseif dtype == "string" then
    truss.save_string(filename, data:sub(1, datasize))
  else
    error("Only CDATA and strings can be saved, got [" .. dtype .. "]")
  end
end
]]

-- terra has issues with line numbering with dos line endings (\r\n), so
-- this function loads a string and then gets rid of carriage returns (\r)
function truss.read_script(path)
  return truss.read_string(path):gsub("\r", "")
end

-- for debugging, get a specific line out of a script;
-- if the script doesn't exist, return nil instead of throwing
-- an error
function truss.get_script_line(path, linenumber)
  local source = truss.read_script(path)
  if not source then error("file does not exist:" .. pathstr(path)) end

  -- this is basically stringutils.split but we don't want to require
  -- extra modules in the middle of an error handler
  local pos = 1
  local line = nil
  local lineidx = 0
  while lineidx < linenumber do
    local first, last = string.find(source, "\n", pos)
    if first then -- found?
      line = source:sub(pos, first-1)
      pos = last+1
      lineidx = lineidx + 1
    else
      line = source:sub(pos)
      break
    end
  end
  return line
end
