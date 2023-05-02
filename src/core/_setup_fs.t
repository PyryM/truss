-- sets up a minimal FS to allow reading of loose files

local TRUSS_FS_HEADER = [[
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

local function install(core)
  local ffi = core.ffi
  local log = core.log

  -- link trussfs through luajit ffi instead of terra to 
  -- put off dealing with header inlclude paths until later
  ffi.cdef(TRUSS_FS_HEADER)
  local fs_c
  do
    local prefix, ext
    if core.GLOBALS._LINKED_TRUSSFS_VERSION then
      -- trussfs is already linked in so we should be able to dlopen
      -- the bare library name and have it used the linked one
      prefix, ext = "", ""
    elseif jit.os == 'Windows' then
      prefix, ext = "lib/", ".dll"
    elseif jit.os == 'OSX' or jit.os == 'Darwin' then
      prefix, ext = "lib/lib", ".dylib"
    else
      -- assume linux-ish
      prefix, ext = "lib/lib", ".so"
    end
    fs_c = ffi.load(prefix .. "trussfs" .. ext)
  end
  local INVALID_HANDLE = 0xFFFFFFFFFFFFFFFFull;

  local fs_version = core.parse_version_int(tonumber(fs_c.trussfs_version()))
  core.assert_compatible_version("trussfs", fs_version, {maj=0, min=1, pat=1})

  local fs_ctx = fs_c.trussfs_init()
  local fs = core._declare_builtin("fs", {archives = {}, version=fs_version})

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

  function fs.list_real_path(target, realroot, subpath, recursive)
    local realpath = realroot
    if #subpath > 0 then
      realpath = fs.joinpath({realroot, subpath}, true)
    end
    log.path("Listing real path:", realpath)
    local list = fs_c.trussfs_list_dir(fs_ctx, realpath, false, true)
    if list == INVALID_HANDLE then return end
    for i, entry in ipairs(_list_and_free(list)) do
      local kind, symlink, filename = entry:match("^(%a) ([a-zA-Z_]):(.*)$")
      local is_file = kind == "F"
      table.insert(target, {
        is_file = is_file, 
        is_symlink = symlink == "S", 
        is_archived = false,
        mountroot = realroot,
        path = fs.joinpath({subpath, filename}, false),
        ospath = fs.joinpath({realroot, subpath, filename}, true),
        base = subpath,
        file = filename,
      })
      if kind == "D" and recursive then
        fs.list_real_path(target, realroot, fs.joinpath{subpath, file_name}, recursive)
      end
    end
  end

  function fs.splitpath(path)
    local parts = {}
    for part in path:gmatch("[^/\\]+") do
      table.insert(parts, part)
    end
    return parts
  end

  function fs.splitbase(p)
    local base, file = p:match("^(.*[/\\])([^/\\]*)$")
    if not base then return "", file end
    return base, file
  end

  -- TODO: lua actually knows this
  if jit.os == "Windows" then
    fs.PATHSEP = "\\"
  else
    fs.PATHSEP = "/"
  end

  function fs.normpath(pathstr, os_paths)
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

  function fs._filterpath(parts)
    local ret = {}
    for idx = 1, #parts do
      local part = parts[idx]
      if part ~= "" then
        ret[#ret + 1] = part
      end
    end
    return ret
  end

  function fs.joinpath(...)
    local path = {...}
    if type(path[1]) == 'table' then
      path = path[1]
    end
    path = fs._filterpath(path)
    path = table.concat(path, fs.PATHSEP)
    return fs.normpath(path, true)
  end

  function fs.split_prefix(s, prefix)
    if s:sub(1, #prefix) ~= prefix then return nil end
    return s:sub(#prefix+1)
  end

  local RawMount = core.nanoclass()
  function RawMount:init(srcpath)
    self.path = srcpath
  end

  function RawMount:realpath(subpath)
    return fs.joinpath({self.path, subpath}, true)
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

  function RawMount:listdir(subpath, recursive)
    subpath = subpath or ""
    local details = {}
    fs.list_real_path(details, self.path, subpath, recursive)
    return details
  end

  function RawMount:mountdir(subpath)
    return RawMount:new(self:realpath(subpath))
  end

  function RawMount:isdir(subpath)
    -- TODO: better way of implementing this?
    return not fs.file_extension(subpath)
  end

  local ArchiveRootMount = core.nanoclass()
  local ArchiveDirMount = core.nanoclass()

  function ArchiveRootMount:init(srcpath)
    self.archive = srcpath
    fs._mount_archive(srcpath)
    self.files = {}
    self.dirs = {}
    for _, filedesc in ipairs(fs._list_archive(srcpath)) do
      local idx, size, kind, path = filedesc:match("^(%d+) (%d+) (%a+):(.*)$")
      idx = assert(tonumber(idx), "archive index is not a number!")
      size = assert(tonumber(size), "archive filesize is not a number!")
      if kind == "F" then
        self.files[path] = {idx = idx, size = size, path = path}
      elseif kind == "D" then
        self.dirs[path] = {idx = idx, size = size, path = path}
      end
    end
  end

  function ArchiveRootMount:read(subpath)
    local desc = self.files[normpath(subpath, false)]
    if not desc then return nil end
    return fs._read_archive_index(self.archive, desc.idx)
  end

  function ArchiveRootMount:listdir(subpath, recursive)
    local target = {}
    for path, entry in pairs(self.files) do
      local base, file = fs.splitbase(path)
      local dirpath = fs.splitbase(base, subpath) -- ???
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

  function ArchiveRootMount:mountdir(path)
    return ArchiveDirMount:new(self, path)
  end

  function ArchiveRootMount:release()
    fs._release_archive(self.archive)
    self.files = nil
    self.archive = nil
  end

  function ArchiveDirMount:init(parent, dir)
    self.parent = parent
    self.dir = dir
  end

  function ArchiveDirMount:read(path)
    return self.parent:read(fs.joinpath(self.dir, path))
  end

  function ArchiveDirMount:listdir(path, recursive)
    return self.parent:listdir(fs.joinpath(self.dir, path), recursive)
  end

  function ArchiveDirMount:mountdir(path)
    return ArchiveDirMount:new(self.parent, fs.joinpath(self.dir, path))
  end

  function fs.mount_path(path)
    return RawMount:new(path)
  end

  function fs.mount_archive(archive_path)
    if not fs.archives[archive_path] then
      fs.archives[archive_path] = ArchiveRootMount:new(archive_path)
    end
    return fs.archives[archive_path]
  end

  local ARCHIVE_EXTENSIONS = {
    zip = true,
  }

  function fs.mount(path)
    local ext = fs.file_extension(path)
    if ARCHIVE_EXTENSIONS[ext] then
      return fs.mount_archive(path)
    else
      return fs.mount_path(path)
    end
  end

  -- TODO: release archives?

  function fs.recursive_makedir(rawpath)
    fs_c.trussfs_recursive_makedir(fs_ctx, assert(rawpath))
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

  core.fs = fs
  core.working_dir = fs.normpath(ffi.string(fs_c.trussfs_working_dir(fs_ctx)) .. fs.PATHSEP, true)
  core.binary_path = ffi.string(fs_c.trussfs_binary_dir(fs_ctx))
  core.binary_dir, core.binary_name = fs.splitbase(core.binary_path)
  core.binary_dir = fs.normpath(core.binary_dir .. fs.PATHSEP, true)
  core.root_dir = core.binary_dir

  log.info("trussfs version:", table.concat(fs_version, "."))
  log.info("Working dir:", core.working_dir)
  log.info("Binary dir:", core.binary_dir)
  log.info("Binary:", core.binary_name)

  function fs.file_extension(path)
    if type(path) == "table" then
      path = path[#path]
    end
    return path:match("^.*%.([^/\\]*)$")
  end

  function fs.isfile(path)
    return not not fs.file_extension(path)
  end

  function fs.isdir(path)
    return not fs.file_extension(path)
  end

  function fs.resolve_relative_path(curdir, path)
    if path:sub(1,1) ~= "." then 
      -- relative path must start with . or ..
      return path 
    end
    local pathstack = fs.splitpath(curdir)
    for _, part in ipairs(fs.splitpath(path)) do
      if part == "." or part == "" then
        -- stay in current directory (do nothing)
      elseif part == ".." then
        pathstack[#pathstack] = nil
      else
        pathstack[#pathstack + 1] = part
      end
    end
    return pathstack
  end  

  -- terra has issues with line numbering with dos line endings (\r\n), so
  -- this function loads a string and then gets rid of carriage returns (\r)
  function core.read_script(path)
    local str = core.read_file(path)
    if not str then return nil end
    return str:gsub("\r", "")
  end
end

return {install = install}
