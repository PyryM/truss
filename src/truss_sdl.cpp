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

void SDLAddon::update(double dt){
	// empty SDL event buffer by polling
	// until none left
	while (SDL_PollEvent(&_event)) {
		// Do something with the event here...
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

void create_window(SDLAddon* addon, int width, int height, const char* name){
	addon->createWindow(width, height, name);
}

void destroy_window(SDLAddon* addon){
	addon->destroyWindow();
}