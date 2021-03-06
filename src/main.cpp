// Minimal main example (with truss sdl)

#include "truss.h"
#include "addons/sdl/sdl_addon.h"
#include "addons/nanovg/nanovg_addon.h"
#if !defined(__APPLE__)
#include "addons/openvr/openvr_addon.h"
#endif
#if defined(WIN32)
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

	truss::Interpreter* interpreter = truss::core().spawnInterpreter();
	interpreter->setDebug(0); // want most verbose debugging output
	interpreter->attachAddon(new SDLAddon);
	interpreter->attachAddon(new NanoVGAddon);
#if !defined(__APPLE__)
	// OpenVR supported on Win+Linux
	interpreter->attachAddon(new OpenVRAddon);
#endif
#if defined(WIN32)
	// Screencap currently uses windows-specific APIs
	interpreter->attachAddon(new ScreencapAddon);
#endif
	truss_log(0, "Starting interpreter!");
	// start this interpreter without threading so we can manually call it in a loop
	interpreter->start("scripts/main.t", false);
	while (interpreter->getState() == THREAD_IDLE) {
		interpreter->step();
	}

	int retval = truss::core().getError();
	if (retval != 0) {
		std::cout << "Quit with error code: " << retval << std::endl;
	}
	return retval;
}
