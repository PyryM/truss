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

uint64_t trussfs_recursive_makedir(trussfs_ctx* ctx, const char* path);

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

uint64_t trussfs_split_path(trussfs_ctx* ctx, const char* path);

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

local function assert_compatible_version(actual, target)
  if actual[1] ~= target[1] or actual[2] ~= target[2] or actual[3] < target[3] then
    error(
      "Incompatible trussfs version: got " .. 
      table.concat(actual, ".") ..
      " needed " ..
      table.concat(target, ".")
    )
  end
end

local fs_version = split_version(tonumber(fs_c.trussfs_version()))
assert_compatible_version(fs_version, {0, 0, 4})

local fs_ctx = fs_c.trussfs_init()
local fs = truss._declare_builtin("fs", {archives = {}, mounts = {}})

local function split_base_and_file(p)
  local base, file = p:match("^(.*[/\\])([^/\\]*)$")
  if not base then return "", file end
  return base, file
end
truss.splitpath = split_base_and_file

local PATHSEP
if jit.os == "Windows" then
  PATHSEP = "\\"
else
  PATHSEP = "/"
end

local function normpath(pathstr, os_paths)
  local in_sep, out_sep
  if os_paths then
    if jit.os == "Windows" then
      in_sep, out_sep = "[\\/]+", "\\"
    else
      in_sep, out_sep = "[/]+", "/"
    end
  else
    in_sep, out_sep = "[\\/]+", "/"
  end
  return (pathstr:gsub(in_sep, out_sep))
end
truss.normpath = normpath

local function joinpath(path, os_paths)
  local sep = (os_paths and PATHSEP) or "/"
  if type(path) == 'table' then
    path = table.concat(path, sep)
  end 
  return normpath(path, os_paths)
end

