#include "screencap_addon.h"

#include <windows.h>
#include <d3d11.h>
#include <dxgi1_2.h>
#include <iostream>

// tell bgfx that it's using a shared library
#define BGFX_SHARED_LIB_USE 1

#include <bgfx/c99/bgfx.h>

class ScreencapAddonInternals {
public:
    bool initted;

    ID3D11Device* device;
    ID3D11DeviceContext* context;
    ID3D11Texture2D* frame;
    DXGI_OUTDUPL_FRAME_INFO frameInfo;
    D3D11_TEXTURE2D_DESC frameDesc;
    IDXGIOutputDuplication* deskDupl;
    DXGI_OUTPUT_DESC outputDesc;
	bool needsRecreate;
	int outputIdx;
	bool printedError;

    ScreencapAddonInternals() {
        initted = false;
        device = NULL;
        context = NULL;
        frame = NULL;
        deskDupl = NULL;
		needsRecreate = false;
		outputIdx = 0;
		printedError = false;
    }
};

ScreencapAddon::ScreencapAddon() {
    _internals = NULL;
    _name = "screencap";
    _version = "0.0.1";
    _header = R"(
    /* Screencap Addon Embedded Header */
	#include <stdbool.h>

    typedef struct Addon Addon;
    typedef struct {
        unsigned int width;
        unsigned int height;
    } truss_scap_frameinfo;
	#define SCREENCAP_NO_UPDATE 0
	#define SCREENCAP_MOUSE_UPDATE 1
	#define SCREENCAP_IMAGE_UPDATE 2
	#define SCREENCAP_ERROR 3
	#define SCREENCAP_RESET 4

    bool truss_scap_init(Addon* addon);
    void truss_scap_shutdown(Addon* addon);
    int truss_scap_acquire_frame(Addon* addon, int timeout);
    truss_scap_frameinfo truss_scap_get_frame_info(Addon* addon);
    bool truss_scap_copy_frame_tex_d3d11(Addon* addon, void* desttex_d3d11);
    )";
}

const std::string& ScreencapAddon::getName() {
    return _name;
}

const std::string& ScreencapAddon::getHeader() {
    return _header;
}

const std::string& ScreencapAddon::getVersion() {
    return _version;
}

void ScreencapAddon::init(truss::Interpreter* owner) {
    _owner = owner;
}

void ScreencapAddon::shutdown() {
    // nothing special to do
}

void ScreencapAddon::update(double dt) {
    // also nothing special to do?
}

bool ScreencapAddon::initDuplication(int outputIdx) {
	truss_log(TRUSS_LOG_DEBUG, "ScreencapAddon 1.");
    if(_internals != NULL) {
        if(_internals->initted) {
            truss_log(TRUSS_LOG_WARNING, "ScreencapAddon duplication already initted.");
            return true;
        } else {
            truss_log(TRUSS_LOG_ERROR, "ScreencapAddon duplication in some broken state.");
            return false;
        }
    }

    _internals = new ScreencapAddonInternals;

    if(outputIdx < 0) {
        outputIdx = 0;
    }
	_internals->outputIdx = outputIdx;
    const bgfx_internal_data_t* bgfxdata = bgfx_get_internal_data();
    _internals->device = reinterpret_cast<ID3D11Device*>(bgfxdata->context);
	_internals->device->GetImmediateContext(&(_internals->context));
	_internals->device->AddRef();
    _internals->context->AddRef();

	acquireDeskDupl();

    _internals->initted = true;
    return true;
}

