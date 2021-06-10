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

#ifdef __cplusplus
class SDLAddon;
#else
typedef struct SDLAddon SDLAddon;
#endif

#define TRUSS_SDL_EVENT_OUTOFBOUNDS   0
#define TRUSS_SDL_EVENT_KEYDOWN       1
#define TRUSS_SDL_EVENT_KEYUP         2
#define TRUSS_SDL_EVENT_MOUSEDOWN     3
#define TRUSS_SDL_EVENT_MOUSEUP       4
#define TRUSS_SDL_EVENT_MOUSEMOVE     5
#define TRUSS_SDL_EVENT_MOUSEWHEEL    6
#define TRUSS_SDL_EVENT_WINDOW        7
#define TRUSS_SDL_EVENT_TEXTINPUT     8
#define TRUSS_SDL_EVENT_GP_ADDED      9
#define TRUSS_SDL_EVENT_GP_REMOVED    10
#define TRUSS_SDL_EVENT_GP_AXIS       11
#define TRUSS_SDL_EVENT_GP_BUTTONDOWN 12
#define TRUSS_SDL_EVENT_GP_BUTTONUP   13
#define TRUSS_SDL_EVENT_FILEDROP      14

#define TRUSS_SDL_MAX_KEYCODE_LENGTH  15 /* should be enough for anybody */
#define TRUSS_SDL_KEYCODE_BUFF_SIZE   16 /* extra byte for null terminator */

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

typedef struct {
	int x;
	int y;
	int w;
	int h;
} truss_sdl_bounds;

TRUSS_C_API int truss_sdl_get_display_count(SDLAddon* addon);
TRUSS_C_API truss_sdl_bounds truss_sdl_get_display_bounds(SDLAddon* addon, int display);
TRUSS_C_API void truss_sdl_create_window(SDLAddon* addon, int width, int height, const char* name, int is_fullscreen, int display);
TRUSS_C_API void truss_sdl_create_window_ex(SDLAddon* addon, int x, int y, int w, int h, const char* name, int is_borderless);
TRUSS_C_API void truss_sdl_destroy_window(SDLAddon* addon);
TRUSS_C_API void truss_sdl_resize_window(SDLAddon* addon, int width, int height, int fullscreen);
TRUSS_C_API truss_sdl_bounds truss_sdl_window_size(SDLAddon* addon);
TRUSS_C_API truss_sdl_bounds truss_sdl_window_gl_size(SDLAddon* addon);
TRUSS_C_API int truss_sdl_num_events(SDLAddon* addon);
TRUSS_C_API truss_sdl_event truss_sdl_get_event(SDLAddon* addon, int index);
TRUSS_C_API void truss_sdl_start_textinput(SDLAddon* addon);
TRUSS_C_API void truss_sdl_stop_textinput(SDLAddon* addon);
TRUSS_C_API void truss_sdl_set_clipboard(SDLAddon* addon, const char* data);
TRUSS_C_API const char* truss_sdl_get_clipboard(SDLAddon* addon);
TRUSS_C_API const char* truss_sdl_get_user_path(SDLAddon* addon, const char* orgname, const char* appname);
TRUSS_C_API const char* truss_sdl_get_filedrop_path(SDLAddon* addon);
TRUSS_C_API bgfx_callback_interface_t* truss_sdl_get_bgfx_cb(SDLAddon* addon);
TRUSS_C_API void truss_sdl_set_relative_mouse_mode(SDLAddon* addon, int mode);
TRUSS_C_API void truss_sdl_show_cursor(SDLAddon* addon, int visible);
TRUSS_C_API int truss_sdl_create_cursor(SDLAddon* addon, int cursorSlot, const unsigned char* data, const unsigned char* mask, int w, int h, int hx, int hy);
TRUSS_C_API int truss_sdl_set_cursor(SDLAddon* addon, int cursorSlot);
TRUSS_C_API int truss_sdl_num_controllers(SDLAddon* addon);
TRUSS_C_API int truss_sdl_enable_controller(SDLAddon* addon, int controllerIdx);
TRUSS_C_API void truss_sdl_disable_controller(SDLAddon* addon, int controllerIdx);
TRUSS_C_API const char* truss_sdl_get_controller_name(SDLAddon* addon, int controllerIdx);

