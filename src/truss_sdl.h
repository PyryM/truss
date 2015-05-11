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

extern "C" {
	#define TRSS_SDL_EVENT_KEYDOWN 		1
	#define TRSS_SDL_EVENT_KEYUP		2
	#define TRSS_SDL_EVENT_MOUSEDOWN 	3
	#define TRSS_SDL_EVENT_MOUSEUP	 	4
	#define TRSS_SDL_EVENT_MOUSEMOVE 	5
	#define TRSS_SDL_EVENT_MOUSEWHEEL   6

	/* Simplified SDL Event */
	typedef struct {
		unsigned int event_type;
		char keycode[10]; /* 10 characters should be enough for anybody */
		double x;
		double y;
		int flags;
	} trss_sdl_event;

	void trss_sdl_create_window(SDLAddon* addon, int width, int height, const char* name);
	void trss_sdl_destroy_window(SDLAddon* addon);
	int  trss_sdl_num_events(SDLAddon* addon);
	trss_sdl_event trss_sdl_get_event(SDLAddon* addon, int index);
}

class SDLAddon : public trss::Addon {
public:
	SDLAddon();
	std::string getName();
	std::string getCHeader();
	void init(trss::Interpreter* owner);
	void shutdown();
	void update(double dt);

	void createWindow(int width, int height, const char* name);
	void registerBGFX();
	void destroyWindow();

	int numEvents();
	trss_sdl_event& getEvent(int index);

	~SDLAddon(); // needed so it can be deleted cleanly
private:
	void _convertAndPushEvent(SDL_Event& event);

	SDL_Window* _window;
	SDL_Event _event;
	trss::Interpreter* _owner;
	std::vector<trss_sdl_event> _eventBuffer;
	trss_sdl_event _errorEvent;
};

#endif