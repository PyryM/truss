-- buildshaders.moon
--
-- shader builder (in moonscript I guess?)

mc = require "dev/miniconsole.t"
sutil = require "util/string.t"
async = require "async"
argparse = require "util/argparse.t"

local app

listdir = (dir) -> [{fn, "#{dir}/#{fn}"} for fn in *(truss.list_directory dir)]

is_shader = (fn) -> (fn != 'varying.def.sc') and ((fn\sub -3) == '.sc')

find_loose_shaders = (dir) ->
  [{fn, p} for {fn, p} in *(listdir dir) when (is_shader fn) and (not truss.is_archived p)]

find_shader_dirs = (dir) ->
  [p for {_, p} in *(listdir dir) when truss.is_directory p]

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
DX_SHADER_TYPES = {
  f: "ps_4_0"
  v: "vs_4_0"
  c: "cs_5_0"
}

BACKEND_SHORTNAMES = {
  directx: "dx11",
  dx11: "dx11",
  dx12: "dx11",
  opengl: "glsl",
  metal: "mtl",
  vulkan: "spirv"
}

BACKEND_TO_BGFX_PLATFORM = {
  directx: "windows",
  dx11: "windows",
  dx12: "windows",
  opengl: "linux",
  vulkan: "linux",
  metal: "osx"
}

BACKEND_SETS = {
  windows: {"directx", "vulkan"},
  windows_all: {"directx", "vulkan", "metal", "opengl"},
  osx: {"metal"},
  osx_all: {"metal", "vulkan", "opengl"},
  linux: {"vulkan"},
  linux_all: {"vulkan", "opengl"}
}

CHARS = if truss.os == "OSX"
  {vert: "│", term: "└"}
else
  {vert: "\179", term: "\192"}

make_cmd = (shader_type, backend, input_fn, output_fn) ->
  args = if truss.os == "Linux" or truss.os == "OSX"
    {"./bin/shadercRelease"}
  else
    {"bin/shadercRelease"}
  extend args, {
    "-f", input_fn, 
    "-o", output_fn,
    "--type", shader_type,
    "-i", "#{SHADER_DIR}/raw/common/",
    "--platform", BACKEND_TO_BGFX_PLATFORM[backend]
  }
  extend args, switch backend 
    when "opengl"
      {"-p", "140"}
    when "directx" or "dx11" or "dx12"
      {"-p", DX_SHADER_TYPES[shader_type], 
       "-O", "3"}
    when "metal"
      {"-p", "metal"}
    when "vulkan"
      {"-p", "spirv"}
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

do_file = (fn, path, backends) ->
  prefix = fn\sub(1,1)
  errors = ""
  errlangs = ""
  for backend in *backends
    lang = BACKEND_SHORTNAMES[backend]
    outfn = "#{SHADER_DIR}/#{lang}/#{fn\sub(1,-4)}.bin"
    cmd = make_cmd prefix, backend, path, outfn
    res = do_cmd cmd
    if #res > 2
      errors ..= (header lang, 80, '-') .. "\n" .. res
      errlangs ..= " " .. lang
  if #errors > 0
    errors, errlangs
  else
    nil, nil

concat = (t) ->
  table.concat ["#{header(k)}\n#{v}" for k,v in pairs t], "\n"

stdout_print = (_, text, fg, bg) ->
  print(text)

finish = -> if app.finish then app\finish!

export init = ->
  args = argparse.parse!
  app = if args['--repl'] 
    app = mc.ConsoleApp {title: 'Shader Compiler'}
  else
    {print: stdout_print, update: ->, clear: ->, finish: truss.quit}

  backends = if args['--backend']
    p = args['--backend']\lower()
    BACKEND_SETS[p] or {p}
  else
    BACKEND_SETS[truss.os\lower()]

  async.run ->
    app\clear!
    app\print "Compiling shaders (#{table.concat backends, " "}):"
    errors = {}
    total_errors = 0
    shader_dirs = if args['-i']
      {"#{SHADER_DIR}/raw/#{args['-i']}"}
    else
      find_shader_dirs "#{SHADER_DIR}/raw"
    for dir in *shader_dirs
      loose_shaders = find_loose_shaders dir
      if #loose_shaders == 0 then continue
      app\print dir
      nerrs, nshaders = 0, 0
      for {fn, path} in *loose_shaders
        errors[fn], errlangs = do_file fn, path, backends
        if errors[fn]
          app\print "#{CHARS.vert}!#{fn} -> #{errlangs}"
          nerrs += 1
        elseif args['-v']
          app\print "#{CHARS.vert} #{fn}"
        nshaders += 1
        async.await_frames 1
      app\print "#{CHARS.term} #{nshaders - nerrs} / #{nshaders}"
      total_errors += nerrs
    app\print "Done."
    errstr = (concat errors, '\n')
    if total_errors > 0
      if args['-o']
        app\print "Errors during compilation; see #{args['-o']}"
        truss.save_string args['-o'], errstr
      else
        app\print "Errors during shader compilation: "
        app\print errstr
    else
      app\print "All shaders compiled successfully."
    finish!

export update = ->
  async\update!
  app\update!