#define MAX_CONTROLLERS 16
#define MAX_CURSORS     16

class SDLAddon : public truss::Addon {
public:
	SDLAddon();
	const std::string& getName();
	const std::string& getHeader();
	const std::string& getVersion();
	void init(truss::Interpreter* owner);
	void SDLinit();
	void shutdown();
	void update(double dt);

	void createWindow(int width, int height, const char* name, int is_fullscreen, int display);
	void createWindow(int x, int y, int w, int h, const char* name, int is_borderless);
	truss_sdl_bounds windowSize();
	truss_sdl_bounds windowGLSize();
	void registerBGFX();
	void destroyWindow();
	void resizeWindow(int width, int height, int fullscreen);

	int openController(int joyIndex);
	void closeController(int joyIndex);
	const char* getControllerName(int controllerIdx);

	const char* getClipboardText();
	const char* getFiledropText();

	bool createCursor(int cursorSlot, const unsigned char* data, const unsigned char* mask, int w, int h, int hx, int hy);
	bool setCursor(int slot);
	void showCursor(int visible);

	int numEvents();
	truss_sdl_event& getEvent(int index);

	~SDLAddon(); // needed so it can be deleted cleanly
private:
	void convertAndPushEvent_(SDL_Event& event);
	std::string name_;
	std::string version_;
	std::string header_;

	std::string clipboard_;
	std::string filedrop_;

	bool sdlIsInit_;

	SDL_Window* window_;
	SDL_Event event_;
	truss::Interpreter* owner_;
	std::vector<truss_sdl_event> eventBuffer_;
	truss_sdl_event errorEvent_;
	SDL_GameController* controllers_[MAX_CONTROLLERS];
	SDL_Cursor* cursors_[MAX_CURSORS];
};

extern "C" {
	void bgfx_cb_fatal(bgfx_callback_interface_t* _this, const char* _filePath, uint16_t _line, bgfx_fatal_t _code, const char* _str);
	void bgfx_cb_trace_vargs(bgfx_callback_interface_t* _this, const char* _filePath, uint16_t _line, const char* _format, va_list _argList);
	void bgfx_cb_profiler_begin(bgfx_callback_interface_t* _this, const char* _name, uint32_t _abgr, const char* _filePath, uint16_t _line);
	void bgfx_cb_profiler_begin_literal(bgfx_callback_interface_t* _this, const char* _name, uint32_t _abgr, const char* _filePath, uint16_t _line);
	void bgfx_cb_profiler_end(bgfx_callback_interface_t* _this);
	uint32_t bgfx_cb_cache_read_size(bgfx_callback_interface_t* _this, uint64_t _id);
	bool bgfx_cb_cache_read(bgfx_callback_interface_t* _this, uint64_t _id, void* _data, uint32_t _size);
	void bgfx_cb_cache_write(bgfx_callback_interface_t* _this, uint64_t _id, const void* _data, uint32_t _size);
	void bgfx_cb_screen_shot(bgfx_callback_interface_t* _this, const char* _filePath, uint32_t _width, uint32_t _height, uint32_t _pitch, const void* _data, uint32_t _size, bool _yflip);
	void bgfx_cb_capture_begin(bgfx_callback_interface_t* _this, uint32_t _width, uint32_t _height, uint32_t _pitch, bgfx_texture_format_t _format, bool _yflip);
	void bgfx_cb_capture_end(bgfx_callback_interface_t* _this);
	void bgfx_cb_capture_frame(bgfx_callback_interface_t* _this, const void* _data, uint32_t _size);
}

#endif