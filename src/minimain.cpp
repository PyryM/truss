// Minimal main example (with truss sdl)

#include "truss.h"
#include "truss_sdl.h"
#include "nanovg_addon.h"
#include "wsclient_addon.h"
#include <iostream>
#include <sstream>

void storeArgs(int argc, char** argv) {
	for (int i = 0; i < argc; ++i) {
		std::stringstream ss;
		ss << "arg" << i;
		std::string val(argv[i]);
		trss::core()->setStoreValue(ss.str(), val);
	}
}

int main(int argc, char** argv){
	trss_test();
	trss_log(0, "Entered main!");
	storeArgs(argc, argv);
		
	// set up physFS filesystem
	trss::core()->initFS(argv[0], true); // mount the base directory
	trss::core()->setWriteDir("save");   // write into basedir/save/

	trss::Interpreter* interpreter = trss::core()->spawnInterpreter("interpreter_0");
	interpreter->setDebug(0); // want most verbose debugging output
	interpreter->attachAddon(new SDLAddon);
	interpreter->attachAddon(new NanoVGAddon);
	interpreter->attachAddon(new WSClientAddon);
	trss_log(0, "Starting interpreter!");
	// startUnthreaded starts the interpreter in the current thread,
	// which means the call will block until the interpreter is stopped
	//interpreter->startUnthreaded("examples/dart_gui_test.t");
	if (argc > 1) {
		interpreter->startUnthreaded(argv[1]);
	}
	else {
		interpreter->startUnthreaded("examples/dart_gui_test.t");
	}
	return 0;
}