-- buildshaders.moon
--
-- shader builder (in moonscript I guess?)

mc = require "devtools/miniconsole.t"
sutil = require "utils/stringutils.t"
async = require "async"
argparse = require "utils/argparse.t"

local app

is_shader = (fn) -> (fn\sub -3) == ".sc"

listdir = (dir) -> ["#{dir}/#{fn}" for fn in *(truss.list_directory dir)]

find_loose_shaders = (dir) ->
  [fn for fn in *(listdir dir) when (is_shader fn) and (not truss.is_archived fn)]

find_shader_dirs = (dir) ->
  [p for p in *(listdir dir) when truss.is_directory p]

normpath = (path) ->
  if truss.os == 'Windows'
    path\gsub("/", "\\")
  else
    path

extend = (a, b) ->
  for v in *b
    a[#a+1] = v
  a

SHADER_DIR = "shaders"
WIN_SHADER_TYPES = {
  f: "ps_4_0"
  v: "vs_4_0"
  c: "cs_4_0"
}
PLATFORMS = {
  windows: "dx11",
  linux: "glsl",
  osx: "mtl"
}

make_cmd = (shader_type, platform, input_fn, output_fn) ->
  args = if platform == "linux"
    {"./#{SHADER_DIR}/raw/shadercRelease"}
  else
    {"#{SHADER_DIR}/raw/shadercRelease"}
  extend args, {
    "-f", input_fn, 
    "-o", output_fn,
    "--type", shader_type,
    "-i", "#{SHADER_DIR}/raw/common/",
    "--platform", platform
  }
  extend args, switch platform 
    when "linux"
      {"-p", "120"}
    when "windows"
      {"-p", WIN_SHADER_TYPES[shader_type], 
       "-O", "3"}
    when "osx"
      {"-p", "metal"}
  args[#args+1] = "2>&1"
  normpath table.concat args, " "

do_cmd = (cmd) ->
  f = io.popen cmd, 'r'
  s = f\read '*a'
  f\close!
  s

header = (s, n = 80, char = "=") ->
  n -= (#s + 2)
  pre = math.floor n / 2
  "#{string.rep(char, pre)} #{s} #{string.rep(char, n - pre)}"

do_file = (fn) ->
  parts = sutil.split "/", fn
  filename = parts[#parts]
  if filename == "varying.def.sc" then return
  prefix = filename\sub(1,1)
  errors = ""
  for platform, lang in pairs PLATFORMS
    cmd = make_cmd prefix, platform, fn, "#{SHADER_DIR}/#{lang}/#{filename\sub(1,-4)}.bin"
    res = do_cmd cmd
    if #res > 2
      app\print "#{filename}: #{lang} =>"
      app\print res, 6
      errors ..= (header lang, 80, '-') .. "\n" .. res
  if #errors > 0
    errors
  else
    nil

concat = (t) ->
  table.concat ["#{header(k)}\n#{v}" for k,v in pairs t], "\n"

stdout_print = (_, text, fg, bg) ->
  print(text)

export init = ->
  args = argparse.parse!
  app = if args['--repl'] 
    mc.ConsoleApp {title: 'Shader Compiler'}
  else
    {print: stdout_print, update: ->, clear: ->, finish: truss.quit}

  async.run ->
    app\clear!
    app\print "Compiling shaders:"
    errors = {}
    for dir in *(find_shader_dirs "#{SHADER_DIR}/raw")
      app\print dir
      for fn in *(find_loose_shaders dir)
        app\print fn
        errors[fn] = do_file fn
        async.await_frames 1
    app\print "Done."
    if args['-o']
      truss.save_string args['-o'], (concat errors, '\n')
    if app.finish then app\finish!

export update = ->
  async\update!
  app\update!