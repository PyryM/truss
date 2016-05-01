-- bootstrap script

-- first, copy whatever we have in the global environment
local lsubenv = {}
for k,v in pairs(_G) do
	lsubenv[k] = v
end

-- Have terra include path include the *fake* std so systems without
-- dev tools can still run it
terralib.includepath = terralib.includepath .. ";include/compat"

-- Link in truss api
truss = terralib.includecstring([[
#include <stdint.h>
#include <stddef.h>

#define TRUSS_MESSAGE_UNKNOWN 0
#define TRUSS_MESSAGE_CSTR 1
#define TRUSS_MESSAGE_BLOB 2
typedef struct {
	unsigned int message_type;
	size_t data_length;
	unsigned char* data;
	unsigned int refcount;
} truss_message;
typedef struct Addon Addon;
#define TRUSS_LOG_CRITICAL 0
#define TRUSS_LOG_ERROR 1
#define TRUSS_LOG_WARNING 2
#define TRUSS_LOG_INFO 3
#define TRUSS_LOG_DEBUG 4
const char* truss_get_version_string();
void truss_test();
void truss_log(int log_level, const char* str);
void truss_shutdown();
uint64_t truss_get_hp_time();
uint64_t truss_get_hp_freq();
int truss_check_file(const char* filename);
truss_message* truss_load_file(const char* filename);
int truss_save_file(const char* filename, truss_message* data);
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
const char* truss_get_addon_version_string(truss_interpreter_id target_id, int addon_idx);
void truss_send_message(truss_interpreter_id dest, truss_message* message);
int truss_fetch_messages(truss_interpreter_id interpreter);
truss_message* truss_get_message(truss_interpreter_id interpreter, int message_index);
truss_message* truss_create_message(size_t data_length);
void truss_acquire_message(truss_message* msg);
void truss_release_message(truss_message* msg);
truss_message* truss_copy_message(truss_message* src);
]])

truss.truss_test()
truss.truss_log(0, "Bootstrapping [" .. TRUSS_INTERPRETER_ID .. "]")
local TRUSS_ID = TRUSS_INTERPRETER_ID

log = {}
log.debug = function(msg) truss.truss_log(4, tostring(msg)) end
log.info = function(msg) truss.truss_log(3, tostring(msg)) end
log.warn = function(msg) truss.truss_log(2, tostring(msg)) end
log.error = function(msg) truss.truss_log(1, tostring(msg)) end
log.critical = function(msg) truss.truss_log(1, tostring(msg)) end

-- from luajit
ffi = require("ffi")
bit = require("bit")

tic = truss.truss_get_hp_time

terra toc(startTime: uint64)
	var curtime = truss.truss_get_hp_time()
	var freq = truss.truss_get_hp_freq()
	var deltaF : float = curtime - startTime
	return deltaF / [float](freq)
end

execArgs = {}
local function readArgs()
	local idx = 0
	while true do
		local argname = "arg" .. idx
		local argval = truss.truss_get_store_value(argname)
		if argval == nil then break end
		local argstr = ffi.string(argval.data, argval.data_length)
		log.debug(argname .. ": " .. argstr)
		table.insert(execArgs, argstr)
		idx = idx + 1
	end
	log.debug("Loaded " .. idx .. " args.")
end

readArgs()

function loadStringFromFile(filename)
	local temp = truss.truss_load_file(filename)
	if temp ~= nil then
		local ret = ffi.string(temp.data, temp.data_length)
		truss.truss_release_message(temp)
		return ret
	else
		log.error("Unable to load " .. filename)
		return nil
	end
end

loadedLibs = {}
local import_nest_level = 0
local function makeindent(n)
	if n == 0 then return "" end
	local ret = ">"
	for i = 1,n do ret = "=" .. ret end
	return ret
end

-- terralib.loadstring does not take a name parameter (which is needed
-- to get reasonable error messages), so we have to perform this workaround
-- to use the lower-level terralib.load which does take a name
local function loadNamed(str, strname)
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

local _requirePrefixPath = ""
function truss_import(filename, force)
	--filename = _requirePrefixPath .. filename
	if loadedLibs[filename] == nil or force then
		log.info("Starting to load [" .. filename .. "]")
		local oldmodule = loadedLibs[filename] -- only relevant if force==true
		loadedLibs[filename] = {} -- prevent possible infinite recursion by a module trying to import itself

		-- check if the file is actually a directory, in which case we should try to load __init__.t
		local fullpath = "scripts/" .. _requirePrefixPath .. filename
		if truss.truss_check_file(fullpath) == 2 then
			fullpath = fullpath .. "/init.t"
			log.info("Required directory; trying to load [" .. fullpath .. "]")
		end

		local t0 = tic()
		local funcsource = loadStringFromFile(fullpath)
		if funcsource == nil then
			log.error("Error loading library [" .. filename .. "]: file does not exist.")
			loadedLibs[filename] = nil
			return nil
		end
		local modulefunc, loaderror = loadNamed(funcsource, filename)
		if modulefunc then
			import_nest_level = import_nest_level + 1
			loadedLibs[filename] = modulefunc()
			import_nest_level = import_nest_level - 1
			local dt = toc(t0) * 1000.0
			log.info(makeindent(import_nest_level) .. 
							"Loaded library [" .. filename .. "]" ..
							" in " .. dt .. " ms")
		else
			loadedLibs[filename] = oldmodule
			log.error("Error loading library [" .. filename .. "]: " .. loaderror)
		end
	end
	return loadedLibs[filename]
