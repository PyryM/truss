#ifndef SCREENCAP_ADDON_H
#define SCREENCAP_ADDON_H

#include "../../truss.h"

// use bgfx through the shared-library C API
//#define BGFX_SHARED_LIB_USE 1
//#include <bgfx/c99/bgfx.h>
//#include <bgfx/c99/bgfxplatform.h>

class ScreencapAddonInternals;
class ScreencapAddon;

typedef struct {
    unsigned int width;
    unsigned int height;
} truss_scap_frameinfo;

TRUSS_C_API bool truss_scap_init(ScreencapAddon* addon);
TRUSS_C_API void truss_scap_shutdown(ScreencapAddon* addon);
TRUSS_C_API bool truss_scap_acquire_frame(ScreencapAddon* addon);
TRUSS_C_API bool truss_scap_release_frame(ScreencapAddon* addon);
TRUSS_C_API truss_scap_frameinfo truss_scap_get_frame_info(ScreencapAddon* addon);
TRUSS_C_API bool truss_scap_copy_frame_tex_d3d11(ScreencapAddon* addon, void* desttex_d3d11);

class ScreencapAddon : public truss::Addon {
public:
    ScreencapAddon();
    const std::string& getName();
    const std::string& getHeader();
    const std::string& getVersion();
    void init(truss::Interpreter* owner);
    void shutdown();
    void update(double dt);

    // API Methods
    bool initDuplication(int outputIdx);
    bool acquireFrame();
    bool releaseFrame();
    truss_scap_frameinfo getFrameInfo();
    bool copyFrameTexD3D11(void* desttex);

    ~ScreencapAddon(); // needed so it can be deleted cleanly
private:
    std::string _name;
    std::string _version;
    std::string _header;

    ScreencapAddonInternals* _internals;

    truss::Interpreter* _owner;

	bool acquireDeskDupl();
	void releaseDeskDupl();

	void printError(const char* errmsg);
	void clearError();
};

#endif
