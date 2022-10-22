local sutil = require "util/string.t"
local argparse = require "util/argparse.t"
local term = require "term"
local fs = require "fs"

local function is_loose_shader(entry)
  if not entry.ospath then return false end -- archived
  if not entry.is_file then return false end
  local fn = entry.file
  return (truss.file_extension(fn) == "sc") and (fn ~= "varying.def.sc")
end

local function find_loose_shaders(dir, workdir_only)
  local shaders = {}
  local skipped = 0
  for _, entry in ipairs(truss.list_dir(dir)) do
    if is_loose_shader(entry) then 
      if (not workdir_only) or entry.mountroot:find(truss.working_dir) then
        table.insert(shaders, entry) 
      else
        skipped = skipped + 1
      end
    end
  end
  return shaders, skipped
end

local function find_shader_dirs(rootdir)
  local dirs = {}
  for _, entry in ipairs(truss.list_dir(rootdir)) do
    if entry.ospath and (not entry.is_file) then
      table.insert(dirs, entry.path)
    end
  end
  return dirs
end

local function extend_list(target, additions)
  for _, v in ipairs(additions) do table.insert(target, v) end
  return target
end

local SHADER_DIR = "shaders"
local DX_SHADER_TYPES = {
  f = "ps_4_0",
  v = "vs_4_0",
  c = "cs_5_0",
}

local BACKEND_SHORTNAMES = {
  directx = "dx11",
  dx11 = "dx11",
  dx12 = "dx11",
  opengl = "glsl",
  metal = "mtl",
  vulkan = "spirv",
  opengles = "essl",
}

local BACKEND_TO_BGFX_PLATFORM = {
  directx = "windows",
  dx11 = "windows",
  dx12 = "windows",
  opengl = "linux",
  vulkan = "linux",
  metal = "osx",
  opengles = "asm.js", -- yes, really
}

local BACKEND_SETS = {
  windows = {"directx", "vulkan"},
  windows_all = {"directx", "vulkan", "metal", "opengl", "opengles"},
  osx = {"metal"},
  osx_all = {"metal", "vulkan", "opengl", "opengles"},
  linux = {"vulkan"},
  linux_all = {"vulkan", "opengl", "opengles"},
  web = {"opengles", "vulkan"},
}

-- assume everyone has unicode these days
local CHARS = {vert = "│", term = "└"}

local BINPATH = truss.joinpath(truss.rootdir, "/bin/shadercRelease")
local INCLUDEPATH = truss.joinpath(truss.rootdir, "/include/bgfx/shader/")

log.info("shaderc path:", BINPATH)
log.info("shader include path:", INCLUDEPATH)

local function guard_path(s)
  -- shaderc does not like it if the includepath features a trailing slash
  local lastchar = s:sub(-1,-1)
  if lastchar == "/" or lastchar == "\\" then
    s = s:sub(1,-2)
  end
  if s:find(" ") then 
    return '"' .. s .. '"' 
  else 
    return s 
  end
end

local function make_cmd(shader_type, backend, input_fn, output_fn)
  local binname = BINPATH
  if jit.os ~= "Windows" then
    -- this is an absolute path, probably?
    binname = "/" .. BINPATH
  end
  binname = guard_path(binname)
  local args = { binname }
  extend_list(args, {
    "-f", guard_path(input_fn), 
    "-o", guard_path(output_fn),
    "--type", shader_type,
    "-i", guard_path(INCLUDEPATH),
    "--platform", BACKEND_TO_BGFX_PLATFORM[backend]
  })
  if backend == "opengl" then
    extend_list(args, {"-p", "140"})
  elseif backend == "opengles" then
    extend_list(args, {"-p", "100_es"})
  elseif backend == "directx" or backend == "dx11" or  backend == "dx12" then
    extend_list(args, {"-p", DX_SHADER_TYPES[shader_type], 
       "-O", "3"})
  elseif backend == "metal" then
    extend_list(args, {"-p", "metal"})
  elseif backend == "vulkan" then
    extend_list(args, {"-p", "spirv"})
  end
  extend_list(args, {"2>&1"})
  local cmdstr = table.concat(args, " ")
  if jit.os == "Windows" then
    -- yes, this is another outer level of quotes, but it's needed in Windows
    -- for reasons I assure you
    cmdstr = '"' .. cmdstr .. '"'
  end
  return cmdstr
