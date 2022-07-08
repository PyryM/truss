-- fileutils.t
--
-- various file io utilities

local m = {}

function m.map_files(f, path, dir_filter, file_filter)
  for _, name in ipairs(truss.list_directory(path)) do
    local subpath = truss.extend_table({}, path)
    table.insert(subpath, name)
    if truss.is_file(subpath) then
      if file_filter == nil or (file_filter and file_filter(subpath)) then
        f(subpath)
      end
    elseif truss.is_directory(subpath) then
      if dir_filter == nil or (dir_filter and dir_filter(subpath)) then
        m.map_files(f, subpath, dir_filter, file_filter)
      end
    end
  end
end

function m.filter_file_prefix(prefix)
  return function(path)
    local fn = path[#path]
    return fn and fn:sub(1, #prefix) == prefix
  end
end

function m.iter_walk_files(path, dir_filter, file_filter)
  local co = coroutine.create(function() 
    m.map_files(coroutine.yield, path, dir_filter, file_filter)
  end)
  return function()
    local code, path = coroutine.resume(co)
    return path
  end
end

return m
