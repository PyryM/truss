// Minimal main example (with truss sdl)

#include "truss.h"
#include "truss_sdl.h"
#include <iostream>

int main(int, char**){
	trss_test();
	trss_log(0, "Entered main!");
	trss::Interpreter* interpreter = trss::core()->spawnInterpreter("interpreter_0");
	interpreter->setDebug(0); // want most verbose debugging output
	interpreter->attachAddon(new SDLAddon);
	trss_log(0, "Starting interpreter!");
	interpreter->startUnthreaded("examples/cube.t"); // will block until this interpreter terminates
	return 0;
}