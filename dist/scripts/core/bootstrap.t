-- bootstrap script

-- Have terra include path include the *fake* std so systems without
-- dev tools can still run it
terralib.includepath = "include;include/compat"

-- Link in truss api
local ctruss = terralib.includecstring([[
#include <stdint.h>
#include <stddef.h>

#define truss_message_UNKNOWN 0
#define truss_message_CSTR    1
#define truss_message_BLOB    2

#define TRUSS_LOG_CRITICAL    0
#define TRUSS_LOG_ERROR       1
#define TRUSS_LOG_WARNING     2
#define TRUSS_LOG_INFO        3
#define TRUSS_LOG_DEBUG       4

typedef struct {
    unsigned int message_type;
    size_t data_length;
    unsigned char* data;
    unsigned int refcount;
} truss_message;
typedef struct Addon Addon;

const char* truss_get_version();
void truss_test();
void truss_log(int log_level, const char* str);
void truss_shutdown();
uint64_t truss_get_hp_time();
uint64_t truss_get_hp_freq();
int truss_check_file(const char* filename);
truss_message* truss_load_file(const char* filename);
int truss_save_file(const char* filename, truss_message* data);
int truss_save_data(const char* filename, const char* data, unsigned int datalength);
int truss_add_fs_path(const char* path, const char* mountpath, int append);
int truss_set_fs_savedir(const char* path);
truss_message* truss_get_store_value(const char* key);
int truss_set_store_value(const char* key, truss_message* val);
int truss_set_store_value_str(const char* key, const char* msg);
typedef int truss_interpreter_id;
int truss_spawn_interpreter(const char* name, truss_message* arg_message);
void truss_stop_interpreter(truss_interpreter_id target_id);
void truss_execute_interpreter(truss_interpreter_id target_id);
int truss_find_interpreter(const char* name);
int truss_get_addon_count(truss_interpreter_id target_id);
Addon* truss_get_addon(truss_interpreter_id target_id, int addon_idx);
const char* truss_get_addon_name(truss_interpreter_id target_id, int addon_idx);
const char* truss_get_addon_header(truss_interpreter_id target_id, int addon_idx);
const char* truss_get_addon_version(truss_interpreter_id target_id, int addon_idx);
void truss_send_message(truss_interpreter_id dest, truss_message* message);
int truss_fetch_messages(truss_interpreter_id interpreter);
truss_message* truss_get_message(truss_interpreter_id interpreter, int message_index);
truss_message* truss_create_message(size_t data_length);
void truss_acquire_message(truss_message* msg);
void truss_release_message(truss_message* msg);
truss_message* truss_copy_message(truss_message* src);
]])

-- strip truss_ from ctruss function names, put into truss table
truss = {}
truss.CRaw = ctruss
truss.C = {}
for k,v in pairs(ctruss) do
    if k:sub(1,6):lower() == "truss_" then
        local shortenedName = k:sub(7,-1)
        truss.C[shortenedName] = v
    end
end
truss.C.Message = truss.C.message -- eh

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

-- from luajit
ffi = require("ffi")
bit = require("bit")

truss.tic = truss.C.get_hp_time

-- local lua_error = error
-- function truss.error(msg)
--     log.critical(msg)
--     truss.errorTrace = debug.traceback()
--     lua_error(msg, 2)
-- end
-- error = truss.error
truss.error = error

terra truss.toc(startTime: uint64)
    var curtime = truss.C.get_hp_time()
    var freq = truss.C.get_hp_freq()
    var deltaF : float = curtime - startTime
    return deltaF / [float](freq)
end

function truss.quit()
    truss.C.stop_interpreter(TRUSS_ID)
end

function truss.loadStringFromFile(filename)
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
function truss.loadScriptFromFile(filename)
    local s = truss.loadStringFromFile(filename)
    if s then return s:gsub("\r", "") else return nil end
end

local function makeindent(n)
    if n == 0 then return "" end
    local ret = ">"
    for i = 1,n do ret = "=" .. ret end
    return ret
end

-- terralib.loadstring does not take a name parameter (which is needed
-- to get reasonable error messages), so we have to perform this workaround
-- to use the lower-level terralib.load which does take a name
function truss.loadNamedString(str, strname)
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

