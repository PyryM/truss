-- sets up a minimal FS to allow reading of loose files

local function pathstr(path)
  if type(path) == 'table' then
    return table.concat(path, '/')
  end 
  return path
end

function truss.list_directory(path)
  error("Minimal FS cannot list a directory! Build trussfs!")
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
