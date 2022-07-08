-- util/argparse.t
--
-- does some basic argument parsing

local m = {}

local function is_flag(s)
  return s:sub(1, 1) == "-"
end

local function find_non_flags(args, startpos)
  local vals = {}
  local pos = startpos
  while (pos <= #args) and (not is_flag(args[pos])) do
    vals[#vals + 1] = args[pos]
    pos = pos + 1
  end
  if #vals == 0 then 
    vals = true
  elseif #vals == 1 then
    vals = vals[1]
  end
  return pos, vals
end

function m.parse(args, startpos)
  args = args or truss.args
  local ret = {}
  local pos = startpos or 1
  while pos <= #args do
    local curarg = args[pos]
    if is_flag(curarg) then
      pos, ret[curarg] = find_non_flags(args, pos+1)
    else
      pos = pos + 1
    end
  end
  return ret
end

return m