local loadedLibs = {}
truss.loadedLibs = loadedLibs
local requireNestLevel = 0
local _requirePrefixPath = ""
function truss.require(filename, force)
    if loadedLibs[filename] == nil or force then
        log.info("Starting to load [" .. filename .. "]")
        local oldmodule = loadedLibs[filename] -- only relevant if force==true
        loadedLibs[filename] = {} -- prevent possible infinite recursion by a module trying to require itself

        -- check if the file is actually a directory, in which case we should try to load __init__.t
        local fullpath = "scripts/" .. _requirePrefixPath .. filename
        if truss.C.check_file(fullpath) == 2 then
            fullpath = fullpath .. "/init.t"
            log.info("Required directory; trying to load [" .. fullpath .. "]")
        end

        local t0 = truss.tic()
        local funcsource = truss.loadScriptFromFile(fullpath)
        if funcsource == nil then
            log.error("Error loading library [" .. filename .. "]: file does not exist.")
            loadedLibs[filename] = nil
            return nil
        end
        local modulefunc, loaderror = truss.loadNamedString(funcsource, filename)
        if modulefunc then
            requireNestLevel = requireNestLevel + 1
            loadedLibs[filename] = modulefunc()
            requireNestLevel = requireNestLevel - 1
            local dt = truss.toc(t0) * 1000.0
            log.info(makeindent(requireNestLevel) ..
                            "Loaded library [" .. filename .. "]" ..
                            " in " .. dt .. " ms")
        else
            loadedLibs[filename] = oldmodule
            log.error("Error loading library [" .. filename .. "]: " .. loaderror)
        end
    end
    return loadedLibs[filename]
end

function truss.checkModuleExists(filename)
    if loadedLibs[filename] ~= nil then return true end
    local fullpath = "scripts/" .. _requirePrefixPath .. filename
    return truss.C.check_file(fullpath) ~= 0
end

function truss.requireAs(filename, libname, force)
    log.info("Loading [" .. filename .. "] as [" .. libname .. "]")
    local temp = truss.require(filename, force)
    loadedLibs[libname] = temp
    return temp
end

-- just directly inserts a library
function truss.insertLibrary(libname, libtable)
    loadedLibs[libname] = libtable
end

-- used to require libraries that require files using relative paths
function truss.requireRelative(path, filename)
    local oldprefix = _requirePrefixPath
    _requirePrefixPath = path
    local ret = truss.require(filename)
    _requirePrefixPath = oldprefix
    return ret
end

-- alias ffi and bit in case somebody tries to require them
truss.insertLibrary("ffi", ffi)
truss.insertLibrary("bit", bit)

-- alias core/30log.lua to class so we can just require("class")
truss.requireAs("core/30log.lua", "class")

local numAddons = truss.C.get_addon_count(TRUSS_ID)
log.info("Found " .. numAddons .. " addons.")

local addons = {}
local raw_addons = {}

for addonIdx = 1,numAddons do
    local addonHeader = ffi.string(truss.C.get_addon_header(TRUSS_ID, addonIdx-1))
    local addonPointer = truss.C.get_addon(TRUSS_ID, addonIdx-1)
    local addonName = ffi.string(truss.C.get_addon_name(TRUSS_ID, addonIdx-1))
    local addonVersion = ffi.string(truss.C.get_addon_version(TRUSS_ID, addonIdx-1))
    log.info("Loading addon [" .. addonName .. "]")
    local addonTable = terralib.includecstring(addonHeader)
    raw_addons[addonName] = {functions = addonTable, pointer = addonPointer, version = addonVersion}
    if truss.checkModuleExists("addons/" .. addonName .. ".t") then
        local addonwrapper = truss.require("addons/" .. addonName .. ".t")
        addonTable = addonwrapper.wrap(addonName, addonTable, addonPointer, addonVersion)
    else
        log.warn("Warning: no wrapper found for addon [" .. addonName .. "]")
    end
    addons[addonName] = addonTable
end
truss.addons = addons
truss.rawAddons = raw_addons

local vstr = ffi.string(truss.C.get_version())
truss.VERSION = vstr

-- these are important enough to just be dumped into the global namespace
bgfx = terralib.includec("bgfx_truss.c99.h")
bgfx_const = truss.require("bgfx_constants.t")
nanovg = terralib.includec("nanovg_terra.h")

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

local function loadAndRun(fn)
    local script = truss.loadScriptFromFile(fn)
    local scriptfunc, loaderror = truss.loadNamedString(script, fn)
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
        truss.quit()
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
