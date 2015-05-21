-- bootstrap script

-- first, copy whatever we have in the global environment
local lsubenv = {}
for k,v in pairs(_G) do
	lsubenv[k] = v
end

-- Link in truss api
trss = terralib.includecstring([[
#include <stdint.h>
#define TRSS_MESSAGE_UNKNOWN 0
#define TRSS_MESSAGE_CSTR 1
#define TRSS_MESSAGE_BLOB 2
typedef struct {
	unsigned int message_type;
	unsigned int data_length;
	unsigned char* data;
	unsigned int refcount;
} trss_message;
typedef struct Addon Addon;
#define TRSS_LOG_CRITICAL 0
#define TRSS_LOG_ERROR 1
#define TRSS_LOG_WARNING 2
#define TRSS_LOG_INFO 3
#define TRSS_LOG_DEBUG 4
const char* trss_get_version_string();
void trss_test();
void trss_log(int log_level, const char* str);
void trss_shutdown();
uint64_t trss_get_hp_time();
uint64_t trss_get_hp_freq();
#define TRSS_ASSET_PATH 0 /* Path where assets are stored */
#define TRSS_SAVE_PATH 1  /* Path for saving stuff e.g. preferences */
#define TRSS_CORE_PATH 2  /* Path for core files e.g. bootstrap.t */
trss_message* trss_load_file(const char* filename, int path_type);
int trss_save_file(const char* filename, int path_type, trss_message* data);
typedef int trss_interpreter_id;
int trss_spawn_interpreter(const char* name, trss_message* arg_message);
void trss_stop_interpreter(trss_interpreter_id target_id);
void trss_execute_interpreter(trss_interpreter_id target_id);
int trss_find_interpreter(const char* name);
int trss_get_addon_count(trss_interpreter_id target_id);
Addon* trss_get_addon(trss_interpreter_id target_id, int addon_idx);
const char* trss_get_addon_name(trss_interpreter_id target_id, int addon_idx);
const char* trss_get_addon_header(trss_interpreter_id target_id, int addon_idx);
void trss_send_message(trss_interpreter_id dest, trss_message* message);
int trss_fetch_messages(trss_interpreter_id interpreter);
trss_message* trss_get_message(trss_interpreter_id interpreter, int message_index);
trss_message* trss_create_message(unsigned int data_length);
void trss_acquire_message(trss_message* msg);
void trss_release_message(trss_message* msg);
trss_message* trss_copy_message(trss_message* src);
]])

trss.trss_test()
trss.trss_log(TRSS_INTERPRETER_ID, "Bootstrapping [" .. TRSS_INTERPRETER_ID .. "]")
local TRSS_ID = TRSS_INTERPRETER_ID

ffi = require("ffi")

terra_ticStartTime = global(uint64, 0)

tic = trss.trss_get_hp_time

terra toc(startTime: uint64)
	var curtime = trss.trss_get_hp_time()
	var freq = trss.trss_get_hp_freq()
	var deltaF : float = curtime - startTime
	return deltaF / [float](freq)
end

function loadStringFromFile(filename)
	local temp = trss.trss_load_file(filename, 0)
	if temp ~= nil then
		local ret = ffi.string(temp.data, temp.data_length)
		return ret
	else
		trss.trss_log(0, "Unable to load " .. filename)
		return nil
	end
end

loadedLibs = {}
function truss_import(filename)
	if loadedLibs[filename] == nil then
		loadedLibs[filename] = {} -- prevent possible infinite recursion by a module trying to import itself
		local t0 = tic()
		local modulefunc = terralib.loadstring(loadStringFromFile("scripts/" .. filename))
		loadedLibs[filename] = modulefunc()
		local dt = toc(t0) * 1000.0
		trss.trss_log(0, "Loaded library [" .. filename .. "] in " .. dt .. " ms")
	end
	return loadedLibs[filename]
end

local numAddons = trss.trss_get_addon_count(TRSS_ID)
trss.trss_log(TRSS_ID, "Found " .. numAddons .. " addons.")

local sdlheader = ffi.string(trss.trss_get_addon_header(TRSS_ID, 0))
trss.trss_log(TRSS_ID, "SDL header: [" .. sdlheader .. "]")

sdlPointer = trss.trss_get_addon(TRSS_ID, 0)
sdl = terralib.includecstring(sdlheader)

nanovg = terralib.includec("include/nanovg_terra.h")

bgfx = terralib.includec("include/bgfx_truss.c99.h")
terralib.loadstring(loadStringFromFile("scripts/bgfx_constants.t"))()

local vstr = ffi.string(trss.trss_get_version_string())

libs = {}
libs.bgfx = bgfx
libs.bgfx_const = bgfx_const
libs.sdl = sdl
libs.trss = trss
libs.TRSS_ID = TRSS_ID
libs.sdlPointer = sdlPointer
libs.terralib = terralib
libs.nanovg = nanovg
libs.TRSS_VERSION = vstr

subenv = lsubenv
subenv.libs = libs
subenv.ffi = ffi
subenv.truss_import = truss_import
subenv.tic = tic
subenv.toc = toc

function _coreInit(argstring)
	-- Load in argstring
	local t0 = tic()
	local fn = "scripts/" .. argstring
	trss.trss_log(TRSS_ID, "Loading " .. fn)
	local script = loadStringFromFile(fn)
	local scriptfunc = terralib.loadstring(script)
	setfenv(scriptfunc, subenv)
	scriptfunc()
	subenv.init()	
	local delta = toc(t0)
	trss.trss_log(0, "Time to init: " .. delta)
end

function _coreUpdate()
	subenv.update()
end