#ifndef TRUSS_SDL_HEADER
#define TRUSS_SDL_HEADER

#include "../../truss.h"

#include <SDL_config.h>
#include <SDL.h>
#include <SDL_syswm.h>
#include <vector>

// SDL defines a "main" prototype to use `SDL_main()`, but we don't want this.
// Instead, we use our own main function so we can control the platform-specific
// runtime library loading.
#undef main

// tell bgfx that it's using a shared library
#define BGFX_SHARED_LIB_USE 1

#include <bgfx/c99/bgfx.h>
#include <bgfx/c99/bgfxplatform.h>

#ifdef __cplusplus
class SDLAddon;
#else
typedef struct SDLAddon SDLAddon;
#endif

#define TRUSS_SDL_EVENT_OUTOFBOUNDS  0
#define TRUSS_SDL_EVENT_KEYDOWN 		1
#define TRUSS_SDL_EVENT_KEYUP		2
#define TRUSS_SDL_EVENT_MOUSEDOWN 	3
#define TRUSS_SDL_EVENT_MOUSEUP	 	4
#define TRUSS_SDL_EVENT_MOUSEMOVE 	5
#define TRUSS_SDL_EVENT_MOUSEWHEEL   6
#define TRUSS_SDL_EVENT_WINDOW       7
#define TRUSS_SDL_EVENT_TEXTINPUT    8

#define TRUSS_SDL_MAX_KEYCODE_LENGTH 15 /* should be enough for anybody */
#define TRUSS_SDL_KEYCODE_BUFF_SIZE  16 /* extra byte for null terminator */

/* Simplified SDL Event */
typedef struct {
	unsigned int event_type;
	char keycode[TRUSS_SDL_KEYCODE_BUFF_SIZE];
	double x;
	double y;
	double dx;
	double dy;
	int flags;
} truss_sdl_event;

TRUSS_C_API void truss_sdl_create_window(SDLAddon* addon, int width, int height, const char* name);
TRUSS_C_API void truss_sdl_destroy_window(SDLAddon* addon);
TRUSS_C_API int truss_sdl_num_events(SDLAddon* addon);
TRUSS_C_API truss_sdl_event truss_sdl_get_event(SDLAddon* addon, int index);
TRUSS_C_API void truss_sdl_start_textinput(SDLAddon* addon);
TRUSS_C_API void truss_sdl_stop_textinput(SDLAddon* addon);
TRUSS_C_API void truss_sdl_set_clipboard(SDLAddon* addon, const char* data);
TRUSS_C_API const char* truss_sdl_get_clipboard(SDLAddon* addon);
TRUSS_C_API bgfx_callback_interface_t* truss_sdl_get_bgfx_cb(SDLAddon* addon);
TRUSS_C_API void truss_sdl_set_relative_mouse_mode(SDLAddon* addon, int mode);

class SDLAddon : public truss::Addon {
public:
	SDLAddon();
	const std::string& getName();
	const std::string& getHeader();
	const std::string& getVersionString();
	void init(truss::Interpreter* owner);
	void shutdown();
	void update(double dt);

	void createWindow(int width, int height, const char* name);
	void registerBGFX();
	void destroyWindow();

	const char* getClipboardText();

	int numEvents();
	truss_sdl_event& getEvent(int index);

	~SDLAddon(); // needed so it can be deleted cleanly
private:
	void convertAndPushEvent_(SDL_Event& event);
	std::string name_;
	std::string version_;
	std::string header_;

	std::string clipboard_;

	SDL_Window* window_;
	SDL_Event event_;
	truss::Interpreter* owner_;
	std::vector<truss_sdl_event> eventBuffer_;
	truss_sdl_event errorEvent_;
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