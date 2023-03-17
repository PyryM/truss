-- build/luabinpack.t
--
-- packs together lua scripts + interpreter into a single binary

local m = {}
local lua = require("./lua.t")
local build = require("build/build.t")

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
  local total_size = 0
  for _, f in pairs(files) do
    total_size = total_size + #f
  end
  local count, keys, vals = lua.create_const_dict(files)
  log.xbuild("Embedded", count, "files ->", total_size, "bytes")
  return quote
    L:set_global_dict_of_strings(table_name, count, keys, vals)
  end
end

local function setup_unicode_terminal()
  if build.target_name() == "Windows" then
    -- Make sure the Windows console is set to use the Unicode codepage
    -- (so that we can print emojis)
    --
    -- This is equivalent to `os.execute("chcp 65001")` except it doesn't
    -- leave an annoying message in the terminal.
    local UNICODE_CODEPAGE = 65001
    local winapi = terralib.includecstring[[
    #include <stdint.h>
    typedef uint32_t UINT;
    typedef int BOOL;
    BOOL SetConsoleOutputCP(UINT wCodePageID);
    ]]
    return quote
      winapi.SetConsoleOutputCP(UNICODE_CODEPAGE)
    end
  else
    return quote end
  end
end

local LUA_INIT = [=[
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
  package.preload[modname] = embedded_loader
end

if _MAIN and #_MAIN > 0 then
  local main = require(_MAIN)
  main:run()
end
]=]

function m.generate_main(options)
  local LOG = options.LOG or require("substrate").configure().LOG
  options.LOG = LOG
  local luabuilt = lua.build(options)
  local LuaState = luabuilt.LuaState
  local files = assert(options.embedded_files, "No embedded files provided!")
  local lua_init_script = options.init_script or LUA_BOOT
  local lua_main = options.main or "main"

  local install_api_funcs = options.install_api or function(L, _lua, _options)
    if _options.compat then
      return require("./node_compat.t").install_compat_functions(L, _lua, _options)
    else
      return quote end
    end
  end

  local terra main(argc: int, argv: &&int8): int
    [setup_unicode_terminal()]

    var L: LuaState
    L:init()

    [embed_files(L, "_EMBEDDED_FILES", files)]
    [install_api_funcs(`L, luabuilt, options)]

    L:set_global_cstring("_MAIN", lua_main)
    L:set_global_array_of_strings("_CMDARGS", argc, argv)
    L:set_global_double("_RETURN_CODE", 0.0)

    if not L:do_cstring(lua_init_script) then
      return 1
    end

    return [int](L:get_global_double("_RETURN_CODE"))
  end

  return main
end

local function module_name(path, filepart)
  path = path .. filepart
  return path:gsub("%.lua$", ""):gsub("/", ".")
end

local function gather_files(rootdir)
  local files = {}
  for fullpath in iter_walk_files(rootdir) do
    local path, filepart = truss.splitpath(fullpath)
    if filepart:match("%.lua$") then
      path = path:gsub("^" .. rootdir .. "/?", "")
      if path == "/" then path = "" end
      local modname = module_name(path, filepart)
      local modsrc = truss.read_file(fullpath)
      files[modname] = modsrc
      log.debug("Adding", modname, ":", #modsrc, "bytes")
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
  local embedded_files = gather_files(assert(options.root_dir, "No root_dir"))
  local lua_version = options.lua_version or "jit"
  local libinfo = assert(LUA_LIBS[lua_version], "Invalid lua version: " .. lua_version)
  local lua_win_lib, lua_posix_lib = unpack(libinfo)

  local main = m.generate_main{
    embedded_files = embedded_files,
    lua_version = options.lua_version or "jit",
    main = options.main,
    install_api = options.install_api,
    init_script = options.init_script,
  }

  local bexport = require("build/binexport.t")
  local merge_sets = bexport.merge_sets

  bexport.export_binary{
    name = assert(options.name, ".name required!"),
    libpath = options.libpath or "lib",
    libs = merge_sets({
      all = {},
      Windows = {lua_win_lib},
      Linux = {lua_posix_lib},
      OSX = {lua_posix_lib},
    }, options.libs),
    syslibs = merge_sets({
      Windows = {"user32"}
    }, options.syslibs),
    platform = {
      Linux = {rpath = "lib/"},
      OSX = {rpath = "lib/"}
    },
    symbols = {main = main}
  }
end

return m