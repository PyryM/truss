-- fileutils.t
--
-- various file io utilities

local m = {}

function m.map_files(f, path, dir_filter, file_filter)
  for _, entry in ipairs(truss.fs:list_dir_detailed(path)) do
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

return m
