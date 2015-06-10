// Minimal main example (with truss sdl)

#include "truss.h"
#include "truss_sdl.h"
#include "nanovg_addon.h"
#include "wsclient_addon.h"
#include <iostream>

int main(int, char**){
	trss_test();
	trss_log(0, "Entered main!");
	trss::Interpreter* interpreter = trss::core()->spawnInterpreter("interpreter_0");
	interpreter->setDebug(0); // want most verbose debugging output
	interpreter->attachAddon(new SDLAddon);
	interpreter->attachAddon(new NanoVGAddon);
	interpreter->attachAddon(new WSClientAddon);
	trss_log(0, "Starting interpreter!");
	// startUnthreaded starts the interpreter in the current thread,
	// which means the call will block until the interpreter is stopped
	//interpreter->startUnthreaded("examples/dart_gui_test.t");
	interpreter->startUnthreaded("examples/split_renderer.t");
	return 0;
}