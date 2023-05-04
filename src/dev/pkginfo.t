local sutil = require("util/string.t")

local function simplify_path(path)
  if sutil.begins_with(path, truss.working_dir) then
    return truss.fs.joinpath("$WORKDIR", path:sub(#truss.working_dir))
  elseif sutil.begins_with(path, truss.binary_dir) then
    return truss.fs.joinpath("$BINDIR", path:sub(#truss.binary_dir))
  else
    return path
  end
end

local function print_info()
  print("=========== Packages ==========")
  local pnames = {}
  for name, _ in pairs(truss.packages) do
    table.insert(pnames, name)
  end
  table.sort(pnames)
  local term = truss.term
  local UNLOADED = term.color(term.WHITE)
  local LOADED = term.color(term.CYAN)
  local RESET = term.RESET
  for _, name in ipairs(pnames) do
    local pkg = truss.packages[name]
    local body = pkg.body
    local path = simplify_path(pkg.source_desc or pkg.source_path or "unknown")
    if body then
      print(LOADED .. name .. RESET .. ": " .. path)
    else
      print(UNLOADED .. name .. RESET .. ": " .. path)
    end
  end
end

return {init = print_info, print_info = print_info}