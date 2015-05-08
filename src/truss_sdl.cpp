#include "truss.h"
#include "truss_sdl.h"

bool sdlSetWindow(SDL_Window* _window)
{
	SDL_SysWMinfo wmi;
	SDL_VERSION(&wmi.version);
	if (!SDL_GetWindowWMInfo(_window, &wmi))
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
	_window = NULL;
	_owner = NULL;
}

std::string SDLAddon::getName(){
	return "SDLAddon";
}

std::string SDLAddon::getCHeader(){
	return "//not yet implemented";
}

void SDLAddon::init(trss::Interpreter* owner){
	_owner = owner;

	// Init SDL
	if (SDL_Init(SDL_INIT_VIDEO) != 0){
		std::cout << "SDL_Init Error: " << SDL_GetError() << std::endl;
	}
}

void SDLAddon::shutdown(){
	destroyWindow();
	SDL_Quit();
}

void SDLAddon::_convertAndPushEvent(SDL_Event& event) {
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
		newEvent.flags = event.wheel.direction;
		break;
	default:
		break;
	}
	_eventBuffer.push_back(newEvent);
}

void SDLAddon::update(double dt){
	_eventBuffer.clear();

	// empty SDL event buffer by polling
	// until none left
	while (SDL_PollEvent(&_event)) {
		_convertAndPushEvent(_event);
	}
}

void SDLAddon::createWindow(int width, int height, const char* name){
	_window = SDL_CreateWindow(name
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
	sdlSetWindow(_window);
}

void SDLAddon::destroyWindow(){
	std::cout << "SDLAddon::destroyWindow not implemented yet.\n";
}

SDLAddon::~SDLAddon(){
	shutdown();
}

int SDLAddon::numEvents() {
	return _eventBuffer.size();
}

trss_sdl_event& SDLAddon::getEvent(int index) {
	if(index >= 0 && index < _eventBuffer.size()) {
		return _eventBuffer[index];
	} else {
		return _errorEvent;
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