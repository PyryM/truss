-- objloader.t
--
-- loads wavefront .obj files

local m = {}

function m.loadOBJ(filename, invert)
	local starttime = tic()
	local srcMessage = trss.trss_load_file(filename, 0)
	local srcstr = ffi.string(srcMessage.data, srcMessage.data_length)
	local ret = m.parseOBJ(srcstr, invert)
	trss.trss_release_message(srcMessage)
	local dtime = toc(starttime)
	trss.trss_log(0, "Loaded " .. filename .. " in " .. (dtime*1000.0) .. " ms")
	return ret
end

-- implementation details

-- Split text into a list consisting of the strings in text,
-- separated by strings matching delimiter (which may be a pattern). 
-- example: strsplit(",%s*", "Anna, Bob, Charlie,Dolores")
-- (from http://lua-users.org/wiki/SplitJoin)
local strfind = string.find
local tinsert = table.insert
local strsub = string.sub
local function strsplit(delimiter, text)
  local list = {}
  local pos = 1
  if strfind("", delimiter, 1) then -- this would result in endless loops
    error("delimiter matches empty string!")
  end
  while 1 do
    local first, last = strfind(text, delimiter, pos)
    if first then -- found?
      tinsert(list, strsub(text, pos, first-1))
      pos = last+1
    else
      tinsert(list, strsub(text, pos))
      break
    end
  end
  return list
end

local function isComment(linegps)
	local firstChar = strsub(linegps[1], 1, 1)
	return firstChar == "#"
end

function m.parseOBJ(objstring, invert)
	-- todo
end