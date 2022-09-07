-- dev/bgfxgen.t
--
-- generate bgfx auxilliary files

local sutil = require "util/string.t"
local argparse = require "util/argparse.t"
local genconstants = require "dev/genconstants.t"

local BGFX_PATH = "include/bgfx/"

local function os_exec(cmd)
  log.debug("cmd exec:", cmd)
  local f = io.popen(cmd, "r")
  local ret = f:read("*a")
  f:close()
  return ret
end

local function os_copy(srcfn, destfn)
  local cmd
  srcfn = truss.normpath(srcfn, true)
  destfn = truss.normpath(destfn, true)
  if truss.os == "Windows" then
    cmd = "copy " .. srcfn .. " " .. destfn .. " /y"
  else
    cmd = "cp " .. srcfn .. " " .. destfn
  end
  os_exec(cmd)
end

local DEFINE_PATT = "^#define%s*([%w_]*)[^%(%w_]"

local function get_define_names()
  local defnames = {}
  local lines = sutil.split_lines(truss.read_file("include/bgfx/defines.h"))
  for _, line in ipairs(lines) do
    local name = line:match(DEFINE_PATT)
    if name and name ~= "" then
      table.insert(defnames, name)
    end
  end
  return defnames
end

local function get_constants()
  return genconstants.gen_constants_file(get_define_names())
end

local function to_snake_case(s)
  local s_first = s:sub(1,1):upper()
  local s_rem = s:sub(2, -1)
  local s = s_first .. s_rem
  local frags = {}
  for v in s:gmatch("[%u%d]+%l*") do
    table.insert(frags, v:lower())
  end
  return table.concat(frags, "_")
end

local function lower_snake(s) 
  return to_snake_case(s):lower() 
end

local function upper_snake(s)
  return to_snake_case(s):upper()
end

local function remove_comment(s)
  local fpos = s:find("%-%-")
  if fpos then
    s = s:sub(1, fpos-1)
  end
  return sutil.strip(s)
end

