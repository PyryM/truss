-- lua/node_compat
--
-- attempts to provide a few interfaces to mimic
-- nodejs for TSTL usage.

local m = {}
local build = require("build/build.t")

-- node fs functions:
--
-- fs.readdirSync(path[, options])
--   path <string>
--   options: ignored
-- Returns: <string[]>

local DEFAULT_OPTIONS = {
  fs_support = "trussfs"
}

local function empty_quote()
  return quote end
end

local function install_trussfs(lua, L, options)
  local trussfs_c = build.includecstring[[
  #include "trussfs.h"
  ]]

  local lua_State = lua.C.lua_State
  local fs_ctx_t = trussfs_c.trussfs_ctx

  -- TODO: consider wrapping this somehow in something that'll
  -- autocreate a context as needed!
  local terra get_fs_ctx(L: &lua_State): &fs_ctx_t
    var state: lua.LuaState
    state:wrap(L)
    var ctx: &fs_ctx_t = [&fs_ctx_t](state:get_registry_pointer("trussfs_ctx"))
    if ctx == nil then
      [options.LOG("Creating FS context!")]
      ctx = trussfs_c.trussfs_init()
      state:set_registry_pointer("trussfs_ctx", ctx)
    end
    return ctx
  end

  local terra lua_recursive_makedir(L: &lua_State): int
    lua.C.luaL_checktype(L, 1, lua.C.LUA_TSTRING)
    var path = lua.C.lua_tolstring(L, 1, nil)
    var ctx = get_fs_ctx(L)
    trussfs_c.trussfs_recursive_makedir(ctx, path)
    return 0
  end

  local terra lua_get_working_dirs(L: &lua_State): int
    var ctx = get_fs_ctx(L)
    lua.C.lua_pushstring(L, trussfs_c.trussfs_working_dir(ctx))
    lua.C.lua_pushstring(L, trussfs_c.trussfs_binary_dir(ctx))
    return 2
  end

  local terra lua_listdir(L: &lua_State): int
    lua.C.luaL_checktype(L, 1, lua.C.LUA_TSTRING)
    lua.C.luaL_checktype(L, 2, lua.C.LUA_TBOOLEAN)
    lua.C.luaL_checktype(L, 3, lua.C.LUA_TBOOLEAN)

    var path = lua.C.lua_tolstring(L, 1, nil)
    var files_only = lua.C.lua_toboolean(L, 2) ~= 0
    var with_metadata = lua.C.lua_toboolean(L, 3) ~= 0

    var ctx = get_fs_ctx(L)
    var dirlist = trussfs_c.trussfs_list_dir(ctx, path, files_only, with_metadata)
    var nentries = trussfs_c.trussfs_list_length(ctx, dirlist)

    lua.C.lua_createtable(L, nentries, 0)
    for idx = 0, nentries do
      var entry = trussfs_c.trussfs_list_get(ctx, dirlist, idx)
      lua.C.lua_pushstring(L, entry)
      lua.C.lua_rawseti(L, -2, idx+1)
    end

    trussfs_c.trussfs_list_free(ctx, dirlist)
    return 1
  end

  return quote
    var vnum = trussfs_c.trussfs_version()
    L:set_global_double("_LINKED_TRUSSFS_VERSION", [double](vnum))
    [options.LOG("Linked trussfs version: %d", vnum)]
    L:register_api_func("fs_listdir", lua_listdir)
    L:register_api_func("fs_makedir", lua_recursive_makedir)
    L:register_api_func("fs_workdir", lua_get_working_dirs)
  end
end

local function install_fs(lua, L, options)
  if not options.fs_support then
    return empty_quote(lua, L, options)
  else
    return install_trussfs(lua, L, options)
  end
  --   return assert(
  --     FS_LIBS[options.fs_support], 
  --     "Invalid fs_support: " .. options.fs_support
  --   )(L, options)
  -- end
end

function m.install_compat_functions(L, lua, user_options)
  local options = truss.extend_table({}, DEFAULT_OPTIONS)
  options = truss.extend_table(options, user_options)
  return quote
    [install_fs(lua, L, options)]
  end
end

return m