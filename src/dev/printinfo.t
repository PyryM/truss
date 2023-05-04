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
    local path = pkg.source_desc or pkg.source_path or "unknown"
    if body then
      print(LOADED .. name .. RESET .. ": " .. path)
    else
      print(UNLOADED .. name .. RESET .. ": " .. path)
    end
  end
end

return {init = print_info}