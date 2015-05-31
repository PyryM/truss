#ifndef TRUSS_SDL_HEADER
#define TRUSS_SDL_HEADER

#include <vector>
#include <SDL.h>
#include <SDL_syswm.h>

#include "truss.h"

// tell bgfx that it's using a shared library
#define BGFX_SHARED_LIB_USE 1

#include <bgfx.c99.h>
#include <bgfxplatform.c99.h>

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

/* Simplified SDL Event */
typedef struct {
	unsigned int event_type;
	char keycode[TRSS_SDL_MAX_KEYCODE_LENGTH + 1]; // reserve 1 byte for \0 
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

class SDLAddon : public trss::Addon {
public:
	SDLAddon();
	const std::string& getName();
	const std::string& getCHeader();
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
	std::string header_;

	std::string clipboard_;

	SDL_Window* window_;
	SDL_Event event_;
	trss::Interpreter* owner_;
	std::vector<trss_sdl_event> eventBuffer_;
	trss_sdl_event errorEvent_;
};

#endif