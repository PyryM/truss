#include "truss.h"
#include "truss_sdl.h"
#include <iostream>

bool sdlSetWindow(SDL_Window* window_)
{
	SDL_SysWMinfo wmi;
	SDL_VERSION(&wmi.version);
	if (!SDL_GetWindowWMInfo(window_, &wmi))
	{
		return false;
	}

#	if BX_PLATFORM_LINUX || BX_PLATFORM_FREEBSD
	x11SetDisplayWindow(wmi.info.x11.display, wmi.info.x11.window);
#	elif BX_PLATFORM_OSX
	osxSetNSWindow(wmi.info.cocoa.window);
#	elif BX_PLATFORM_WINDOWS
	bgfx_win_set_hwnd(wmi.info.win.window);
#	endif // BX_PLATFORM_

	return true;
}

SDLAddon::SDLAddon(){
	window_ = NULL;
	owner_ = NULL;
	name_ = "sdl";
	header_ = "/*SDLAddon Embedded Header*/\n"
		"typedef struct Addon Addon;\n"
		"#define TRSS_SDL_EVENT_OUTOFBOUNDS 0\n"
		"#define TRSS_SDL_EVENT_KEYDOWN 1\n"
		"#define TRSS_SDL_EVENT_KEYUP		2\n"
		"#define TRSS_SDL_EVENT_MOUSEDOWN 	3\n"
		"#define TRSS_SDL_EVENT_MOUSEUP	 	4\n"
		"#define TRSS_SDL_EVENT_MOUSEMOVE 	5\n"
		"#define TRSS_SDL_EVENT_MOUSEWHEEL  6\n"
		"#define TRSS_SDL_EVENT_WINDOW      7\n"
		"typedef struct {\n"
		"    unsigned int event_type;\n"
		"    char keycode[10];\n"
		"    double x;\n"
		"    double y;\n"
		"    int flags;\n"
		"} trss_sdl_event;\n"
		"void trss_sdl_create_window(Addon* addon, int width, int height, const char* name);\n"
		"void trss_sdl_destroy_window(Addon* addon);\n"
		"int  trss_sdl_num_events(Addon* addon);\n"
		"trss_sdl_event trss_sdl_get_event(Addon* addon, int index);\n";
	errorEvent_.event_type = TRSS_SDL_EVENT_OUTOFBOUNDS;
}

const std::string& SDLAddon::getName(){
	return name_;
}

const std::string& SDLAddon::getCHeader(){
	return header_;
}

void SDLAddon::init(trss::Interpreter* owner){
	owner_ = owner;

	// Init SDL
	if (SDL_Init(SDL_INIT_VIDEO) != 0){
		std::cout << "SDL_Init Error: " << SDL_GetError() << std::endl;
	}
}

void SDLAddon::shutdown(){
	destroyWindow();
	SDL_Quit();
}

void SDLAddon::convertAndPushEvent_(SDL_Event& event) {
	trss_sdl_event newEvent;
	switch(event.type) {
	case SDL_KEYDOWN:
		// TODO
		break;
	case SDL_KEYUP:
		// TODO
		break;
	case SDL_MOUSEMOTION:
		newEvent.event_type = TRSS_SDL_EVENT_MOUSEMOVE;
		newEvent.x = event.motion.x;
		newEvent.y = event.motion.y;
		newEvent.flags = event.motion.state;
		break;
	case SDL_MOUSEBUTTONDOWN:
		newEvent.event_type = TRSS_SDL_EVENT_MOUSEDOWN;
		newEvent.x = event.button.x;
		newEvent.y = event.button.y;
		newEvent.flags = event.button.button;
		break;
	case SDL_MOUSEBUTTONUP:
		newEvent.event_type = TRSS_SDL_EVENT_MOUSEUP;
		newEvent.x = event.button.x;
		newEvent.y = event.button.y;
		newEvent.flags = event.button.button;
		break;
	case SDL_MOUSEWHEEL:
		newEvent.event_type = TRSS_SDL_EVENT_MOUSEWHEEL;
		newEvent.x = event.wheel.x;
		newEvent.y = event.wheel.y;
		newEvent.flags = event.wheel.which;
		break;
	case SDL_WINDOWEVENT:
		newEvent.event_type = TRSS_SDL_EVENT_WINDOW;
		newEvent.flags = event.window.event;
	default:
		break;
	}
	eventBuffer_.push_back(newEvent);
}

void SDLAddon::update(double dt){
	if (window_ == NULL) {
		return;
	}

	eventBuffer_.clear();

	// empty SDL event buffer by polling
	// until none left
	while (SDL_PollEvent(&event_)) {
		convertAndPushEvent_(event_);
	}
}

void SDLAddon::createWindow(int width, int height, const char* name){
	window_ = SDL_CreateWindow(name
			, SDL_WINDOWPOS_UNDEFINED
			, SDL_WINDOWPOS_UNDEFINED
			, width
			, height
			, SDL_WINDOW_SHOWN
			| SDL_WINDOW_RESIZABLE
			);
	registerBGFX();
}

void SDLAddon::registerBGFX(){
	sdlSetWindow(window_);
}

void SDLAddon::destroyWindow(){
	std::cout << "SDLAddon::destroyWindow not implemented yet.\n";
}

SDLAddon::~SDLAddon(){
	shutdown();
}

int SDLAddon::numEvents() {
	return (int)(eventBuffer_.size());
}

trss_sdl_event& SDLAddon::getEvent(int index) {
	if (index >= 0 && index < eventBuffer_.size()) {
		return eventBuffer_[index];
	}
	else {
		return errorEvent_;
	}
}

void trss_sdl_create_window(SDLAddon* addon, int width, int height, const char* name){
	addon->createWindow(width, height, name);
}

void trss_sdl_destroy_window(SDLAddon* addon){
	addon->destroyWindow();
}

int  trss_sdl_num_events(SDLAddon* addon) {
	return addon->numEvents();
}

trss_sdl_event trss_sdl_get_event(SDLAddon* addon, int index) {
	return addon->getEvent(index);
}