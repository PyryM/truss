local function pathstr(path)
  if type(path) == 'table' then
    return table.concat(path, '/')
  end 
  return path
end

function truss.list_directory(path)
  TODO()
end

function truss.extract_from_archive(src_path, dest_path)
  TODO()
end

function truss.is_file(path)
  TODO()
end

function truss.is_dir(path)
  TODO()
end

function truss.read_string(path)
  TODO()
end

function truss.joinpath(...)
  -- Not sure if this replacement works!
  return table.concat({...}, "/").gsub("//+", "/")
end

-- returns true if the file exists and is inside an archive
function truss.is_archived(path)
  TODO()
  local rawpath = truss.get_file_real_path(path)
  if not rawpath then return false end
  local pathstr = ffi.string(rawpath)
  local ext = string.sub(pathstr, -4)
  return ext == ".zip" 
end

function truss.save_data(filename, data, datalen)
  TODO()
end

function truss.save_string(filename, s)
  TODO()
end

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

-- terra has issues with line numbering with dos line endings (\r\n), so
-- this function loads a string and then gets rid of carriage returns (\r)
function truss.read_script(path)
  local s = truss.read_string(path)
  if s then return s:gsub("\r", "") else return nil end
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

-- terralib.loadstring does not take a name parameter (which is needed
-- to get reasonable error messages), so we have to perform this workaround
-- to use the lower-level terralib.load which does take a name
function truss.load_named_string(str, strname, loader)
  -- create a function which returns str on the first call
  -- and nil on the second (to let terralib.load know it is done)
  local s = str
  local generator_func = function()
    local s2 = s
    s = nil
    return s2
  end
  loader = loader or terralib.load
  return loader(generator_func, '@' .. strname)
end
