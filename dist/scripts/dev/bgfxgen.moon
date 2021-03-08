-- dev/bgfxgen.moon
--
-- generate bgfx auxilliary files
-- assumes truss has been built into "../build/"

sutil = require "util/string.t"
argparse = require "util/argparse.t"
genconstants = require "dev/genconstants.t"

BGFX_PATH = "/bgfx_EXTERNAL-prefix/src/bgfx_EXTERNAL"

os_exec = (cmd) ->
  f = io.popen cmd, "r"
  ret = f\read "*all"
  f\close!
  ret

os_copy = (srcfn, destfn) ->
  cmd = if truss.os == "Windows"
    "copy \"#{srcfn\gsub("/", "\\")}\" \"#{destfn\gsub("/", "\\")}\" /y"
  else
    "cp \"#{srcfn}\" \"#{destfn}\""
  print cmd
  print os_exec cmd

copy_files = (buildpath) ->
  srcpath = "#{buildpath}#{BGFX_PATH}"
  os_copy "#{srcpath}/include/bgfx/defines.h", "include/bgfxdefines.h"
  os_copy "#{srcpath}/examples/common/shaderlib.sh", "shaders/raw/common/shaderlib.sh"
  os_copy "#{srcpath}/src/bgfx_shader.sh", "shaders/raw/common/bgfx_shader.sh"
  os_copy "#{srcpath}/src/bgfx_compute.sh", "shaders/raw/common/bgfx_compute.sh"

rawload = (fn) -> (io.open fn, "rt")\read "*a"

DEFINE_PATT = "^#define%s*([%w_]*)[^%(%w_]"

get_define_names = () ->
  -- assumes `defines.h` has been copied to `include/bgfxdefines.h`
  defnames = {}
  for line in *(sutil.split_lines rawload "include/bgfxdefines.h")
    name = line\match DEFINE_PATT
    if name and name != ""
      table.insert defnames, name
  defnames

get_constants = () -> genconstants.gen_constants_file get_define_names!

to_snake_case = (s) ->
  s_first = s\sub(1,1)\upper!
  s_rem = s\sub 2, -1
  s = s_first .. s_rem
  table.concat [v\lower! for v in s\gmatch "[%u%d]+%l*"], "_"

lower_snake = (s) -> (to_snake_case s)\lower!

upper_snake = (s) -> (to_snake_case s)\upper!

remove_comment = (s) -> 
  fpos = s\find "%-%-"
  if fpos
    s = s\sub 1, fpos-1
  sutil.strip s

