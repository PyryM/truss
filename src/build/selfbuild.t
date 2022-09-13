-- builds truss binary with truss or terra
local _truss = rawget(_G, "truss")
if not _truss then
  -- we're running in terra, so bootstrap into truss
  terralib.loadfile("src/core/core.t")()
end

if not truss.using_system_headers then
  log.fatal("self-build cannot use bundled compat headers")
  if truss.os == "Windows" then
    log.fatal("Try running through 'Developer Command Prompt for VS 2022'")
  end
  error("C headers not available")
end

local binname = truss.binary_name:lower()
if binname == "truss" or binname == "truss.exe" then
  log.fatal("truss[.exe] cannot overwrite itself while running!")
  log.fatal("to build truss with truss, first rename the old truss binary.")
  error("Cannot overwrite own binary while running")
end

local clib = require("native/clib.t")

local terra_c = terralib.includecstring[[
#include "terra/terra.h"

// LUA_GLOBALSINDEX is a macro that terra is unable to parse
// so wrap it into a function like this
int get_lua_globalsindex() {
  return LUA_GLOBALSINDEX;
}
]]

local LUA_GLOBALSINDEX = terra_c.get_lua_globalsindex()

-- create embedded files
local function find_core_file(fn)
  local f = io.open(truss._COREPATH .. fn)
  local data = f:read("*a")
  f:close()
  return data
end

local embeds = {}
for _, fn in ipairs(truss._COREFILES) do
  embeds[fn] = find_core_file(fn)
end

local coresrc = find_core_file("core.t")

local function embed_core_files(state_q)
  local embed_statements = {}
  for fn, content in pairs(embeds) do
    local contentsize = #content
    table.insert(embed_statements, quote
      terra_c.lua_pushlstring(state_q, content, contentsize)
      terra_c.lua_setfield(state_q, -2, fn)
    end)
  end
  return quote
    terra_c.lua_createtable(state_q, 0, 0)
    [embed_statements]
    terra_c.lua_setfield(state_q, LUA_GLOBALSINDEX, "_TRUSS_EMBEDDED")
  end
end

local terra call_global_func(L: &terra_c.lua_State, name: &int8): bool
  terra_c.lua_getfield(L, LUA_GLOBALSINDEX, name)
  var runres = terra_c.lua_pcall(L, 0, 0, 0)
  if runres ~= 0 then
    clib.io.printf(
      "Error running [%s]: %s\n", name, terra_c.lua_tolstring(L, -1, nil))
    return false
  end
  return true
end

local terra update_loop(L: &terra_c.lua_State): int
  while true do
    terra_c.lua_getfield(L, LUA_GLOBALSINDEX, "_TRUSS_RUNNING")
    var running = terra_c.lua_toboolean(L, -1)
    terra_c.lua_settop(L, -2)
    if running == 0 then break end
    if not call_global_func(L, "_core_update") then
      return 1
    end
  end

  terra_c.lua_getfield(L, LUA_GLOBALSINDEX, "_TRUSS_RETURN_CODE")
  return terra_c.lua_tointeger(L, -1)
end

local terra push_args(L: &terra_c.lua_State, argc: int, argv: &&int8)
  terra_c.lua_createtable(L, 0, 0)
  for idx = 0, argc do
    terra_c.lua_pushstring(L, argv[idx])
    terra_c.lua_rawseti(L, -2, idx+1)
  end
  terra_c.lua_setfield(L, LUA_GLOBALSINDEX, "_TRUSS_ARGS")
end

local terra main(argc: int, argv: &&int8): int
  var L = terra_c.luaL_newstate()
  terra_c.luaL_openlibs(L)

  var ops = terra_c.terra_Options {
    verbose = 0,
    debug = 0,
    cmd_line_chunk = nil,
  }
  terra_c.terra_initwithoptions(L, &ops)

  terra_c.lua_pushlstring(L, [truss.version], [#truss.version])
  terra_c.lua_setfield(L, LUA_GLOBALSINDEX, "_TRUSS_VERSION")

  -- set embeds
  [embed_core_files(L)]

  -- set args
  push_args(L, argc, argv)

  terra_c.lua_pushboolean(L, 1)
  terra_c.lua_setfield(L, LUA_GLOBALSINDEX, "_TRUSS_RUNNING")
  terra_c.lua_pushinteger(L, 0)
  terra_c.lua_setfield(L, LUA_GLOBALSINDEX, "_TRUSS_RETURN_CODE")

  -- run core
  var loadres = terra_c.terra_loadbuffer(L, coresrc, [#coresrc], "core.t")
  if loadres ~= 0 then
    clib.io.printf("Error parsing core: %s\n", terra_c.lua_tolstring(L, -1, nil))
    return 1
  end

  var runres = terra_c.lua_pcall(L, 0, 0, 0)
  if runres ~= 0 then
    clib.io.printf("Error running core: %s\n", terra_c.lua_tolstring(L, -1, nil))
    return 1
  end

  return update_loop(L)
end

require("build/binexport.t").export_binary{
  name = "truss",
  libpath = "lib",
  libs = {
    all = {"terra"},
    Windows = {"lua51"}
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

return {init = function() truss.quit() end}
