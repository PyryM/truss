-- bootstrap script

-- Link in truss api
trss = terralib.includecstring([[
#define TRSS_MESSAGE_UNKNOWN 0
#define TRSS_MESSAGE_CSTR 1
#define TRSS_MESSAGE_BLOB 2
typedef struct {
	unsigned int message_type;
	unsigned int data_length;
	unsigned char* data;
	unsigned int _refcount;
} trss_message;
typedef struct Addon Addon;
#define TRSS_LOG_CRITICAL 0
#define TRSS_LOG_ERROR 1
#define TRSS_LOG_WARNING 2
#define TRSS_LOG_INFO 3
#define TRSS_LOG_DEBUG 4
void trss_test();
void trss_log(int log_level, const char* str);
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
trss.trss_log(0, "Bootstrapping.")

ffi = require("ffi")

local numAddons = trss.trss_get_addon_count(0)
trss.trss_log(0, "Found " .. numAddons .. " addons.")

local sdlheader = ffi.string(trss.trss_get_addon_header(0, 0))
trss.trss_log(0, "SDL header: [" .. sdlheader .. "]")

sdlPointer = trss.trss_get_addon(0, 0)
sdl = terralib.includecstring(sdlheader)

bgfx = terralib.includec("include/bgfx/bgfx.c99.h")

width = 800
height = 600

globals = {frame = 0, x = 0, y = 0}

function initBGFX()
	local debug = 0x08 --bgfx_constants.BGFX_DEBUG_TEXT
	local reset = 0x80 --bgfx_constants.BGFX_RESET_VSYNC

	bgfx.bgfx_init(7, 0, 0, nil, nil)
	bgfx.bgfx_reset(width, height, reset)

	-- Enable debug text.
	bgfx.bgfx_set_debug(debug)

	bgfx.bgfx_set_view_clear(0, 
	0x0001 + 0x0002, -- clear color + clear depth
	0x303030ff,
	1.0,
	0)

	trss.trss_log(0, "Initted bgfx I hope?")
end

function updateEvents()
	local nevents = sdl.trss_sdl_num_events(sdlPointer)
	for i = 1,nevents do
		local evt = sdl.trss_sdl_get_event(sdlPointer, i-1)
		if evt.event_type == sdl.TRSS_SDL_EVENT_MOUSEMOVE then
			globals.x = evt.x
			globals.y = evt.y
		elseif evt.event_type == sdl.TRSS_SDL_EVENT_WINDOW and evt.flags == 14 then
			trss.trss_log(0, "Received window close, stopping interpreter...")
			trss.trss_stop_interpreter(0)
		end
	end
end

function updateBGFX()
	-- Set view 0 default viewport.
	bgfx.bgfx_set_view_rect(0, 0, 0, width, height);

	-- This dummy draw call is here to make sure that view 0 is cleared
	-- if no other draw calls are submitted to view 0.
	bgfx.bgfx_submit(0, 0);

	-- Use debug font to print information about this example.
	bgfx.bgfx_dbg_text_clear(0, false);

	bgfx.bgfx_dbg_text_printf(0, 1, 0x4f, "scripts/core/bootstrap.t");
	bgfx.bgfx_dbg_text_printf(0, 2, 0x6f, "(frame " .. globals.frame .. ")");
	bgfx.bgfx_dbg_text_printf(0, 3, 0x6f, "x: " .. globals.x .. ", y: " .. globals.y);

	-- Advance to next frame. Rendering thread will be kicked to
	-- process submitted rendering primitives.
	bgfx.bgfx_frame();
end

function _coreInit(argstring)
	trss.trss_log(0, "Core init called with string: [" .. argstring .. "]")
	sdl.trss_sdl_create_window(sdlPointer, width, height, 'TRUSS TEST')
	initBGFX()
	local rendererType = bgfx.bgfx_get_renderer_type()
	local rendererName = ffi.string(bgfx.bgfx_get_renderer_name(rendererType))
	trss.trss_log(0, "Renderer type: " .. rendererName)
end

function _coreUpdate()
	globals.frame = globals.frame + 1
	updateEvents()
	updateBGFX()

	-- Just stop the interpreter
	-- trss.trss_log(0, "Stopping interpreter.")
	-- trss.trss_stop_interpreter(0)
end