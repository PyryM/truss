// Minimal main example (with truss sdl)

#include "truss.h"
#include "addons/sdl/sdl_addon.h"
#include "addons/nanovg/nanovg_addon.h"
#include "addons/wsclient/wsclient_addon.h"
#if defined(WIN32)
#include "addons/openvr/openvr_addon.h"
#include "addons/screencap/screencap_addon.h"
#endif
#include <iostream>
#include <sstream>

#if defined(WIN32)
// On Windows, manually construct an RPATH to the `./lib` subdirectory.
// TODO: refactor this into a config.in
#include "windows.h"
void setupRPath() {
	// Get path to current executable.
	char exe_filepath[MAX_PATH], exe_drive[MAX_PATH], exe_path[MAX_PATH];
	GetModuleFileName(NULL, exe_filepath, MAX_PATH);
	_splitpath_s(exe_filepath, exe_drive, MAX_PATH, exe_path, MAX_PATH, NULL, 0, NULL, 0);

	// Add absolute path to "./lib" directory to "RPATH".
	std::stringstream ss;
	ss << exe_drive << exe_path << "\\lib";
	SetDllDirectory(ss.str().c_str());

	// Manually force loading of DELAYLOAD-ed libraries.
	LoadLibrary("bgfx-shared-libRelease.dll");
}
#else
void setupRPath() {
	// Do nothing on non-WIN32 platforms.
}
#endif

void storeArgs(int argc, char** argv) {
	for (int i = 0; i < argc; ++i) {
		std::stringstream ss;
		ss << "arg" << i;
		std::string val(argv[i]);
		truss::core().setStoreValue(ss.str(), val);
	}
}

int main(int argc, char** argv) {
	truss_test();
	truss_log(0, "Entered main!");
	storeArgs(argc, argv);

	// set up physFS filesystem
	truss::core().initFS(argv[0], true);			// mount the base directory
	truss::core().addFSPath("truss.zip", "/");		// try to mount truss.zip as root if it exists
	truss::core().extractLibraries();				// extract currently loaded C libraries
	setupRPath();									// set windows RPATH if necessary

	truss::core().setWriteDir("");              	// write into basedir/

	truss::Interpreter* interpreter = truss::core().spawnInterpreter("interpreter_0");
	interpreter->setDebug(0); // want most verbose debugging output
	interpreter->attachAddon(new SDLAddon);
	interpreter->attachAddon(new NanoVGAddon);
	interpreter->attachAddon(new WSClientAddon);
#if defined(WIN32)
	interpreter->attachAddon(new OpenVRAddon);
	interpreter->attachAddon(new ScreencapAddon);
#endif
	truss_log(0, "Starting interpreter!");
	// startUnthreaded starts the interpreter in the current thread,
	// which means the call will block until the interpreter is stopped
	if (argc > 1) {
		interpreter->startUnthreaded(argv[1]);
	} else {
		interpreter->startUnthreaded("scripts/main.t");
	}
	int retval = truss::core().getError();
	if (retval != 0) {
		std::cout << "Quit with error code: " << retval << std::endl;
	}
	return retval;
}
