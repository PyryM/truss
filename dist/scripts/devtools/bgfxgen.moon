-- devtools/bgfxgen.moon
--
-- generate bgfx auxilliary files
-- assumes truss has been built into "../build/"

sutil = require "utils/stringutils.t"
argparse = require "utils/argparse.t"

BGFX_PATH = "/bgfx_EXTERNAL-prefix/src/bgfx_EXTERNAL"

rawload = (fn) -> (io.open fn, "rt")\read "*a"

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

key_sorted_concat = (t, sep) ->
  sorted_keys = [k for k, v in pairs t]
  table.sort sorted_keys
  table.concat [t[k] for k in *sorted_keys], (sep or "\n\n")

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

SNAKE_ENUMS = {
  "Fatal": true
  "Topology": true
  "TopologyConvert": true
  "TopologySort": true
  "ViewMode": true
  "RenderFrame": true
  "RendererType": false
  "Access": false
  "Attrib": false
  "AttribType": false
  "TextureFormat": false
  "UniformType": false
  "OcclusionQueryResult": false
}

gen_enum = (e) ->
  format_val = if e.underscore --SNAKE_ENUMS[e.name]
    (v) -> upper_snake v
  else
    (v) -> v\upper!
  name = "bgfx_#{lower_snake e.name}"
  conflatten {
    "typedef enum #{name} {",
    (table.concat ["    #{name\upper!}_#{format_val v.name}" for v in *e.enum], ",\n"),
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
      print "Checking #{parent}_#{res}"
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
    print "NS: #{name}"
    namespaced_structs[name] = true
  if #struct.struct == 0
    return "typedef struct bgfx_#{name}_s bgfx_#{name}_t;"
  conflatten {
    "typedef struct bgfx_#{name}_s {",
    [format_field f, name for f in *struct.struct]
    "} bgfx_#{name}_t"
  }

gen_structs = (idl) ->
  structs = {t.name, gen_struct t for t in *idl.types when t.struct}
  key_sorted_concat structs, "\n\n"

export init = ->
  idl = load_idl "../build"
  print gen_enums idl
  print "\n"
  print gen_handles idl
  print "\n"
  print gen_structs idl
  truss.quit!

export update = ->
  truss.quit!