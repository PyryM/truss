#include <iostream>
#include <SDL.h>
#include <SDL_syswm.h>
#include <terra.h>

// tell bgfx that it's using a shared library
#define BGFX_SHARED_LIB_USE 1

#include <bgfx.c99.h>
#include <bgfxplatform.c99.h>

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

const int WINDOW_WIDTH = 800;
const int WINDOW_HEIGHT = 600;

void bgfxLoopBody() {
	// Set view 0 default viewport.
	bgfx_set_view_rect(0, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT);

	// This dummy draw call is here to make sure that view 0 is cleared
	// if no other draw calls are submitted to view 0.
	bgfx_submit(0, 0);

	// Use debug font to print information about this example.
	bgfx_dbg_text_clear(0, false);

	bgfx_dbg_text_printf(0, 1, 0x4f, "bgfx/examples/25-c99");
	bgfx_dbg_text_printf(0, 2, 0x6f, "Description: Initialization and debug text with C99 API.");

	// Advance to next frame. Rendering thread will be kicked to
	// process submitted rendering primitives.
	bgfx_frame();
}

void bgfxInit() {
	std::cout << "Rendering first frame...\n";
	//bgfx_render_frame();
	std::cout << "Done rendering first frame.\n";

	uint32_t debug = BGFX_DEBUG_TEXT;
	uint32_t reset = BGFX_RESET_VSYNC;

	std::cout << "Going to init...\n";
	bgfx_init(BGFX_RENDERER_TYPE_COUNT
		, BGFX_PCI_ID_NONE
		, 0
		, NULL
		, NULL
		);
	std::cout << "Done initting.\n";
	bgfx_reset(WINDOW_WIDTH, WINDOW_HEIGHT, reset);
	std::cout << "Done resetting.\n";

	// Enable debug text.
	bgfx_set_debug(debug);

	bgfx_set_view_clear(0
		, BGFX_CLEAR_COLOR | BGFX_CLEAR_DEPTH
		, 0x303030ff
		, 1.0f
		, 0
		);
}

void luaCallWithErrorChecking(lua_State* L, const char* funcname) {
	lua_getglobal(L, funcname);
	int res = lua_pcall(L, 0, 0, 0);
	if (res) {
		std::cout << lua_tostring(L, -1) << std::endl;
	}
}

int main(int, char**){
	if (SDL_Init(SDL_INIT_VIDEO) != 0){
		std::cout << "SDL_Init Error: " << SDL_GetError() << std::endl;
		return 1;
	}
	std::cout << "We seem to have succeeded.\n";

	SDL_Window* m_window = SDL_CreateWindow("testo"
		, SDL_WINDOWPOS_UNDEFINED
		, SDL_WINDOWPOS_UNDEFINED
		, WINDOW_WIDTH
		, WINDOW_HEIGHT
		, SDL_WINDOW_SHOWN
		| SDL_WINDOW_RESIZABLE
		);

	sdlSetWindow(m_window);

	std::cout << "Creating new lua state\n";
	lua_State* L = luaL_newstate();
	std::cout << "Opening standard libraries\n";
	luaL_openlibs(L);
	std::cout << "Upgrading to terra\n";
	terra_Options t;
	t.debug = 1;
	t.verbose = 2;
	t.usemcjit = 0;
	//terra_init(L);
	terra_initwithoptions(L, &t);
	std::cout << "Executing terra code...\n";
	terra_dofile(L, "fake.t");
	//luaL_dofile(L, "fake.t");

	std::cout << "Executing init...\n";
	//lua_getglobal(L, "init");
	//lua_pcall(L, 0, 0, 0);
	luaCallWithErrorChecking(L, "init");

	//bgfxInit();

	SDL_Event event;
	std::cout << "Entering main loop...\n";
	while(true) {
		//std::cout << "Frame...\n";

		// call into terra
		//lua_getglobal(L, "update");
		//lua_pcall(L, 0, 0, 0);
		luaCallWithErrorChecking(L, "update");

		//bgfxLoopBody();
		//bgfx_render_frame();

		while (SDL_PollEvent(&event)) {
		}
	};

	SDL_Quit();
	return 0;
}