bool ScreencapAddon::acquireDeskDupl() {
	if (_internals->deskDupl != NULL) {
		releaseDeskDupl();
	}

	// Get DXGI device
	IDXGIDevice* DxgiDevice = nullptr;
	HRESULT hr = _internals->device->QueryInterface(__uuidof(IDXGIDevice), reinterpret_cast<void**>(&DxgiDevice));
	if (FAILED(hr)) {
		truss_log(TRUSS_LOG_ERROR, "ScreencapAddon::acquireDeskDupl :(");
		return false;
	}

	// Get DXGI adapter
	IDXGIAdapter* DxgiAdapter = nullptr;
	hr = DxgiDevice->GetParent(__uuidof(IDXGIAdapter), reinterpret_cast<void**>(&DxgiAdapter));
	DxgiDevice->Release();
	DxgiDevice = nullptr;
	if (FAILED(hr)) {
		truss_log(TRUSS_LOG_ERROR, "ScreencapAddon::acquireDeskDupl Failed to get parent DXGI Adapter");
		return false;
	}

	// Get output
	IDXGIOutput* DxgiOutput = nullptr;
	hr = DxgiAdapter->EnumOutputs(_internals->outputIdx, &DxgiOutput);
	DxgiAdapter->Release();
	DxgiAdapter = nullptr;
	if (FAILED(hr)) {
		truss_log(TRUSS_LOG_ERROR, "ScreencapAddon::acquireDeskDupl Failed to get specified output");
		return false;
	}

	DxgiOutput->GetDesc(&(_internals->outputDesc));

	// QI for Output 1
	IDXGIOutput1* DxgiOutput1 = nullptr;
	hr = DxgiOutput->QueryInterface(__uuidof(DxgiOutput1), reinterpret_cast<void**>(&DxgiOutput1));
	DxgiOutput->Release();
	DxgiOutput = nullptr;
	if (FAILED(hr)) {
		truss_log(TRUSS_LOG_ERROR, "ScreencapAddon::acquireDeskDupl Failed to QI for DxgiOutput1");
		return false;
	}

	// Create desktop duplication
	hr = DxgiOutput1->DuplicateOutput(_internals->device, &(_internals->deskDupl));
	DxgiOutput1->Release();
	DxgiOutput1 = nullptr;
	if (FAILED(hr)) {
		if (hr == DXGI_ERROR_NOT_CURRENTLY_AVAILABLE) {
			truss_log(TRUSS_LOG_ERROR, "ScreencapAddon::acquireDeskDupl There is already the maximum number of applications using the Desktop Duplication API running");
		}
		printError("ScreencapAddon::acquireDeskDupl Failed to get duplicate output");
		_internals->deskDupl = NULL;
		return false;
	}

	clearError();
	return true;
}

void ScreencapAddon::releaseDeskDupl() {
	if (_internals->deskDupl == NULL) {
		return;
	}
	_internals->deskDupl->Release();
	_internals->deskDupl = NULL;
}

void ScreencapAddon::printError(const char* errmsg) {
	if (!_internals->printedError) {
		truss_log(TRUSS_LOG_ERROR, errmsg);
		_internals->printedError = true;
	}
}

void ScreencapAddon::clearError() {
	_internals->printedError = false;
}

ScreencapAddon::~ScreencapAddon() {
    if(_internals == NULL) return;

    if (_internals->deskDupl != NULL) {
        _internals->deskDupl->Release();
    }

    if (_internals->frame != NULL) {
        _internals->frame->Release();
    }

    if(_internals->context != NULL) {
        _internals->context->Release();
    }

    if (_internals->device != NULL) {
        _internals->device->Release();
    }

    delete _internals;
    _internals = NULL;
}

//
// Get next frame and write it into Data
//
int ScreencapAddon::acquireFrame(int timeout) {
    if(_internals == NULL || !(_internals->initted)) {
        truss_log(TRUSS_LOG_ERROR, "ScreencapAddon::acquireFrame : not initialized!");
        return SCREENCAP_ERROR;
    }

	if (_internals->deskDupl == NULL) {
		if (!acquireDeskDupl()) {
			printError("ScreencapAddon::acquireFrame : failed to reacquire capture.");
			return SCREENCAP_ERROR;
		}
	}

	releaseFrame();

    IDXGIResource* DesktopResource = NULL;

    //Get new frame
    HRESULT hr = S_OK;
    hr = _internals->deskDupl->AcquireNextFrame(timeout, &(_internals->frameInfo), &DesktopResource);
    if (FAILED(hr)) {
        if ((hr != DXGI_ERROR_ACCESS_LOST) && (hr != DXGI_ERROR_WAIT_TIMEOUT)) {
            truss_log(TRUSS_LOG_ERROR, "ScreencapAddon: failed to acquire frame.");
			printf("%x\n", hr);
			return SCREENCAP_ERROR;
        }
		if (hr == DXGI_ERROR_ACCESS_LOST) {
			truss_log(TRUSS_LOG_INFO, "ScreencapAddon: duplication lost (probably due to mode switch).");
			releaseDeskDupl();
			return SCREENCAP_RESET;
		}
        return SCREENCAP_NO_UPDATE; // just a plain timeout
    }


	// Frames can be both image and/or mouse updates: we don't care about 1000hz mouse updates
	// Docs on LastPresentTime: "A zero value indicates that the desktop image was not updated"
	bool isScreenUpdate = true;
	if (_internals->frameInfo.LastPresentTime.QuadPart == 0ULL) {
		isScreenUpdate = false;
	}

    // If still holding old frame, destroy it
    if (_internals->frame != NULL) {
        _internals->frame->Release();
        _internals->frame = NULL;
    }

    // QI for IDXGIResource
	if(isScreenUpdate) {
		hr = DesktopResource->QueryInterface(__uuidof(ID3D11Texture2D), reinterpret_cast<void **>(&(_internals->frame)));
		DesktopResource->Release();
		DesktopResource = NULL;
		if (FAILED(hr)) {
			truss_log(TRUSS_LOG_ERROR, "ScreencapAddon: Failed to QI for ID3D11Texture2D from acquired IDXGIResource");
			_internals->deskDupl->ReleaseFrame();
			_internals->frame = NULL;
			return SCREENCAP_ERROR;
		}
		_internals->frame->GetDesc(&(_internals->frameDesc));
	} else {
		DesktopResource->Release();
		DesktopResource = NULL;
	}

	clearError();
    return isScreenUpdate ? SCREENCAP_IMAGE_UPDATE : SCREENCAP_MOUSE_UPDATE;
}