end

function truss_import_as(filename, libname, force)
	log.info("Loading [" .. filename .. "] as [" .. libname .. "]")
	local temp = truss_import(filename, force)
	loadedLibs[libname] = temp
	return temp
end

-- just directly inserts a library
function truss_insert_library(libname, libtable)
	loadedLibs[libname] = libtable
end

-- used to import libraries that import files using relative paths
function truss_import_relative(path, filename)
	local oldprefix = _requirePrefixPath
	_requirePrefixPath = path
	local ret = truss_import(filename)
	_requirePrefixPath = oldprefix
	return ret
end

-- alias ffi and bit in case somebody tries to require them
truss_insert_library("ffi", ffi)
truss_insert_library("bit", bit)

-- alias core/30log.lua to class so we can just require("class")
truss_import_as("core/30log.lua", "class")

local numAddons = truss.truss_get_addon_count(TRUSS_ID)
log.info("Found " .. numAddons .. " addons.")

addons = {}
raw_addons = {}

for addonIdx = 1,numAddons do
	local addonHeader = ffi.string(truss.truss_get_addon_header(TRUSS_ID, addonIdx-1))
	local addonPointer = truss.truss_get_addon(TRUSS_ID, addonIdx-1)
	local addonName = ffi.string(truss.truss_get_addon_name(TRUSS_ID, addonIdx-1))
	local addonVersion = ffi.string(truss.truss_get_addon_version_string(TRUSS_ID, addonIdx-1))
	log.info("Loading addon [" .. addonName .. "]")
	local addonwrapper = truss_import("addons/" .. addonName .. ".t")
	local addonTable = terralib.includecstring(addonHeader)

	raw_addons[addonName] = {functions = addonTable, pointer = addonPointer, version = addonVersion}

	if addonwrapper and addonwrapper.wrap then
		addonTable = addonwrapper.wrap(addonName, addonTable, addonPointer, addonVersion)
	else
		log.warn("Warning: no wrapper found for addon [" .. addonName .. "]")
	end

	addons[addonName] = addonTable
end

local vstr = ffi.string(truss.truss_get_version_string())

-- these are important enough to just be dumped into the global namespace
bgfx = terralib.includec("include/bgfx_truss.c99.h")
bgfx_const = truss_import("bgfx_constants.t")
nanovg = terralib.includec("include/nanovg_terra.h")

core = {}
core.truss = truss
core.terralib = terralib
core.bgfx = bgfx
core.bgfx_const = bgfx_const
core.nanovg = nanovg
core.TRUSS_ID = TRUSS_ID
core.TRUSS_VERSION = vstr

subenv = lsubenv
subenv.core = core
subenv.addons = addons
subenv.raw_addons = raw_addons
subenv.ffi = ffi
subenv.bit = bit
subenv.truss_import = truss_import
subenv.truss_import_as = truss_import_as
subenv.require = truss_import
subenv.tic = tic
subenv.toc = toc
subenv.loadStringFromFile = loadStringFromFile
subenv.args = execArgs
subenv.log = log

-- create a fresh copy of subenv for modules that need to have
-- a clean-ish sandbox
clean_subenv = {}
for sk,sv in pairs(subenv) do
	clean_subenv[sk] = sv
end

-- replace terra/lua's require with truss's import mechanism
lua_require = require
require = truss_import

function _addPaths()
	local nargs = #execArgs
	for i = 3,nargs do
		if execArgs[i] == "--addpath" and i+2 <= nargs then
			local physicalPath = execArgs[i+1]
			local mountPath = execArgs[i+2]
			log.info("Adding path " .. physicalPath ..
					 " => " .. mountPath)
			truss.truss_add_fs_path(physicalPath, 
								  mountPath,
								  0)
		end
	end
end

function _coreInit(argstring)
	-- Set paths from command line arguments
	_addPaths()
	-- Load in argstring
	local t0 = tic()
	local fn = "scripts/" .. argstring
	log.info("Loading " .. fn)
	local script = loadStringFromFile(fn)
	local scriptfunc, loaderror = loadNamed(script, argstring)
	if scriptfunc == nil then
		truss.truss_log(0, "Script error: " .. loaderror)
	end
	setfenv(scriptfunc, subenv)
	scriptfunc()
	subenv.init()	
	local delta = toc(t0)
	log.info("Time to init: " .. delta)
end

function _coreUpdate()
	subenv.update()
end