local function split_prefix(s, prefix)
  if s:sub(1, #prefix) ~= prefix then return nil end
  return s:sub(#prefix+1)
end

local function microclass(t)
  t = t or {}
  t.__index = t
  function t:new(...)
    ret = setmetatable({}, t)
    ret:init(...)
    return ret
  end
  return t
end

local RawMount = microclass()
function RawMount:init(srcpath)
  self.path = srcpath
end

function RawMount:realpath(subpath)
  return joinpath({self.path, subpath}, true)
end

function RawMount:read(subpath)
  local realpath = self:realpath(subpath)
  log.path("Reading from real path:", realpath)
  -- binary/text read mode distinction is critical on Windows where
  -- opening in text mode will truncate files with interior 0s
  local f = io.open(realpath, "rb")
  if not f then return nil end
  local data = f:read("*a")
  f:close()
  return data
end

local function _list_and_free(list)
  assert(fs_ctx, "No FS context!")
  local entries = {}
  local nentries = tonumber(fs_c.trussfs_list_length(fs_ctx, list))
  for idx = 1, nentries do
    entries[idx] = ffi.string(fs_c.trussfs_list_get(fs_ctx, list, idx-1))
  end
  fs_c.trussfs_list_free(fs_ctx, list)
  return entries
end

local function list_real_path(target, realroot, subpath, recursive)
  local realpath = joinpath({realroot, subpath}, true)
  log.path("Listing real path:", realpath)
  local list = fs_c.trussfs_list_dir(fs_ctx, realpath, false, true)
  for i, entry in ipairs(_list_and_free(list)) do
    local kind, symlink, filename = entry:match("^(%a) ([a-zA-Z_]):(.*)$")
    local is_file = kind == "F"
    table.insert(target, {
      is_file = is_file, 
      is_symlink = symlink == "S", 
      is_archived = false,
      path = joinpath({subpath, filename}, false),
      ospath = joinpath({realroot, subpath, filename}, true),
      base = subpath,
      file = filename,
    })
    if kind == "D" and recursive then
      list_real_path(target, realroot, joinpath{subpath, file_name}, recursive)
    end
  end
end

function RawMount:listdir(subpath, recursive, target)
  local details = target or {}
  list_real_path(details, self.path, subpath, recursive)
  return details
end

local ArchiveMount = microclass()
function ArchiveMount:init(srcpath)
  self.archive = srcpath
  fs._mount_archive(srcpath)
  self.files = {}
  for _, filedesc in ipairs(fs._list_archive(srcpath)) do
    local idx, size, kind, path = filedesc:match("^(%d+) (%d+) (%a+):(.*)$")
    idx = assert(tonumber(idx), "archive index is not a number!")
    size = assert(tonumber(size), "archive filesize is not a number!")
    if kind == "F" then
      self.files[path] = {idx = idx, size = size, path = path}
    end
  end
end

function ArchiveMount:read(subpath)
  local desc = self.files[normpath(subpath, false)]
  if not desc then return nil end
  return fs._read_archive_index(self.archive, desc.idx)
end

function ArchiveMount:listdir(subpath, recursive, target)
  target = target or {}
  for path, entry in pairs(self.files) do
    local base, file = split_base_and_file(path)
    local dirpath = split_prefix(base, subpath)
    if dirpath and (recursive or dirpath == "" or dirpath == "/") then
      table.insert(target, {
        is_file = true, 
        is_symlink = false, 
        is_archived = true,
        path = path,
        base = base,
        file = file,
        ospath = nil,
      })
    end
  end
  return target
end

function ArchiveMount:release()
  fs._release_archive(self.archive)
  self.files = nil
  self.archive = nil
end

function fs._mount(vpath, mount)
  vpath = normpath(vpath .. "/", false)
  if vpath == "/" or vpath == "./" then vpath = "" end
  table.insert(fs.mounts, {vpath, mount})
end

function fs.mount_path(vpath, realpath)
  log.info("Mounting path:", vpath, "->", realpath)
  fs._mount(vpath, RawMount:new(realpath))
end

function fs.mount_archive(vpath, archivefn)
  log.info("Mounting archive:", vpath, "->", archivefn)
  fs._mount(vpath, ArchiveMount:new(archivefn))
end

function fs.read_bare_archive(archivefn)
  return ArchiveMount:new(archivefn)
end

function fs.recursive_makedir(rawpath)
  fs_c.trussfs_recursive_makedir(fs_ctx, assert(rawpath))
end

function fs._match_path(path, f)
  -- exhaustively try all paths for now
  path = normpath(path, false)
  for _, vpath in ipairs(fs.mounts) do
    local prefix, mount = vpath[1], vpath[2]
    local subpath = split_prefix(path, prefix)
    if subpath then
      log.path("Matched [" .. path .. "] ->", prefix, "|", subpath)
      local res = f(mount, subpath)
      if res then return res end
    end
  end
  return nil
end

local function mount_read(mount, subpath)
  return mount:read(subpath)
end

function fs.read_file(fn)
  return fs._match_path(fn, mount_read)
end

function fs.listdir(dir, recursive)
  local details = {}
  local function mount_list(mount, subpath)
    mount:listdir(subpath, recursive, details)
  end
  fs._match_path(dir, mount_list)
  return details
end

function fs.read_file_buffer(fn)
  local str = fs.read_file(fn)
  if not str then return nil end
  return {data = terralib.cast(&uint8, str), str = str, size = #str}
end

function fs._get_scratch(size)
  if not fs._scratch or fs._scratch.size < size then
    local next_pow2 = math.ceil(2^math.ceil(math.log(size) / math.log(2)))
    fs._scratch = {
      data = terralib.new(uint8[next_pow2]),
      size = next_pow2
    }
  end
  return fs._scratch
end

function fs._read_archive_index(archive_fn, file_idx)
  if not fs.archives[archive_fn] then return nil end
  local handle = fs.archives[archive_fn]
  local fsize = tonumber(fs_c.trussfs_archive_filesize_index(fs_ctx, handle, file_idx))
  local scratch = fs._get_scratch(fsize)
  local outsize = fs_c.trussfs_archive_read_index(fs_ctx, handle, file_idx, scratch.data, scratch.size)
  if outsize <= 0 then return nil end
  return ffi.string(scratch.data, outsize)
end

function fs._mount_archive(fn)
  if not fs.archives[fn] then
    fs.archives[fn] = fs_c.trussfs_archive_mount(fs_ctx, fn)
  end
  return fs.archives[fn]
end

function fs._release_archive(handle)
  if type(handle) == 'string' then
    local fn = handle
    handle = fs.archives[fn]
    fs.archives[fn] = nil
  else
    for fn, _handle in pairs(fs.archives) do
      if handle == _handle then
        fs.archives[fn] = nil
      end
    end
  end
  if not handle then return end
  fs_c.trussfs_archive_free(fs_ctx, handle)
end

function fs._list_archive(handle)
  if type(handle) == 'string' then
    handle = fs.archives[handle]
  end
  if not handle then return nil end
  local list = fs_c.trussfs_archive_list(fs_ctx, handle)
  return _list_and_free(list)
end

truss.fs = fs
truss.working_dir = normpath(ffi.string(fs_c.trussfs_working_dir(fs_ctx)) .. PATHSEP, true)
truss.binary_path = ffi.string(fs_c.trussfs_binary_dir(fs_ctx))
truss.binary_dir, truss.binary_name = split_base_and_file(truss.binary_path)
truss.binary_dir = normpath(truss.binary_dir .. PATHSEP, true)

log.info("trussfs version:", table.concat(fs_version, "."))
log.info("Working dir:", truss.working_dir)
log.info("Binary dir:", truss.binary_dir)
log.info("Binary:", truss.binary_name)

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

local function _collectpath(...)
  local args = {...}
  if #args == 1 then
    return args[1]
  else
    return args
  end
end

function truss.joinvpath(...)
  return joinpath(_collectpath(...), false)  
end

function truss.joinpath(...)
  return joinpath(_collectpath(...), true)
end

function truss.read_file(path)
  return truss.fs.read_file(path)
end

function truss.read_file_buffer(path)
  return truss.fs.read_file_buffer(path)
end

function truss.list_dir(path, recursive)
  return truss.fs.listdir(path, recursive)
end

-- terra has issues with line numbering with dos line endings (\r\n), so
-- this function loads a string and then gets rid of carriage returns (\r)
function truss.read_script(path)
  local str = truss.read_file(path)
  if not str then return nil end
  return str:gsub("\r", "")
end
