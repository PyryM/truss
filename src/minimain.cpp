// Minimal main example (with truss sdl)

#include "truss.h"
#include "truss_sdl.h"
#include <iostream>

int main(int, char**){
	trss_log(0, "Enterd main!");
	trss::Interpreter* interpreter = trss::core()->spawnInterpreter("interpreter_0");
	interpreter->attachAddon(new SDLAddon);
	trss_log(0, "Starting interpreter!");
	interpreter->startUnthreaded("sdl_bgfx_example.t"); // will block until this interpreter terminates
	return 0;
}