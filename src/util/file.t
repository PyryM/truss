-- fileutils.t
--
-- various file io utilities

local m = {}

function m.map_files(f, path, dir_filter, file_filter)
  for _, entry in ipairs(truss.list_dir(path)) do
    if entry.is_file then
      if file_filter == nil or (file_filter and file_filter(entry)) then
        f(entry)
      end
    elseif not entry.is_symlink then
      if dir_filter == nil or (dir_filter and dir_filter(entry)) then
        m.map_files(f, entry.path, dir_filter, file_filter)
      end
    end
  end
end

function m.filter_file_prefix(prefix)
  return function(entry)
    return entry.file and entry.file:sub(1, #prefix) == prefix
  end
end

function m.iter_walk_files(path, dir_filter, file_filter)
  local co = coroutine.create(function() 
    m.map_files(coroutine.yield, path, dir_filter, file_filter)
  end)
  return function()
    local happy, path = coroutine.resume(co)
    assert(happy, path)
    return path
  end
end

function m.extract_archive(fn, dest)
  dest = dest or ""
  local made_dirs = {}
  local fs = require("fs")
  local arch = fs.read_bare_archive(fn)
  for path, f in pairs(arch.files) do
    local dir, fn = truss.splitpath(f.path)
    local destdir = truss.joinpath(truss.binary_dir, dest, dir)
    local destfilename = truss.joinpath(destdir, fn)
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
