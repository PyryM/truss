-- fileutils.t
--
-- various file io utilities

local m = {}

local function map_files(f, mount, dir_filter, file_filter)
  for _, entry in ipairs(mount:listdir("", false)) do
    if entry.is_file then -- non-archived file
      if file_filter == nil or (file_filter and file_filter(entry.file, entry.path)) then
        f(mount, entry)
      end
    elseif not entry.is_file then
      if dir_filter == nil or (dir_filter and dir_filter(entry.path)) then
        map_files(f, mount:mountdir(entry.path), dir_filter, file_filter)
      end
    end
  end
end
m.map_files = map_files

local function filter_file_prefixes(prefixes)
  return function(name)
    for _, prefix in ipairs(prefixes) do
      if name:find("^"..prefix) then 
        log.debug("ignoring: ", name)
        return false 
      end
    end
    return true
  end
end
m.filter_file_prefixes = filter_file_prefixes

local function iter_walk_files(mount, dir_filter, file_filter)
  if type(mount) == 'string' then
    mount = truss.fs.mount(mount)
  end
  return coroutine.wrap(function() 
    map_files(coroutine.yield, mount, dir_filter, file_filter)
  end)
end
m.iter_walk_files = iter_walk_files

function m.extract_archive(fn, dest)
  dest = dest or ""
  local made_dirs = {}
  local fs = truss.fs
  local arch = fs.mount_archive(fn)
  for path, f in pairs(arch.files) do
    local dir, fn = fs.splitbase(f.path)
    local destdir = fs.joinpath(truss.binary_dir, dest, dir)
    local destfilename = fs.joinpath(destdir, fn)
    if not made_dirs[destdir] then
      log.info("Creating directory:", destdir)
      fs.recursive_makedir(destdir)
      made_dirs[destdir] = true
    end
    log.info("Extracting:", path, "->", destfilename, ("(%d bytes)"):format(f.size))
    local data = arch:read(path)
    if data then
      local outfile = io.open(destfilename, "wb")
      outfile:write(data)
      outfile:close()
    end
  end
  arch:release()
end

return m
