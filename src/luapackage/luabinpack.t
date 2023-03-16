-- build/luabinpack.t
--
-- packs together lua scripts + interpreter into a single binary

local m = {}
local lua = require("./lua.t")

-- TODO: move this into its own module?
local function map_files(f, path, dir_filter, file_filter)
  for _, entry in ipairs(truss.list_dir(path, false)) do
    if entry.is_file then -- non-archived file
      if file_filter == nil or (file_filter and file_filter(entry.file, entry.path)) then
        f(entry.path)
      end
    elseif not entry.is_file then
      if dir_filter == nil or (dir_filter and dir_filter(entry.path)) then
        map_files(f, entry.path, dir_filter, file_filter)
      end
    end
  end
end

local function filter_file_prefixes(prefixes)
  return function(name)
    for _, prefix in ipairs(prefixes) do
      if name:find("^"..prefix) then 
        log.debug("ignoring: ", name)
        return false 
      end
    end
    return true
  end
end

local function iter_walk_files(path, dir_filter, file_filter)
  return coroutine.wrap(function() 
    map_files(coroutine.yield, path, dir_filter, file_filter)
  end)
end

local function embed_files(L, table_name, files)
  local count, keys, vals = lua.create_const_dict(files)
  log.crit("Embed count:", count)
  return quote
    L:set_global_dict_of_strings(table_name, count, keys, vals)
  end
end

local function link_trussfs(L)
  if jit.os == "Windows" then 
    return quote end
  end
  local trussfs_c = terralib.includecstring[[
  #include <stdint.h>
  uint64_t trussfs_version();
  ]]
  return quote
    var vnum = trussfs_c.trussfs_version()
    terra_c.lua_pushnumber(L, vnum)
    terra_c.lua_setfield(L, LUA_GLOBALSINDEX, "_LINKED_TRUSSFS_VERSION")
  end
end

local LUA_BOOT = [[
local _load = loadstring or load

local function embedded_loader(modname)
  local fdata = assert(
    _EMBEDDED_FILES[modname], 
    "Missing embedded file: " .. modname
  )
  local modfunc = assert(_load(fdata, modname))
  return modfunc()
end

for modname, _ in pairs(_EMBEDDED_FILES) do
  print("PRELOAD:", modname)
  package.preload[modname] = embedded_loader
end

if _MAIN and #_MAIN > 0 then
  local main = require(_MAIN)
  main:run()
end
]]

function m.generate_main(options)
  local LuaState = lua.build(options).LuaState
  local files = assert(options.embedded_files, "No embedded files provided!")
  local lua_main = options.main or "main"

  local terra main(argc: int, argv: &&int8): int
    var L: LuaState
    L:init()

    [embed_files(L, "_EMBEDDED_FILES", files)]
    [link_trussfs(L)]

    L:set_global_cstring("_MAIN", lua_main)
    L:set_global_array_of_strings("_CMDARGS", argc, argv)
    L:set_global_double("_RETURN_CODE", 0.0)

    if not L:do_cstring(LUA_BOOT) then
      return 1
    end

    return [int](L:get_global_double("_RETURN_CODE"))
  end

  return main
end

local function split_path(path)
  local p0, p1, filepart = path:find("/([^/]*)$")
  if not p0 then return "", path end
  return path:sub(1, p0), filepart
end

local function module_name(path, filepart)
  path = path .. filepart
  log.info(path)
  path = path:gsub("%.lua$", ""):gsub("/", ".")
  return path
end

local function gather_files(rootdir)
  local files = {}
  for fullpath in iter_walk_files(rootdir) do
    local path, filepart = split_path(fullpath)
    if filepart:match("%.lua$") then
      path = path:gsub("^" .. rootdir .. "/?", "")
      if path == "/" then path = "" end
      local modname = module_name(path, filepart)
      local modsrc = truss.read_file(fullpath)
      files[modname] = modsrc
      log.info("Adding", modname, ":", #modsrc, "bytes")
    end
  end
  return files
end

local LUA_LIBS = {
  ["jit"] = {"lua51", "luajit"},
  ["5.4"] = {"lua5.4-static", "lua"},
  ["5.4+lpeg"] = {"lua5.4-static", "lua"},
}

function m.export_binary(options)
  local embedded_files = gather_files(assert(options.root_dir, "No root_dir!"))
  local lua_version = options.lua_version or "jit"
  local libinfo = assert(LUA_LIBS[lua_version], "Invalid lua version: " .. lua_version)
  local lua_win_lib, lua_posix_lib = unpack(libinfo)

  local main = m.generate_main{
    embedded_files = embedded_files,
    lua_version = options.lua_version or "jit",
    main = options.main
  }

  require("./binexport.t").export_binary{
    name = assert(options.name, ".name required!"),
    libpath = options.libpath or "lib",
    libs = {
      all = {},
      Windows = {lua_win_lib},
      Linux = {lua_posix_lib, "trussfs"},
      OSX = {lua_posix_lib, "trussfs"},
    },
    syslibs = {
      Windows = {"user32"}
    },
    platform = {
      Linux = {rpath = "lib/"},
      OSX = {rpath = "lib/"}
    },
    symbols = {main = main}
  }
end

return m