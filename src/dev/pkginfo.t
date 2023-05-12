local sutil = require("util/string.t")

local pkginfo = {}

function pkginfo.simplify_pkg_path(path)
  if sutil.begins_with(path, truss.working_dir) then
    return truss.fs.joinpath("$WORKDIR", path:sub(#truss.working_dir))
  elseif sutil.begins_with(path, truss.binary_dir) then
    return truss.fs.joinpath("$BINDIR", path:sub(#truss.binary_dir))
  else
    return path
  end
end

function pkginfo.list_packages()
  local pnames = {}
  for name, _ in pairs(truss.packages) do
    table.insert(pnames, name)
  end
  table.sort(pnames)
  local listing = {}
  for _, name in ipairs(pnames) do
    local pkg = truss.packages[name]
    local path = pkg.source_desc or pkg.source_path or "unknown"
    table.insert(listing, {
      name = name,
      pkg = pkg,
      path = path,
      is_loaded = pkg.body ~= nil,
      short_path = pkginfo.simplify_pkg_path(path)
    })
  end
  return listing
end

function pkginfo.print_info()
  print("=========== Packages ==========")
  local term = truss.term
  local UNLOADED = term.color(term.WHITE)
  local LOADED = term.color(term.CYAN)
  local RESET = term.RESET
  for _, info in ipairs(pkginfo.list_packages()) do
    if info.is_loaded then
      print(LOADED .. info.name .. RESET .. ": " .. info.short_path)
    else
      print(UNLOADED .. info.name .. RESET .. ": " .. info.short_path)
    end
  end
end
pkginfo.init = pkginfo.print_info

return pkginfo