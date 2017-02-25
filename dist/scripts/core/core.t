-- core.t
-- defines truss library functions, imports bgfx, sets up require system

-- add our compatibility C standard library headers so systems without
-- dev tools can still use truss (e.g., windows without VS installed)
terralib.includepath = "include;include/compat"

-- Link in truss api
local ctruss = terralib.includec("truss_api.h")

-- strip truss_ from ctruss function names, put into truss table
-- (note, this is essentially the same function as in core/module.t,
-- but we haven't set up `require` yet)
truss = {}
truss.C_raw = ctruss
truss.C = {}
for k,v in pairs(ctruss) do
  if k:sub(1,6):lower() == "truss_" then
    local shortenedName = k:sub(7,-1)
    truss.C[shortenedName] = v
  end
end
truss.C.Message = truss.C.message -- style is Capitalized class/struct names

truss.C.test()
truss.C.log(truss.C.LOG_INFO, "Bootstrapping [" .. TRUSS_INTERPRETER_ID .. "]")
local TRUSS_ID = TRUSS_INTERPRETER_ID
truss.TRUSS_ID = TRUSS_ID

-- let log be a global because it's inconvenient to have to do truss.log
log = {}
log.debug = function(msg) ctruss.truss_log(4, tostring(msg)) end
log.info = function(msg) ctruss.truss_log(3, tostring(msg)) end
log.warn = function(msg) ctruss.truss_log(2, tostring(msg)) end
log.warning = log.warn
log.error = function(msg) ctruss.truss_log(1, tostring(msg)) end
log.critical = function(msg) ctruss.truss_log(0, tostring(msg)) end
truss.log = log

-- use default lua error handling
truss.error = error

-- from luajit
ffi = require("ffi")
bit = require("bit")

-- timing functions
-- local t0 = tic()
-- local dt = toc(t0) -- dt is elapsed seconds as a float
truss.tic = truss.C.get_hp_time
terra truss.toc(startTime: uint64)
  var curtime = truss.C.get_hp_time()
  var freq = truss.C.get_hp_freq()
  var deltaF : float = curtime - startTime
  return deltaF / [float](freq)
end

-- register a function to be called right before truss quits
-- (e.g., openvr cleanup)
truss._cleanup_functions = {}
function truss.on_quit(f)
  truss._cleanup_functions[f] = f
end

-- gracefully quit truss with an optional error code
function truss.quit(code)
  for _, f in pairs(truss._cleanup_functions) do f() end
  if code and type(code) == "number" then
    truss.C.set_error(code)
    log.info("Error code: [" .. tostring(code) .. "]")
  end
  truss.C.stop_interpreter(TRUSS_ID)
end

-- load an entire file into memory as a string (8-bit clean)
function truss.load_string_from_file(filename)
  local temp = truss.C.load_file(filename)
  if temp ~= nil then
    local ret = ffi.string(temp.data, temp.data_length)
    truss.C.release_message(temp)
    return ret
  else
    log.error("Unable to load " .. filename)
    return nil
  end
end

-- terra has issues with line numbering with dos line endings (\r\n), so
-- this function loads a string and then gets rid of carriage returns (\r)
function truss.load_script_from_file(filename)
  local s = truss.load_string_from_file(filename)
  if s then return s:gsub("\r", "") else return nil end
end

-- terralib.loadstring does not take a name parameter (which is needed
-- to get reasonable error messages), so we have to perform this workaround
-- to use the lower-level terralib.load which does take a name
function truss.load_named_string(str, strname)
  -- create a function which returns str on the first call
  -- and nil on the second (to let terralib.load know it is done)
  local s = str
  local loaderfunc = function()
    local s2 = s
    s = nil
    return s2
  end
  return terralib.load(loaderfunc, strname)
end

local function extend_table(dest, addition)
  for k,v in pairs(addition) do dest[k] = v end
  return dest
end
truss.extend_table = extend_table

truss._module_env = extend_table({}, _G)
local disallow_globals_mt = {
  __newindex = function (t,k,v)
    truss.error("Module tried to create global '" .. k .. "'")
  end,
  __index = function (t,k)
    truss.error("Module tried to access nil global '" .. k .. "'")
  end
}

local function create_module_env()
  local modenv = extend_table({}, truss._module_env)
  setmetatable(modenv, disallow_globals_mt)
  return modenv
end

-- require a module
-- unlike the built-in `require`, truss.require uses / as the path separator
-- and needs the file extension (e.g., require("core/module.t"))
-- if no file extension is present and the path is a directory, then truss
-- tries to load dir/init.t
local loaded_libs = {}
truss._loaded_libs = loaded_libs
local require_prefix_path = ""
function truss.require(filename, force)
  if loaded_libs[filename] == false then
    truss.error("require [" .. filename .. "] : cyclical require")
    return nil
  end
  if loaded_libs[filename] == nil or force then
    local oldmodule = loaded_libs[filename] -- only relevant if force==true
    loaded_libs[filename] = false -- prevent possible infinite recursion

    -- if the filename is actually a directory, try to load init.t
    local fullpath = "scripts/" .. require_prefix_path .. filename
    if truss.C.check_file(fullpath) == 2 then
      fullpath = fullpath .. "/init.t"
      log.info("Required directory; trying to load [" .. fullpath .. "]")
    end

    local t0 = truss.tic()
    local funcsource = truss.load_script_from_file(fullpath)
    if not funcsource then
      truss.error("require [" .. filename .. "]: file does not exist.")
      return nil
    end
    local module_def, loaderror = truss.load_named_string(funcsource, filename)
    if not module_def then
      truss.error("require [" .. filename .. "]: syntax error: " .. loaderror)
      return nil
    end
    setfenv(module_def, create_module_env())
    loaded_libs[filename] = module_def()
    log.info(string.format("Loaded [%s] in %.2f ms",
                          filename, truss.toc(t0) * 1000.0))
  end
  return loaded_libs[filename]
end
truss._module_env.require = truss.require

function truss.check_module_exists(filename)
  if loaded_libs[filename] then return true end
  local fullpath = "scripts/" .. require_prefix_path .. filename
  return truss.C.check_file(fullpath) ~= 0
end

function truss.require_as(filename, libname, force)
  log.info("Loading [" .. filename .. "] as [" .. libname .. "]")
  local temp = truss.require(filename, force)
  loaded_libs[libname] = temp
  return temp
end

-- just directly inserts a module
function truss.insert_module(libname, libtable)
  loaded_libs[libname] = libtable
end

-- used to require libraries that require files using relative paths
function truss.require_relative(path, filename)
  local oldprefix = require_prefix_path
  require_prefix_path = path
  local ret = truss.require(filename)
  require_prefix_path = oldprefix
  return ret
end

-- alias ffi and bit in case somebody tries to require them
truss.insert_module("ffi", ffi)
truss.insert_module("bit", bit)

-- alias core/30log.lua to class so we can just require("class")
truss.require_as("core/30log.lua", "class")

local numaddons = truss.C.get_addon_count(TRUSS_ID)
log.info("Found " .. numaddons .. " addons.")

local addons = {}

for addonIdx = 1,numaddons do
  local header = ffi.string(truss.C.get_addon_header(TRUSS_ID, addonIdx-1))
  local pointer = truss.C.get_addon(TRUSS_ID, addonIdx-1)
  local addon_name = ffi.string(truss.C.get_addon_name(TRUSS_ID, addonIdx-1))
  local addon_version = ffi.string(truss.C.get_addon_version(TRUSS_ID, addonIdx-1))
  log.info("Loading addon [" .. addon_name .. "]")
  local addon_table = terralib.includecstring(header)
  addons[addon_name] = {functions = addon_table, pointer = pointer,
                        version = addon_version}
end
truss.addons = addons

local vstr = ffi.string(truss.C.get_version())
truss.VERSION = vstr

-- do some name mangling on bgfx to avoid awkward constructs like
-- bgfx.bgfx_do_something(bgfx.BGFX_SOME_CONSTANT)
local bgfx_c = terralib.includec("bgfx_truss.c99.h")
local bgfx_const = truss.require("core/bgfx_constants.t")

bgfx = {}
local modutils = truss.require("core/module.t")
modutils.reexport_without_prefix(bgfx_c, "bgfx_", bgfx)
modutils.reexport_without_prefix(bgfx_c, "BGFX_", bgfx)
modutils.reexport_without_prefix(bgfx_const, "BGFX_", bgfx)
bgfx.raw_functions = bgfx_c
bgfx.raw_constants = bgfx_const
function bgfx.check_handle(h) return h.idx ~= bgfx.INVALID_HANDLE end

modutils.reexport(truss.require("core/memory.t"), truss)

-- replace lua require with truss require
lua_require = require
require = truss.require

-- read out command line arguments into a convenient table
truss.args = {}
local idx = 0
while true do
  local argname = "arg" .. idx
  local argval = truss.C.get_store_value(argname)
  if argval == nil then break end
  local argstr = ffi.string(argval.data, argval.data_length)
  log.debug(argname .. ": " .. argstr)
  table.insert(truss.args, argstr)
  idx = idx + 1
end
log.debug("Loaded " .. idx .. " args.")

-- mount command line argument paths into physfs
local function add_paths()
  local nargs = #(truss.args)
  for i = 3,nargs do
    if truss.args[i] == "--addpath" and i+2 <= nargs then
      local physicalPath = truss.args[i+1]
      local mountPath = truss.args[i+2]
      log.info("Adding path " .. physicalPath ..
       " => " .. mountPath)
      truss.C.add_fs_path(physicalPath,
        mountPath,
        0)
    end
  end
end

-- create some environments
truss.clean_subenv = extend_table({},  _G)
truss.mainenv = extend_table({}, _G)
extend_table(truss._module_env, _G)

local function load_and_run(fn)
  local script = truss.load_script_from_file(fn)
  if script == nil then
    error("File [" .. fn .. "] does not exist or other IO error.")
    return
  end
  local scriptfunc, loaderror = truss.load_named_string(script, fn)
  if scriptfunc == nil then
    error("Main script loading error: " .. loaderror)
    return
  end
  setfenv(scriptfunc, truss.mainenv)
  truss.mainobj = scriptfunc() or truss.mainenv
  truss.mainobj:init()
end

local function error_handler(err)
  log.critical(err)
  truss.error_trace = debug.traceback(err, 3)
  return err
end

-- These functions have to be global because
function _core_init(argstring)
  -- Set paths from command line arguments
  add_paths()
  -- Load in argstring
  local t0 = truss.tic()
  local fn = argstring
  log.info("Loading " .. fn)
  local happy, errmsg = xpcall(load_and_run, error_handler, fn)
  if not happy then
    truss.enter_error_state(errmsg)
  end
  local delta = truss.toc(t0) * 1000.0
  log.info(string.format("Time to init: %.2f ms", delta))
end

function _core_update()
  local happy, errmsg = xpcall(truss.mainobj.update, error_handler, truss.mainobj)
  if not happy then
    truss.enter_error_state(errmsg)
  end
end

function _fallback_update()
  truss.mainobj:fallback_update()
end

_resume_update = _core_update
function truss.enter_error_state(errmsg)
  log.warn("Entering error state: " .. errmsg)
  truss.crash_message = errmsg
  if truss.mainobj and truss.mainobj.fallback_update then
    _resume_update = _core_update
    _core_update = _fallback_update
  else
    log.info("No fallback update function present; quitting.")
    local tstr = "Traceback: " .. tostring(truss.error_trace)
    print("Runtime error. See trusslog.txt for details.")
    print(tstr)
    log.info(tstr)
    truss.quit(2001)
  end
end

function truss.resume_from_error()
  log.info("Attempting to resume from an error")
  if _resume_update then
    _core_update = _resume_update
  else
    log.warn("Cannot resume; no resume update function set.")
  end
end
