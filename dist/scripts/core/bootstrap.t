-- bootstrap script

-- add our compatibility C standard library headers so systems without
-- dev tools can still use truss (e.g., windows without VS installed)
terralib.includepath = "include;include/compat"

-- Link in truss api
local ctruss = terralib.includec("truss_api.h")

-- strip truss_ from ctruss function names, put into truss table
-- (note, this is essentially the same function as in core/module.t,
-- but we haven't set up `require` yet)
truss = {}
truss.CRaw = ctruss
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

-- create a series of indents ====> for showing module load nesting
local function makeindent(n)
  if n == 0 then return "" end
  local ret = ">"
  for i = 1,n do ret = "=" .. ret end
  return ret
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

local loaded_libs = {}
truss._loaded_libs = loaded_libs
local require_nest_level = 0
local require_prefix_path = ""
function truss.require(filename, force)
  if loaded_libs[filename] == nil or force then
    log.info("Starting to load [" .. filename .. "]")
    local oldmodule = loaded_libs[filename] -- only relevant if force==true
    loaded_libs[filename] = {} -- prevent possible infinite recursion

    -- if the filename is actually a directory, try to load init.t
    local fullpath = "scripts/" .. require_prefix_path .. filename
    if truss.C.check_file(fullpath) == 2 then
      fullpath = fullpath .. "/init.t"
      log.info("Required directory; trying to load [" .. fullpath .. "]")
    end

    local t0 = truss.tic()
    local funcsource = truss.load_script_from_file(fullpath)
    if funcsource == nil then
      loaded_libs[filename] = nil
      truss.error("require [" .. filename .. "]: file does not exist.")
      return nil
    end
    local modulefunc, loaderror = truss.load_named_string(funcsource, filename)
    if modulefunc then
      require_nest_level = require_nest_level + 1
      loaded_libs[filename] = modulefunc()
      require_nest_level = require_nest_level - 1
      local dt = truss.toc(t0) * 1000.0
      log.info(makeindent(require_nest_level) ..
        "Loaded library [" .. filename .. "]" ..
        " in " .. dt .. " ms")
    else
      loaded_libs[filename] = oldmodule
      truss.error("require [" .. filename .. "]: " .. loaderror)
    end
  end
  return loaded_libs[filename]
end

function truss.check_module_exists(filename)
  if loaded_libs[filename] ~= nil then return true end
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
local raw_addons = {}

for addonIdx = 1,numaddons do
  local header = ffi.string(truss.C.get_addon_header(TRUSS_ID, addonIdx-1))
  local pointer = truss.C.get_addon(TRUSS_ID, addonIdx-1)
  local addon_name = ffi.string(truss.C.get_addon_name(TRUSS_ID, addonIdx-1))
  local addon_version = ffi.string(truss.C.get_addon_version(TRUSS_ID, addonIdx-1))
  log.info("Loading addon [" .. addon_name .. "]")
  local addon_table = terralib.includecstring(header)
  raw_addons[addon_name] = {functions = addon_table, pointer = pointer, 
                            version = addon_version}
  if truss.check_module_exists("addons/" .. addon_name .. ".t") then
    local wrapper = truss.require("addons/" .. addon_name .. ".t")
    addon_table = wrapper.wrap(addon_name, addon_table, pointer, addon_version)
  else
    log.warn("Warning: no wrapper found for addon [" .. addon_name .. "]")
  end
  addons[addon_name] = addon_table
end
truss.addons = addons
truss.raw_addons = raw_addons

local vstr = ffi.string(truss.C.get_version())
truss.VERSION = vstr

-- do some name mangling on bgfx to avoid awkward constructs like
-- bgfx.bgfx_do_something(bgfx.BGFX_SOME_CONSTANT)
local bgfx_c = terralib.includec("bgfx_truss.c99.h")
local bgfx_const = truss.require("core/bgfx_constants.t")

bgfx = {C = {}}
local modutils = truss.require("core/module.t")
modutils.reexport_without_prefix(bgfx_c, "bgfx_", bgfx.C)
modutils.reexport_without_prefix(bgfx_const, "BGFX_", bgfx.C)
bgfx.raw_functions = bgfx_c
bgfx.raw_constants = bgfx_const

nanovg = terralib.includec("nanovg_terra.h")

-- replace lua require with truss require
lua_require = require
require = truss.require

-- create the subenv that the main script will run in
local subenv = {}
for k,v in pairs(_G) do
  subenv[k] = v
end
truss.mainEnv = subenv

-- create a fresh copy of subenv for modules that need to have
-- a clean-ish sandbox
truss.clean_subenv = {}
for sk,sv in pairs(subenv) do
  truss.clean_subenv[sk] = sv
end

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

--
local function _addPaths()
  local nargs = #(truss.args)
  for i = 3,nargs do
    if execArgs[i] == "--addpath" and i+2 <= nargs then
      local physicalPath = execArgs[i+1]
      local mountPath = execArgs[i+2]
      log.info("Adding path " .. physicalPath ..
       " => " .. mountPath)
      truss.C.add_fs_path(physicalPath,
        mountPath,
        0)
    end
  end
end

local function loadAndRun(fn)
  local script = truss.load_script_from_file(fn)
  local scriptfunc, loaderror = truss.load_named_string(script, fn)
  if scriptfunc == nil then
    error("Main script loading error: " .. loaderror)
    return
  end
  setfenv(scriptfunc, subenv)
  truss.mainObj = scriptfunc() or truss.mainEnv
  truss.mainObj:init()
end

local function errorHandler(err)
  log.critical(err)
  truss.errorTrace = debug.traceback(err, 3)
  return err
end

-- These functions have to be global because
function _coreInit(argstring)
  -- Set paths from command line arguments
  _addPaths()
  -- Load in argstring
  local t0 = truss.tic()
  local fn = argstring
  log.info("Loading " .. fn)
  local happy, errmsg = xpcall(loadAndRun, errorHandler, fn)
  if not happy then
    truss.enterErrorState(errmsg)
  end
  local delta = truss.toc(t0)
  log.info("Time to init: " .. delta)
end

function _coreUpdate()
  local happy, errmsg = xpcall(truss.mainObj.update, errorHandler, truss.mainObj)
  if not happy then
    truss.enterErrorState(errmsg)
  end
end

function _fallbackUpdate()
  truss.mainObj:fallbackUpdate()
end

_resumeUpdate = _coreUpdate
function truss.enterErrorState(errmsg)
  log.warn("Entering error state: " .. errmsg)
  truss.crashMessage = errmsg
  if truss.mainObj and truss.mainObj.fallbackUpdate then
    _resumeUpdate = _coreUpdate
    _coreUpdate = _fallbackUpdate
  else
    log.info("No fallback update function present; quitting.")
    local tstr = "Traceback: " .. tostring(truss.errorTrace)
    print("Runtime error. See trusslog.txt for details.")
    print(tstr)
    log.info(tstr)
    truss.quit(2001)
  end
end

function truss.resumeFromError()
  log.info("Attempting to resume from an error")
  if _resumeUpdate then
    _coreUpdate = _resumeUpdate
  else
    log.warn("Cannot resume; no resume update function set.")
  end
end
