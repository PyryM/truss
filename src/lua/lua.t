local build = require("build/build.t")
local m = {}

local HEADERS = {
  ["terra"] = [[
    #include "terra/terra.h"

    // LUA_GLOBALSINDEX is a macro that terra is unable to parse
    // so wrap it into a function like this
    int get_lua_globalsindex() {
      return LUA_GLOBALSINDEX;
    }
  ]],
  ["jit"] = [[
    #include "luajit/lua_minimal.h"
  ]],
  ["5.4"] = [[
    #include "lua5.4/lua.h"
    #include "lua5.4/lualib.h"
    #include "lua5.4/lauxlib.h"
  ]],
  ["5.4+lpeg"] = [[
    #include "lua5.4/lua.h"
    #include "lua5.4/lualib.h"
    #include "lua5.4/lauxlib.h"
    int luaopen_lpeg (lua_State *L); // ???
  ]],
}

function m.create_const_dict(t)
  local keys = {}
  local vals = {}
  for k, _ in pairs(t) do
    table.insert(keys, k)
  end
  table.sort(keys)
  for _, k in ipairs(keys) do
    table.insert(vals, t[k])
  end

  local key_const = terralib.constant(`arrayof([&int8], [keys]))
  local val_const = terralib.constant(`arrayof([&int8], [vals]))

  return #keys, key_const, val_const
end

