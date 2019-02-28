#include "openvr_addon.h"

OpenVRAddon::OpenVRAddon() {
    owner_ = NULL;
    name_ = "openvr";
    version_ = "0.9.20";
    header_ = R"(
        /*  OpenVR Addon Embedded Header                                     */
        /*  Note that this only defines the initialization for OpenVR;       */
        /*  the bulk of the functions are contained in includes/openvr_c.h   */

            typedef struct Addon Addon;

            #define TRUSS_OPENVR_DX11 0
            #define TRUSS_OPENVR_GL   1

            int truss_openvr_init(Addon* addon, int graphicsApiMode);
            int truss_openvr_shutdown(Addon* addon);
            const char* truss_openvr_get_last_error(Addon* addon);
            void* truss_openvr_get_system(Addon* addon);
            void* truss_openvr_get_chaperone(Addon* addon);
            void* truss_openvr_get_chaperonesetup(Addon* addon);
            void* truss_openvr_get_compositor(Addon* addon);
            void* truss_openvr_get_overlay(Addon* addon);
            void* truss_openvr_get_rendermodels(Addon* addon);
            void* truss_openvr_get_extendeddisplay(Addon* addon);
            void* truss_openvr_get_settings(Addon* addon);
            void* truss_openvr_get_applications(Addon* addon);
            void* truss_openvr_get_camera(Addon* addon);
            void* truss_openvr_get_input(Addon* addon);
    )";
    ivrsystem_ = NULL;
}

const std::string& OpenVRAddon::getName() {
    return name_;
}

const std::string& OpenVRAddon::getHeader() {
    return header_;
}

const std::string& OpenVRAddon::getVersion() {
    return version_;
}

void OpenVRAddon::init(truss::Interpreter* owner) {
    owner_ = owner;
}

void OpenVRAddon::shutdown() {
    shutdownVR();
}

void OpenVRAddon::update(double dt) {
    // Nothing to do
}

int OpenVRAddon::shutdownVR() {
    if(NULL != ivrsystem_) {
        vr::VR_Shutdown();
        ivrsystem_ = NULL;
    }
    return 1;
}

int OpenVRAddon::initVR(int graphicsApiMode) {
    if(NULL != ivrsystem_) {
        shutdownVR();
    }

    // Loading the SteamVR Runtime
    vr::EVRInitError eError = vr::VRInitError_None;
	if (graphicsApiMode == 0) {
		ivrsystem_ = vr::VR_Init(&eError, vr::VRApplication_Other);
	} else if (graphicsApiMode == 1) {
		ivrsystem_ = vr::VR_Init(&eError, vr::VRApplication_Scene);
	} else {
		ivrsystem_ = vr::VR_Init(&eError, vr::VRApplication_Overlay);
	}

    if ( eError != vr::VRInitError_None ) {
        ivrsystem_ = NULL;
        lastError_ = vr::VR_GetVRInitErrorAsEnglishDescription( eError );
        return 0;
    } else {
        return 1;
    }
}

OpenVRAddon::~OpenVRAddon() {
    shutdown();
}

int truss_openvr_init(OpenVRAddon* addon, int graphicsApiMode) {
    return addon->initVR(graphicsApiMode);
}

int truss_openvr_shutdown(OpenVRAddon* addon) {
    return addon->shutdownVR();
}

const char* truss_openvr_get_last_error(OpenVRAddon* addon) {
    return addon->lastError_.c_str();
}

void* truss_openvr_get_system(OpenVRAddon* addon) {
    return addon->ivrsystem_;
}

void* truss_openvr_get_chaperone(OpenVRAddon* addon) {
    if(NULL != addon->ivrsystem_) {
        return vr::VRChaperone();
    } else {
        return NULL;
    }
}

void* truss_openvr_get_chaperonesetup(OpenVRAddon* addon) {
    if(NULL != addon->ivrsystem_) {
        return vr::VRChaperoneSetup();
    } else {
        return NULL;
    }
}

void* truss_openvr_get_compositor(OpenVRAddon* addon) {
    if(NULL != addon->ivrsystem_) {
        return vr::VRCompositor();
    } else {
        return NULL;
    }
}

void* truss_openvr_get_overlay(OpenVRAddon* addon) {
    if(NULL != addon->ivrsystem_) {
        return vr::VROverlay();
    } else {
        return NULL;
    }
}

void* truss_openvr_get_rendermodels(OpenVRAddon* addon) {
    if(NULL != addon->ivrsystem_) {
        return vr::VRRenderModels();
    } else {
        return NULL;
    }
}

void* truss_openvr_get_extendeddisplay(OpenVRAddon* addon) {
    if(NULL != addon->ivrsystem_) {
        return vr::VRExtendedDisplay();
    } else {
        return NULL;
    }
}

void* truss_openvr_get_settings(OpenVRAddon* addon) {
    if(NULL != addon->ivrsystem_) {
        return vr::VRSettings();
    } else {
        return NULL;
    }
}

void* truss_openvr_get_applications(OpenVRAddon* addon) {
    if(NULL != addon->ivrsystem_) {
        return vr::VRApplications();
    } else {
        return NULL;
    }
}

void* truss_openvr_get_camera(OpenVRAddon* addon) {
    if (NULL != addon->ivrsystem_) {
        return vr::VRTrackedCamera();
    }
    else {
        return NULL;
    }
}

void* truss_openvr_get_input(OpenVRAddon* addon) {
    if (NULL != addon->ivrsystem_) {
        return vr::VRInput();
    }
    else {
        return NULL;
    }
}    
}