bool ScreencapAddon::copyFrameTexD3D11(void* rawdest) {
    if(_internals == NULL || !(_internals->initted)) {
        truss_log(TRUSS_LOG_ERROR, "ScreencapAddon::copyFrameTexD3D11 : not initialized!");
        return false;
    }

    if(_internals->frame == NULL || rawdest == NULL){
		truss_log(TRUSS_LOG_ERROR, "No frame or destination?");
        return false;
    }
    ID3D11Texture2D* desttex = reinterpret_cast<ID3D11Texture2D*>(rawdest);

    D3D11_TEXTURE2D_DESC& srcDesc = _internals->frameDesc;
    D3D11_TEXTURE2D_DESC destDesc;
    desttex->GetDesc(&destDesc);

    // CopyResource requires that the dimensions and format match exactly
    if(srcDesc.Width != destDesc.Width || srcDesc.Height != destDesc.Height) {
		truss::core().logPrint(TRUSS_LOG_ERROR,
                 "ScreencapAddon::copyFrameTexD3D11 size mismatch: ",
                 srcDesc.Width, "*", srcDesc.Height, " vs ",
                 destDesc.Width, "*", destDesc.Height);
        return false;
    }
    if(srcDesc.Format != destDesc.Format) {
		truss::core().logPrint(TRUSS_LOG_ERROR,
                  "ScreencapAddon::copyFrameTexD3D11 format mismatch: ",
                  srcDesc.Format, " vs ", destDesc.Format);
        return false;
    }
	//truss_log(TRUSS_LOG_DEBUG, "Dimensions seem to match...");
    _internals->context->CopyResource(desttex, _internals->frame);

    return true;
}

truss_scap_frameinfo ScreencapAddon::getFrameInfo() {
    truss_scap_frameinfo ret;
    if(_internals->frame != NULL) {
        ret.width = _internals->frameDesc.Width;
        ret.height = _internals->frameDesc.Height;
    } else {
        ret.width = 0;
        ret.height = 0;
    }
    return ret;
}

//
// Release frame
//
bool ScreencapAddon::releaseFrame() {
	/*
	if (_internals->frame == NULL) {
		return true; // no frame to release, so success?
	}*/

    if(_internals == NULL || !(_internals->initted)) {
        truss_log(TRUSS_LOG_ERROR, "ScreencapAddon::releaseFrame : not initialized!");
        return false;
    }

    HRESULT hr = _internals->deskDupl->ReleaseFrame();
    if (FAILED(hr)) {
		if (hr == DXGI_ERROR_ACCESS_LOST) {
			printError("ScreencapAddon::releaseFrame : duplication lost (probably due to mode switch).");
			_internals->frame = NULL; // is this what's segfaulting?
			releaseDeskDupl();
		} else {
			printError("ScreencapAddon: Failed to release frame for unknown reason.");
		}
        return false;
    }

    if (_internals->frame != NULL) {
        _internals->frame->Release();
        _internals->frame = NULL;
    }

	clearError();
    return true;
}

bool truss_scap_init(ScreencapAddon* addon) {
    if(addon == NULL) return false;
    return addon->initDuplication(0);
}

void truss_scap_shutdown(ScreencapAddon* addon) {
    if(addon == NULL) return;
    // anything to do here?
}

int truss_scap_acquire_frame(ScreencapAddon* addon, int timeout) {
    if(addon == NULL) return false;
    return addon->acquireFrame(timeout);
}

/*
bool truss_scap_release_frame(ScreencapAddon* addon) {
    if(addon == NULL) return false;
    return addon->releaseFrame();
}*/

truss_scap_frameinfo truss_scap_get_frame_info(ScreencapAddon* addon) {
    if(addon == NULL) {
        truss_scap_frameinfo badinfo;
        badinfo.width = 0;
        badinfo.height = 0;
        return badinfo;
    }
    return addon->getFrameInfo();
}

bool truss_scap_copy_frame_tex_d3d11(ScreencapAddon* addon, void* desttex_d3d11) {
    if(addon == NULL) return false;
    return addon->copyFrameTexD3D11(desttex_d3d11);
}