-- bgfx's IDL is written with some syntax quirks that don't
-- parse correctly in luajit / 5.1
local function fix5p1(data)
  local lines = sutil.split_lines(data)
  local outlines = {}
  local cur_enum = nil
  for linepos = 1, #lines do
    local curline = remove_comment(sutil.strip(lines[linepos]))
    if curline:sub(1,4) == "enum" then
      cur_enum = curline:sub(5, -1)
    elseif cur_enum and curline == "" then
      if outlines[#outlines]:sub(-2, -1) ~= "()" then
        log.debug("Enum missing function call:", cur_enum)
        outlines[#outlines] = outlines[#outlines] .. "()"
      end
      cur_enum = nil
    end
    
    if curline:sub(1, 2) == "()" then
      outlines[#outlines] = outlines[#outlines] .. curline
    else
      outlines[#outlines+1] = curline
    end
  end
  return table.concat(outlines, "\n")
end

local function _flatten(dest, list)
  for _, v in ipairs(list) do
    if type(v) == 'table' then
      _flatten(dest, v)
    else
      dest[#dest+1] = v
    end
  end
  return dest
end

local function flatten(lists)
  return _flatten({}, lists)
end

-- concat(flatten(lists))
local function conflatten(lists)
  return table.concat(flatten(lists), "\n")
end

local function ordered_concat(t, keyorder, sep)
  local frags = {}
  for _, k in ipairs(keyorder) do
    table.insert(frags, t[k])
  end
  return table.concat(frags, sep or "\n\n")
end

local function key_sorted_concat(t, sep)
  local sorted_keys = {}
  for k, _ in pairs(t) do
    table.insert(sorted_keys, k)
  end
  table.sort(sorted_keys)
  return ordered_concat(t, sorted_keys, sep)
end

local function exec_in(env, fn)
  local src = fix5p1(truss.read_script(fn))
  local chunk, err = loadstring(src)
  if not chunk then
    error("Error parsing " .. fn .. ": " .. err)
  end
  setfenv(chunk, env)
  return chunk() or env
end

local function load_idl()
  local env = truss.extend_table({}, truss.bare_env)
  local idl = exec_in(env, truss.joinvpath(BGFX_PATH, "idl.lua"))
  return exec_in(idl, truss.joinvpath(BGFX_PATH, "bgfx.idl"))
end

local BANNED_TYPES = {"va_list"}

local function is_api_func(line)
  local parts = sutil.split(" ", line)
  if parts[1] ~= "BGFX_C_API" then return nil end
  local api_key = (parts[2] ~= "const" and parts[3]) or parts[4] or line
  api_key = sutil.split("%(", api_key)[1]
  local signature = table.concat(truss.slice_list(parts, 2, #parts), " ")
  for _, bad_type in ipairs(BANNED_TYPES) do
    if line:find(bad_type) then
      signature = "//" .. signature
      break
    end
  end
  return signature, api_key
end

local function get_functions()
  -- generating function signatures from the IDL is too much of a pain
  -- instead just read them from the C-api header
  local path = truss.joinvpath(BGFX_PATH, "bgfx.h")
  local api_funcs = {}
  for _, line in ipairs(sutil.split_lines(truss.read_script(path))) do
    local api_line, api_order_key = is_api_func(line)
    if api_line then api_funcs[api_order_key] = api_line end
  end
  return key_sorted_concat(api_funcs, "\n")
end

local function gen_enum(e)
  local format_val
  if e.underscore then
    format_val = upper_snake
  else
    format_val = string.upper
  end
  local name = "bgfx_" .. lower_snake(e.name)
  local body_frags = {}
  for _, v in ipairs(e.enum) do
    local entry = "    " .. name:upper() .. "_" .. format_val(v.name)
    table.insert(body_frags, entry)
  end
  local enum_body = table.concat(body_frags, ",\n")

  return conflatten({
    "typedef enum " .. name .. " {",
    enum_body .. ",",
    "    " .. name:upper() .. "_COUNT",
    "} " .. name .. "_t;"
  })
end

local function gen_enums(idl)
  local enums = {}
  for _, t in ipairs(idl.types) do
    if t.enum then
      enums[t.name] = gen_enum(t)
    end
  end
  return key_sorted_concat(enums, "\n\n")
end

local function gen_handle(handle)
  local name = "bgfx_" .. lower_snake(handle.name)
  return "typedef struct " .. name .. " { uint16_t idx; } " .. name .. "_t;"
end

local function gen_handles(idl)
  local handles = {}
  for _, t in ipairs(idl.types) do
    if t.handle then
      handles[t.name] = gen_handle(t)
    end
  end
  return key_sorted_concat(handles, "\n")
end

local function is_pointer(s)
  return (s:sub(-1) == "*") and s:sub(1, -2)
end

local function is_const(s)
  return (s:sub(1, 5) == "const") and s:sub(7)
end

local function is_enum(s)
  local parts = sutil.split("::", s)
  if #parts == 2 and parts[2]:sub(1, 4) == "Enum" then
    return parts[1]
  else
    return false
  end
end

local function is_array(s)
  local array_start = s:find("%[")
  if not array_start then return nil, nil end
  return s:sub(1, array_start-1), s:sub(array_start+1, -2)
end

local FIXED_TYPES = {
  float = "float",
  double = "double",
  char = "char",
  bool = "bool",
  CallbackI = "bgfx_callback_interface_t",
  ["bx::AllocatorI"] = "bgfx_allocator_interface_t",
  void = "void",
}

for _, itype in ipairs{8, 16, 32, 64} do
  for __, qualifier in ipairs{"uint", "int"} do
    local tname = qualifier .. itype .. "_t"
    FIXED_TYPES[tname] = tname
  end
end

local function format_count(count)
  local parts = sutil.split("::", count)
  if #parts == 2 then -- assume ::Count
    return "BGFX_" .. upper_snake(parts[1]) .. "_COUNT"
  else
    return count
  end
end

local namespaced_structs = {}

local function format_type(t, parent)
  local subtype, count = is_array(t)
  if subtype then
    return format_type(subtype, parent), format_count(count)
  end
  local pointer_type = is_pointer(t)
  if pointer_type then
    t = pointer_type
  end
  local const_type = is_const(t)
  if const_type then
    t = const_type
  end
  local res = ""
  if FIXED_TYPES[t] then
    res = FIXED_TYPES[t]
  else
    res = lower_snake(is_enum(t) or t)
    if parent then
      local ns_name = parent .. "_" .. res
      if namespaced_structs[ns_name] then
        res = ns_name
      end
    end
    res = "bgfx_" .. res .. "_t"
  end
  if pointer_type then
    res = res .. "*"
  end
  if const_type then
    res = "const " .. res
  end
  return res
end

local function format_field(f, parent)
  local argtype, argcount = format_type(f.fulltype, parent)
  local name = f.name
  if argcount then
    name = name .. "[" .. argcount .. "]"
  end
  return "    " .. argtype .. " " .. name .. ";"
end

local function gen_struct(decl)
  local name = lower_snake(decl.name)
  if decl.namespace then
    name = lower_snake(decl.namespace) .. "_" .. name
    namespaced_structs[name] = true
  end
  if #decl['struct'] == 0 then
    local td = "typedef struct bgfx_" .. name .. "_s bgfx_" .. name .. "_t;"
    return name, td
  end
  local body = {}
  for _, f in ipairs(decl['struct']) do
    table.insert(body, format_field(f, name))
  end
  return name, conflatten({
    "typedef struct bgfx_" .. name .. "_s {",
    body,
    "} bgfx_" .. name .. "_t;"
  })
end

local function gen_structs(idl)
  local defs = {}
  for _, t in ipairs(idl.types) do
    if t['struct'] then
      local __, def = gen_struct(t)
      table.insert(defs, def)
    end
  end
  return table.concat(defs, "\n\n")
end

local PREAMBLE = [[
/*
 * BGFX Copyright 2011-2022 Branimir Karadzic. All rights reserved.
 * License: https://github.com/bkaradzic/bgfx/blob/master/LICENSE
 *
 * This header is slightly modified to make it easier for Terra
 * to digest; it is automatically generated from the 'real' BGFX
 * headers and IDL by `dev/bgfxgen.t`.
 */

#ifndef BGFX_C99_H_HEADER_GUARD
#define BGFX_C99_H_HEADER_GUARD

//#include <stdarg.h>  // va_list
#include <stdbool.h> // bool
#include <stdint.h>  // uint32_t
#include <stdlib.h>  // size_t

#undef UINT32_MAX
#define UINT32_MAX 4294967295
#define BGFX_UINT32_MAX 4294967295

#define BGFX_INVALID_HANDLE 0xffff
typedef uint16_t bgfx_view_id_t;

typedef struct bgfx_interface_vtbl bgfx_interface_vtbl_t;
typedef struct bgfx_callback_interface bgfx_callback_interface_t;
typedef struct bgfx_callback_vtbl bgfx_callback_vtbl_t;
typedef struct bgfx_allocator_interface bgfx_allocator_interface_t;
typedef struct bgfx_allocator_vtbl bgfx_allocator_vtbl_t;

typedef void (*bgfx_release_fn_t)(void* _ptr, void* _userData);
]]

local function gen_header() 
  local idl = load_idl()
  return conflatten({
    PREAMBLE,
    "\n\n/* Enums: */\n",
    gen_enums(idl),
    "\n\n/* Handle types: */\n",
    gen_handles(idl),
    "\n\n/* Structs: */\n",
    gen_structs(idl),
    "\n\n/* Functions: */\n",
    get_functions(),
    "\n",
    "#endif // BGFX_C99_H_HEADER_GUARD"
  })
end

log.todo("Switch to correct truss file write functions")
local function save_string(path, s)
  local dest = io.open(path, "wb")
  dest:write(s)
  dest:close()
end

local function init()
  log.info("Generating include/bgfx/bgfx_truss.c99.h")
  save_string("include/bgfx/bgfx_truss.c99.h", gen_header())
  log.info("Generating src/gfx/bgfx_constants.t")
  save_string("src/gfx/bgfx_constants.t", get_constants())
  log.info("Done.")
end

return {init = init}