function m.build(options)
  local substrate = require("substrate")
  local LOG = substrate.configure().LOG
  local StringSlice = substrate.StringSlice

  local built = {}

  -- TODO: DBG_PRINT instead of raw printf

  local header_path = HEADERS["jit"]
  if options.lua_version and options.lua_version ~= "jit" then
    if build.is_native() then
      log.warn("Using non-jit lua is only allowed in export!")
      log.warn("Attempting to call lua functions in Terra will crash!")
    end
    header_path = options.lua_header or HEADERS[options.lua_version]
    assert(header_path, "No header for " .. options.lua_version)
  end
  log.info("Lua building with header [", header_path, "]")

  local C = build.includecstring(header_path)
  built.C = C
  built.lua_version = options.lua_version or "jit"

  local lua_State = C.lua_State

  -- LUA COMPATIBILITY FUNCTIONS --
  ---------------------------------

  -- macro in 5.4
  if not rawget(C, "lua_pcall") then
    assert(rawget(C, "lua_pcallk"), "No pcall or pcallk!")
    -- lua 5.4 defines pcall as a macro
    C.lua_pcall = macro(function(L, n, r, f)
      return `C.lua_pcallk(L, n, r, f, 0, nil)
    end)
  end

  -- macro in 5.4
  if not rawget(C, "luaL_loadbuffer") then
    assert(rawget(C, "luaL_loadbufferx"), "No loadbuffer or loadbufferx!")
    C.luaL_loadbuffer = macro(function(L,s,sz,n)
      return `C.luaL_loadbufferx(L, s, sz, n, nil)
    end)
  end

  -- macros in jit
  if not rawget(C, "lua_getglobal") then
    local LUA_GLOBALSINDEX = rawget(C, "LUA_GLOBALSINDEX")
    if not LUA_GLOBALSINDEX then
      LUA_GLOBALSINDEX = C.get_lua_globalsindex()
    end
    assert(LUA_GLOBALSINDEX, "Unable to determine LUA_GLOBALSINDEX!")

    C.lua_getglobal = macro(function(L, s)
      return `C.lua_getfield(L, LUA_GLOBALSINDEX, s)
    end)

    C.lua_setglobal = macro(function(L, s)
      return `C.lua_setfield(L, LUA_GLOBALSINDEX, s)
    end)
  end

  -- macro in 5.4
  if not rawget(C, "lua_tonumber") then
    C.lua_tonumber = macro(function(L, i)
      return `C.lua_tonumberx(L, i, nil)
    end)
  end

  -- macro in 5.4
  if not rawget(C, "lua_newuserdata") then
    C.lua_newuserdata = macro(function(L, s)
      return `C.lua_newuserdatauv(L, s, 1)
    end)
  end

  -- macro in 5.4
  if not rawget(C, "LUA_REGISTRYINDEX") then
    assert(rawget(C, "LUAI_MAXSTACK"), "Couldn't infer LUA_REGISTRYINDEX!")
    C.LUA_REGISTRYINDEX = -(C.LUAI_MAXSTACK) - 1000
  end

  -- HACK: this value isn't extracted correctly from lua 5.4 header
  if not rawget(C, "LUA_MULTRET") then C.LUA_MULTRET = -1 end

  ---------------------------------

  local struct LuaState {
    L: &lua_State;
    status: uint32;
  }

  local terra dostring(L: &lua_State, s: &int8): int32
    var err = C.luaL_loadstring(L, s)
    if err > 0 then return err end
    return C.lua_pcall(L, 0, C.LUA_MULTRET, 0)
  end

  local terra do_sized_string(L: &lua_State, s: &StringSlice): int32
    var err = C.luaL_loadbuffer(L, s.data, s.size, nil)
    if err > 0 then return err end
    return C.lua_pcall(L, 0, C.LUA_MULTRET, 0)
  end

  local terra isnil(L: &lua_State): bool
    return C.lua_type(L, -1) == C.LUA_TNIL
  end

  local terra lua_tostring(L: &lua_State, idx: int32): &int8
    return C.lua_tolstring(L, idx, nil)
  end

  local function openlibs(L)
    local libs = {quote C.luaL_openlibs(L) end}
    if rawget(C, "luaopen_lpeg") then
      log.info("Found lpeg, automatically opening!")
      -- assume lua 5.4 so we can use luaL_requiref
      table.insert(libs, quote 
        C.luaL_requiref(L, "lpeg", C.luaopen_lpeg, 1)
      end)
    end
    return libs
  end

  terra LuaState:create(): bool
    self.status = 0
    self.L = C.luaL_newstate()
    if self.L == nil then return false end
    [openlibs(`self.L)]
    self.status = 1
    return true
  end

  -- compat with things that expect an 'init'
  terra LuaState:init(): bool
    return self:create()
  end

  terra LuaState:check_error(status: int32): bool
    if status == 0 then return true end
    [LOG("Lua error: %s", `lua_tostring(self.L, -1))]
    return false
  end

  terra LuaState:do_string(s: &StringSlice): bool
    return self:check_error(do_sized_string(self.L, s))
  end

  terra LuaState:do_cstring(s: &int8): bool
    return self:check_error(dostring(self.L, s))
  end

  terra LuaState:call_argless(funcname: &int8): bool
    C.lua_getglobal(self.L, funcname)
    if isnil(self.L) then
      [LOG("Lua error: attempt to call nil global function [%s]", `funcname)]
      return false
    end
    return self:check_error(C.lua_pcall(self.L, 0, 0, 0))
  end

  terra LuaState:register_api_func(funcname: &int8, func: C.lua_CFunction)
    C.lua_pushcclosure(self.L, func, 0)
    C.lua_setglobal(self.L, funcname)
  end

  terra LuaState:set_global_cstring(gname: &int8, str: &int8)
    C.lua_pushstring(self.L, str)
    C.lua_setglobal(self.L, gname)
  end

  terra LuaState:set_global_string(gname: &int8, str: StringSlice)
    C.lua_pushlstring(self.L, str.data, str.size)
    C.lua_setglobal(self.L, gname)
  end

  terra LuaState:set_global_bool(gname: &int8, val: bool)
    var ival: int32 = 0
    if val then ival = 1 end
    C.lua_pushboolean(self.L, ival)
    C.lua_setglobal(self.L, gname)
  end

  terra LuaState:set_global_double(gname: &int8, val: double)
    C.lua_pushnumber(self.L, val)
    C.lua_setglobal(self.L, gname)
  end

  terra LuaState:set_global_dict_of_strings(tname: &int8, count: uint32, keys: &&int8, vals: &&int8)
    C.lua_createtable(self.L, 0, 0)
    for idx = 0, count do
      C.lua_pushstring(self.L, vals[idx])
      C.lua_setfield(self.L, -2, keys[idx])
    end
    C.lua_setglobal(self.L, tname)    
  end

  terra LuaState:set_global_array_of_strings(tname: &int8, count: uint32, strs: &&int8)
    C.lua_createtable(self.L, 0, 0)
    for idx = 0, count do
      C.lua_pushstring(self.L, strs[idx])
      C.lua_rawseti (self.L, -2, idx+1)
    end
    C.lua_setglobal(self.L, tname)
  end

  terra LuaState:set_global_pointer(gname: &int8, ptr: &opaque)
    C.lua_pushlightuserdata(self.L, ptr)
    C.lua_setglobal(self.L, gname)
  end

  terra LuaState:get_global_double(gname: &int8): double
    C.lua_getglobal(self.L, gname)
    var ret: double = C.lua_tonumber(self.L, -1)
    C.lua_settop(self.L, 0) -- clear stack
    return ret
  end

  terra LuaState:close()
    C.lua_close(self.L)
  end

  built.LuaState = LuaState
  built.ctype = LuaState

  return built
end

return m