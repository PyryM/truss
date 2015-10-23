#ifndef TRUSS_SDL_HEADER
#define TRUSS_SDL_HEADER

#include <vector>
#include <SDL.h>
#include <SDL_syswm.h>

#include "truss.h"

// tell bgfx that it's using a shared library
#define BGFX_SHARED_LIB_USE 1

#include <c99/bgfx.h>
#include <c99/bgfxplatform.h>

#ifdef __cplusplus
class SDLAddon;
#else
typedef struct SDLAddon SDLAddon;
#endif

#define TRSS_SDL_EVENT_OUTOFBOUNDS  0
#define TRSS_SDL_EVENT_KEYDOWN 		1
#define TRSS_SDL_EVENT_KEYUP		2
#define TRSS_SDL_EVENT_MOUSEDOWN 	3
#define TRSS_SDL_EVENT_MOUSEUP	 	4
#define TRSS_SDL_EVENT_MOUSEMOVE 	5
#define TRSS_SDL_EVENT_MOUSEWHEEL   6
#define TRSS_SDL_EVENT_WINDOW       7
#define TRSS_SDL_EVENT_TEXTINPUT    8

#define TRSS_SDL_MAX_KEYCODE_LENGTH 15 /* should be enough for anybody */
#define TRSS_SDL_KEYCODE_BUFF_SIZE  16 /* extra byte for null terminator */

/* Simplified SDL Event */
typedef struct {
	unsigned int event_type;
	char keycode[TRSS_SDL_KEYCODE_BUFF_SIZE];
	double x;
	double y;
	int flags;
} trss_sdl_event;

TRSS_C_API void trss_sdl_create_window(SDLAddon* addon, int width, int height, const char* name);
TRSS_C_API void trss_sdl_destroy_window(SDLAddon* addon);
TRSS_C_API int trss_sdl_num_events(SDLAddon* addon);
TRSS_C_API trss_sdl_event trss_sdl_get_event(SDLAddon* addon, int index);
TRSS_C_API void trss_sdl_start_textinput(SDLAddon* addon);
TRSS_C_API void trss_sdl_stop_textinput(SDLAddon* addon);
TRSS_C_API void trss_sdl_set_clipboard(SDLAddon* addon, const char* data);
TRSS_C_API const char* trss_sdl_get_clipboard(SDLAddon* addon);
TRSS_C_API bgfx_callback_interface_t* trss_sdl_get_bgfx_cb(SDLAddon* addon);

class SDLAddon : public trss::Addon {
public:
	SDLAddon();
	const std::string& getName();
	const std::string& getCHeader();
	const std::string& getVersionString();
	void init(trss::Interpreter* owner);
	void shutdown();
	void update(double dt);

	void createWindow(int width, int height, const char* name);
	void registerBGFX();
	void destroyWindow();

	const char* getClipboardText();

	int numEvents();
	trss_sdl_event& getEvent(int index);

	~SDLAddon(); // needed so it can be deleted cleanly
private:
	void convertAndPushEvent_(SDL_Event& event);
	std::string name_;
	std::string version_;
	std::string header_;

	std::string clipboard_;

	SDL_Window* window_;
	SDL_Event event_;
	trss::Interpreter* owner_;
	std::vector<trss_sdl_event> eventBuffer_;
	trss_sdl_event errorEvent_;
};

extern "C" {
	void bgfx_cb_fatal(bgfx_callback_interface_t* _this, bgfx_fatal_t _code, const char* _str);
	uint32_t bgfx_cb_cache_read_size(bgfx_callback_interface_t* _this, uint64_t _id);
	bool bgfx_cb_cache_read(bgfx_callback_interface_t* _this, uint64_t _id, void* _data, uint32_t _size);
	void bgfx_cb_cache_write(bgfx_callback_interface_t* _this, uint64_t _id, const void* _data, uint32_t _size);
	void bgfx_cb_screen_shot(bgfx_callback_interface_t* _this, const char* _filePath, uint32_t _width, uint32_t _height, uint32_t _pitch, const void* _data, uint32_t _size, bool _yflip);
	void bgfx_cb_capture_begin(bgfx_callback_interface_t* _this, uint32_t _width, uint32_t _height, uint32_t _pitch, bgfx_texture_format_t _format, bool _yflip);
	void bgfx_cb_capture_end(bgfx_callback_interface_t* _this);
	void bgfx_cb_capture_frame(bgfx_callback_interface_t* _this, const void* _data, uint32_t _size);
}

#endif