// Minimal main example (with truss sdl)

#include "truss.h"
#include "truss_sdl.h"
#include <iostream>

int main(int, char**){
	trss::Interpreter* interpreter = trss::Core::getCore()->spawnInterpreter("interpreter_0");
	interpreter->attachAddon(new SDLAddon);
	interpreter->startUnthreaded("sdl_bgfx_example.t"); // will block until this interpreter terminates
	return 0;
}