end

local function do_cmd(cmd)
  log.debug("subprocess:", cmd)
  local f = io.popen(cmd, 'r')
  local s = f:read('*a')
  f:close()
  return s
end

local function header(s, n, char)
  n = (n or 80) - (#s + 2)
  char = char or "="
  local pre = math.floor(n / 2)
  local post = n - pre
  return ("%s %s %s"):format(char:rep(pre), s, char:rep(post))
end

local function make_outdirs(backends)
  local made_dirs = {}
  for _, backend in ipairs(backends) do
    local lang = BACKEND_SHORTNAMES[backend]
    local outdir = truss.joinpath(SHADER_DIR, lang)
    if not made_dirs[outdir] then
      log.info("Creating directory:", outdir)
      fs.recursive_makedir(outdir)
      made_dirs[outdir] = true
    end
  end
end

local function do_file(fn, path, backends)
  local prefix = fn:sub(1,1)
  local errors = ""
  local errlangs = ""
  for _, backend in ipairs(backends) do
    local lang = BACKEND_SHORTNAMES[backend]
    local outfn = truss.joinpath(SHADER_DIR, lang, fn:sub(1,-4)..".bin")
    local cmd = make_cmd(prefix, backend, path, outfn)
    local res = do_cmd(cmd)
    if #res > 2 then
      errors = errors .. header(lang, 80, '-') .. "\n" .. res
      errlangs = errlangs .. " " .. lang
    end
  end
  if #errors > 0 then
    return errors, errlangs
  end
end

local function concat(t)
  local frags = {}
  for k, v in pairs(t) do
    table.insert(frags, header(k) .. "\n" .. v)
  end
  return table.concat(frags, "\n")
end

local function colored(color, text)
  return term.color(term[color:upper()]) .. text .. term.RESET
end

local function init()
  local args = argparse.parse()
  local backends

  if args['--backend'] then
    local p = args['--backend']:lower()
    backends = BACKEND_SETS[p] or {p}
  else
    backends = BACKEND_SETS[jit.os:lower()]
  end

  make_outdirs(backends)

  print("Compiling shaders", table.concat(backends, " "))
  local errors = {}
  local total_errors = 0
  local shader_dirs
  if args['-i'] then
    shader_dirs = {truss.joinpath(SHADER_DIR, "raw", args['-i'])}
  else
    shader_dirs = find_shader_dirs(truss.joinpath(SHADER_DIR, "raw"))
  end
  local skipped_dirs = 0
  for _, dir in ipairs(shader_dirs) do
    local loose_shaders, nskipped = find_loose_shaders(dir, true)
    if #loose_shaders > 0 then
      print(dir)
      local nerrs, nshaders = 0, 0
      for _, entry in ipairs(loose_shaders) do
        local fn = entry.file
        local path = entry.ospath
        local errlangs
        errors[path], errlangs = do_file(fn, path, backends)
        if errors[path] then
          print(CHARS.vert .. path ..  " -> " .. colored("red", errlangs))
          nerrs = nerrs + 1
        elseif args['-v'] then
          print(CHARS.vert .. " " .. fn)
        end
        nshaders = nshaders + 1
      end
      local count_str = (nshaders - nerrs) .. " / " .. nshaders
      if nerrs > 0 then 
        count_str = colored('red', count_str)
      else 
        count_str = colored('green', count_str) 
      end
      if nskipped > 0 then
        local skipstr = ("(%d skipped)"):format(nskipped)
        count_str = count_str .. " " .. colored('cyan', skipstr)
      end
      print(CHARS.term .. " " .. count_str)
      total_errors = total_errors + nerrs
    elseif nskipped > 0 then
      skipped_dirs = skipped_dirs + 1
    end
  end
  if skipped_dirs > 0 then
    print(colored('cyan', skipped_dirs .. " skipped dirs."))
  end
  print("Done.")
  local errstr = concat(errors, '\n')
  if total_errors > 0 then
    if args['-o'] then
      print(colored("red", "Errors during compilation; see " .. args['-o']))
      --truss.save_string args['-o'], errstr
    else
      print(errstr)
      print(colored("red", "^^^ Errors during shader compilation."))
    end
    return 1
  else
    print(colored("green", "All shaders compiled successfully."))
    return 0
  end
end

return {init = init}