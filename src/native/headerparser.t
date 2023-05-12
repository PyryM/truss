-- native/headerparse.t
--
-- utilities for (poorly) parsing C headers

local sutil = require("util/string.t")

local m = {}

function m.strip_comments(s)
  return s:gsub("//[^\n]*", "")
end

function m.split_definitions(s)
  local defs = {}
  for _, line in ipairs(sutil.split(";", s)) do
    local stripped = sutil.strip(line)
    if #stripped > 0 then
      table.insert(defs, stripped)
    end
  end
  return defs
end

function m.parse_function_signature(s)
  local pre, post = s:match("([^(]*)%(([^)]*)%)")
  if not (pre and post) then return nil end
  pre, post = sutil.strip(pre), sutil.strip(post)
  local pre_parts = sutil.split("%s+", sutil.strip(pre))
  local funcname = pre_parts[#pre_parts]
  pre_parts[#pre_parts] = nil
  local rettype = table.concat(pre_parts, " ")
  local raw_args = sutil.split("%s*,%s*", post)
  local args = {}
  for idx, raw in ipairs(raw_args) do
    local parts = sutil.split("%s+", raw)
    local argname, argtype = "unknown", "unknown"
    if #parts == 1 then
      argname = "_arg" .. idx
      argtype = parts[1]
    elseif #parts >= 2 then
      argname = parts[#parts]
      parts[#parts] = nil
      argtype = table.concat(parts, " ")
    end
    args[idx] = {argname, argtype}
  end
  return {
    name = funcname,
    args = args,
    return_type = rettype
  }
end

function m.parse_header_string(s)
  s = m.strip_comments(s)
  local funcs = {}
  for _, sig in ipairs(m.split_definitions(s)) do
    local f = m.parse_function_signature(sig)
    if f and f.name then
      funcs[f.name] = f
    end
  end
  return funcs
end

function m.parse_header_file(fn)
  for _, path in ipairs(truss.config.include_paths) do
    local fn = truss.fs.joinpath(path, fn)
    local s = truss.fs.read(fn)
    if s then
      return m.parse_header_string(s)
    end
  end
  error("Couldn't locate header: '" .. fn .. "'")
end

return m