fix5p1 = (data) ->
  lines = sutil.split_lines data
  outlines = {}
  for linepos = 1, #lines
    curline = sutil.strip lines[linepos]
    if (curline\sub 1,2) == "()"
      outlines[#outlines] = (remove_comment outlines[#outlines]) .. curline
    else
      outlines[#outlines+1] = lines[linepos]
  temp = io.open "bleh.lua", "wt"
  temp\write table.concat outlines, "\n"
  temp\close!
  table.concat outlines, "\n"

_flatten = (dest, list) ->
  for v in *list
    if type(v) == 'table' then
      _flatten dest, v
    else
      dest[#dest+1] = v
  dest

flatten = (lists) -> _flatten {}, lists

conflatten = (lists) -> table.concat (flatten lists), "\n"

ordered_concat = (t, keyorder, sep) ->
  table.concat [t[k] for k in *keyorder], (sep or "\n\n")

key_sorted_concat = (t, sep) ->
  sorted_keys = [k for k, v in pairs t]
  table.sort sorted_keys
  ordered_concat t, sorted_keys, sep

exec_in = (env, fn) ->
  chunk, err = loadstring fix5p1 rawload fn
  if not chunk
    truss.error "Error parsing #{fn}: #{err}"
  setfenv chunk, env
  chunk! or env

load_idl = (buildpath) ->
  env = truss.extend_table {}, truss.clean_subenv
  path = buildpath .. BGFX_PATH
  print "Loading IDL from [#{path}]"
  idl = exec_in env, "#{path}/scripts/idl.lua"
  exec_in idl, "#{path}/scripts/bgfx.idl"

is_api_func = (line) ->
  parts = sutil.split " ", line
  if parts[1] != "BGFX_C_API" then return nil
  api_key = (parts[2] != "const" and parts[3]) or parts[4] or line
  api_key = (sutil.split "%(", api_key)[1]
  (table.concat [p for p in *parts[2,]], " "), api_key

get_functions = (buildpath) ->
  -- generating function signatures from the IDL is too much of a pain
  -- instead just read them from the C-api header
  path = "#{buildpath}#{BGFX_PATH}/include/bgfx/c99/bgfx.h"
  api_funcs = {}
  for line in *(sutil.split_lines rawload path)
    api_line, api_order_key = is_api_func line
    if api_line then api_funcs[api_order_key] = api_line
  key_sorted_concat api_funcs, "\n"

gen_enum = (e) ->
  format_val = if e.underscore
    (v) -> upper_snake v
  else
    (v) -> v\upper!
  name = "bgfx_#{lower_snake e.name}"
  conflatten {
    "typedef enum #{name} {",
    (table.concat ["    #{name\upper!}_#{format_val v.name}" for v in *e.enum], ",\n") .. ",",
    "    #{name\upper!}_COUNT",
    "} #{name}_t;"
  }

gen_enums = (idl) ->
  enums = {t.name, gen_enum t for t in *idl.types when t.enum}
  key_sorted_concat enums, "\n\n"

gen_handle = (handle) ->
  name =  "bgfx_#{lower_snake handle.name}"
  "typedef struct #{name} { uint16_t idx; } #{name}_t;"

gen_handles = (idl) ->
  handles = {t.name, gen_handle t for t in *idl.types when t.handle}
  key_sorted_concat handles, "\n"

is_pointer = (s) -> ((s\sub -1) == "*") and (s\sub 1, -2)

is_const = (s) -> ((s\sub 1, 5) == "const") and (s\sub 7)

is_enum = (s) ->
  parts = sutil.split "::", s
  if #parts == 2 and (parts[2]\sub 1, 4) == "Enum"
    parts[1]
  else
    false

is_array = (s) ->
  array_start = s\find "%["
  if not array_start then return nil, nil
  return (s\sub 1, array_start-1), (s\sub array_start+1, -2)

FIXED_TYPES = {
  "float": "float"
  "double": "double"
  "char": "char"
  "bool": "bool"
  "CallbackI": "bgfx_callback_interface_t"
  "bx::AllocatorI": "bgfx_allocator_interface_t"
  "void": "void"
}
for itype in *{8, 16, 32, 64}
  for qualifier in *{"uint", "int"}
    tname = "#{qualifier}#{itype}_t"
    FIXED_TYPES[tname] = tname

format_count = (count) ->
  parts = sutil.split "::", count
  if #parts == 2 -- assume ::Count
    "BGFX_#{upper_snake parts[1]}_COUNT"
  else
    count

namespaced_structs = {}

format_type = (t, parent) ->
  subtype, count = is_array t
  if subtype
    (format_type subtype, parent), (format_count count)
  else
    pointer_type = is_pointer t
    if pointer_type
      t = pointer_type
    const_type = is_const t
    if const_type
      t = const_type
    res = ""
    if FIXED_TYPES[t]
      res = FIXED_TYPES[t]
    else
      res = lower_snake ((is_enum t) or t)
      if parent and namespaced_structs["#{parent}_#{res}"]
        res = "#{parent}_#{res}"
      res = "bgfx_" .. res .. "_t"
    if pointer_type
      res = res .. "*"
    if const_type
      res = "const " .. res
    res

format_field = (f, parent) -> 
  argtype, argcount = format_type f.fulltype, parent
  name = f.name
  if argcount
    name = "#{name}[#{argcount}]"
  "    #{argtype} #{name};"

gen_struct = (struct) ->
  name = lower_snake struct.name
  if struct.namespace
    name = "#{lower_snake struct.namespace}_#{name}"
    namespaced_structs[name] = true
  if #struct.struct == 0
    return name, "typedef struct bgfx_#{name}_s bgfx_#{name}_t;"
  name, conflatten {
    "typedef struct bgfx_#{name}_s {",
    [format_field f, name for f in *struct.struct]
    "} bgfx_#{name}_t;"
  }

gen_structs = (idl) ->
  structs = {}
  for t in *idl.types
    if not t.struct then continue
    name, struct = gen_struct t
    table.insert structs, struct
  table.concat structs, "\n\n"

PREAMBLE = [[
/*
 * BGFX Copyright 2011-2021 Branimir Karadzic. All rights reserved.
 * License: https://github.com/bkaradzic/bgfx/blob/master/LICENSE
 *
 * This header is slightly modified to make it easier for Terra
 * to digest; it is automatically generated from the 'real' BGFX
 * headers and IDL by `dev/bgfxgen.moon`.
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

gen_header = (buildpath) ->
  idl = load_idl buildpath
  conflatten {
    PREAMBLE,
    "\n\n/* Enums: */\n",
    gen_enums idl,
    "\n\n/* Handle types: */\n",
    gen_handles idl,
    "\n\n/* Structs: */\n",
    gen_structs idl,
    "\n\n/* Functions: */\n",
    get_functions buildpath,
    "\n",
    "#endif // BGFX_C99_H_HEADER_GUARD"
  }

export init = ->
  bpath = "../build"
  print "Copying files"
  copy_files bpath
  print "Generating include/bgfx_truss.c99.h"
  truss.save_string "include/bgfx_truss.c99.h", (gen_header bpath)
  print "Generating scripts/gfx/bgfx_constants.t"
  truss.save_string "scripts/gfx/bgfx_constants.t", get_constants!
  print "Done."
  truss.quit!

export update = ->
  truss.quit!