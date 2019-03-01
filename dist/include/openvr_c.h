// Mostly auto generated c api to openvr 1.0.6

#include <stdint.h>

typedef char bool;

// Need to declare these opaque types so we don't have to pass around void*
typedef struct IVRSystem IVRSystem;
typedef struct IVRChaperone IVRChaperone;
typedef struct IVRChaperoneSetup IVRChaperoneSetup;
typedef struct IVROverlay IVROverlay;
typedef struct IVRApplications IVRApplications;
typedef struct IVRCompositor IVRCompositor;
typedef struct IVRExtendedDisplay IVRExtendedDisplay;
typedef struct IVRSettings IVRSettings;
typedef struct IVRRenderModels IVRRenderModels;
typedef struct IVRNotifications IVRNotifications;
typedef struct IVRTrackedCamera IVRTrackedCamera;
typedef struct IVRScreenshots IVRScreenshots;
typedef struct IVRResources IVRResources;
typedef struct IVRInput IVRInput;
typedef struct IVRIOBuffer IVRIOBuffer;
typedef struct IVRSpatialAnchors IVRSpatialAnchors;
typedef struct IVRDriverManager IVRDriverManager;

// These were defined at the top for some reason, but duplicate
// definitions make me uncomfortable so let's not
/*
typedef uint64_t PropertyContainerHandle_t;
typedef uint32_t PropertyTypeTag_t;
typedef uint64_t VRActionHandle_t;
typedef uint64_t VRActionSetHandle_t;
typedef uint64_t VRInputValueHandle_t;
*/

// OpenVR Constants
// (in vr/constants.t)

// OpenVR Enums

typedef enum EVREye
{
	EVREye_Eye_Left = 0,
	EVREye_Eye_Right = 1,
} EVREye;

typedef enum ETextureType
{
	ETextureType_TextureType_Invalid = -1,
	ETextureType_TextureType_DirectX = 0,
	ETextureType_TextureType_OpenGL = 1,
	ETextureType_TextureType_Vulkan = 2,
	ETextureType_TextureType_IOSurface = 3,
	ETextureType_TextureType_DirectX12 = 4,
	ETextureType_TextureType_DXGISharedHandle = 5,
	ETextureType_TextureType_Metal = 6,
} ETextureType;

typedef enum EColorSpace
{
	EColorSpace_ColorSpace_Auto = 0,
	EColorSpace_ColorSpace_Gamma = 1,
	EColorSpace_ColorSpace_Linear = 2,
} EColorSpace;

typedef enum ETrackingResult
{
	ETrackingResult_TrackingResult_Uninitialized = 1,
	ETrackingResult_TrackingResult_Calibrating_InProgress = 100,
	ETrackingResult_TrackingResult_Calibrating_OutOfRange = 101,
	ETrackingResult_TrackingResult_Running_OK = 200,
	ETrackingResult_TrackingResult_Running_OutOfRange = 201,
	ETrackingResult_TrackingResult_Fallback_RotationOnly = 300,
} ETrackingResult;

typedef enum ETrackedDeviceClass
{
	ETrackedDeviceClass_TrackedDeviceClass_Invalid = 0,
	ETrackedDeviceClass_TrackedDeviceClass_HMD = 1,
	ETrackedDeviceClass_TrackedDeviceClass_Controller = 2,
	ETrackedDeviceClass_TrackedDeviceClass_GenericTracker = 3,
	ETrackedDeviceClass_TrackedDeviceClass_TrackingReference = 4,
	ETrackedDeviceClass_TrackedDeviceClass_DisplayRedirect = 5,
	ETrackedDeviceClass_TrackedDeviceClass_Max = 6,
} ETrackedDeviceClass;

typedef enum ETrackedControllerRole
{
	ETrackedControllerRole_TrackedControllerRole_Invalid = 0,
	ETrackedControllerRole_TrackedControllerRole_LeftHand = 1,
	ETrackedControllerRole_TrackedControllerRole_RightHand = 2,
	ETrackedControllerRole_TrackedControllerRole_OptOut = 3,
	ETrackedControllerRole_TrackedControllerRole_Treadmill = 4,
	ETrackedControllerRole_TrackedControllerRole_Max = 4,
} ETrackedControllerRole;

typedef enum ETrackingUniverseOrigin
{
	ETrackingUniverseOrigin_TrackingUniverseSeated = 0,
	ETrackingUniverseOrigin_TrackingUniverseStanding = 1,
	ETrackingUniverseOrigin_TrackingUniverseRawAndUncalibrated = 2,
} ETrackingUniverseOrigin;

typedef enum EAdditionalRadioFeatures
{
	EAdditionalRadioFeatures_AdditionalRadioFeatures_None = 0,
	EAdditionalRadioFeatures_AdditionalRadioFeatures_HTCLinkBox = 1,
	EAdditionalRadioFeatures_AdditionalRadioFeatures_InternalDongle = 2,
	EAdditionalRadioFeatures_AdditionalRadioFeatures_ExternalDongle = 4,
} EAdditionalRadioFeatures;

typedef enum ETrackedDeviceProperty
{
	ETrackedDeviceProperty_Prop_Invalid = 0,
	ETrackedDeviceProperty_Prop_TrackingSystemName_String = 1000,
	ETrackedDeviceProperty_Prop_ModelNumber_String = 1001,
	ETrackedDeviceProperty_Prop_SerialNumber_String = 1002,
	ETrackedDeviceProperty_Prop_RenderModelName_String = 1003,
	ETrackedDeviceProperty_Prop_WillDriftInYaw_Bool = 1004,
	ETrackedDeviceProperty_Prop_ManufacturerName_String = 1005,
	ETrackedDeviceProperty_Prop_TrackingFirmwareVersion_String = 1006,
	ETrackedDeviceProperty_Prop_HardwareRevision_String = 1007,
	ETrackedDeviceProperty_Prop_AllWirelessDongleDescriptions_String = 1008,
	ETrackedDeviceProperty_Prop_ConnectedWirelessDongle_String = 1009,
	ETrackedDeviceProperty_Prop_DeviceIsWireless_Bool = 1010,
	ETrackedDeviceProperty_Prop_DeviceIsCharging_Bool = 1011,
	ETrackedDeviceProperty_Prop_DeviceBatteryPercentage_Float = 1012,
	ETrackedDeviceProperty_Prop_StatusDisplayTransform_Matrix34 = 1013,
	ETrackedDeviceProperty_Prop_Firmware_UpdateAvailable_Bool = 1014,
	ETrackedDeviceProperty_Prop_Firmware_ManualUpdate_Bool = 1015,
	ETrackedDeviceProperty_Prop_Firmware_ManualUpdateURL_String = 1016,
	ETrackedDeviceProperty_Prop_HardwareRevision_Uint64 = 1017,
	ETrackedDeviceProperty_Prop_FirmwareVersion_Uint64 = 1018,
	ETrackedDeviceProperty_Prop_FPGAVersion_Uint64 = 1019,
	ETrackedDeviceProperty_Prop_VRCVersion_Uint64 = 1020,
	ETrackedDeviceProperty_Prop_RadioVersion_Uint64 = 1021,
	ETrackedDeviceProperty_Prop_DongleVersion_Uint64 = 1022,
	ETrackedDeviceProperty_Prop_BlockServerShutdown_Bool = 1023,
	ETrackedDeviceProperty_Prop_CanUnifyCoordinateSystemWithHmd_Bool = 1024,
	ETrackedDeviceProperty_Prop_ContainsProximitySensor_Bool = 1025,
	ETrackedDeviceProperty_Prop_DeviceProvidesBatteryStatus_Bool = 1026,
	ETrackedDeviceProperty_Prop_DeviceCanPowerOff_Bool = 1027,
	ETrackedDeviceProperty_Prop_Firmware_ProgrammingTarget_String = 1028,
	ETrackedDeviceProperty_Prop_DeviceClass_Int32 = 1029,
	ETrackedDeviceProperty_Prop_HasCamera_Bool = 1030,
	ETrackedDeviceProperty_Prop_DriverVersion_String = 1031,
	ETrackedDeviceProperty_Prop_Firmware_ForceUpdateRequired_Bool = 1032,
	ETrackedDeviceProperty_Prop_ViveSystemButtonFixRequired_Bool = 1033,
	ETrackedDeviceProperty_Prop_ParentDriver_Uint64 = 1034,
	ETrackedDeviceProperty_Prop_ResourceRoot_String = 1035,
	ETrackedDeviceProperty_Prop_RegisteredDeviceType_String = 1036,
	ETrackedDeviceProperty_Prop_InputProfilePath_String = 1037,
	ETrackedDeviceProperty_Prop_NeverTracked_Bool = 1038,
	ETrackedDeviceProperty_Prop_NumCameras_Int32 = 1039,
	ETrackedDeviceProperty_Prop_CameraFrameLayout_Int32 = 1040,
	ETrackedDeviceProperty_Prop_CameraStreamFormat_Int32 = 1041,
	ETrackedDeviceProperty_Prop_AdditionalDeviceSettingsPath_String = 1042,
	ETrackedDeviceProperty_Prop_Identifiable_Bool = 1043,
	ETrackedDeviceProperty_Prop_BootloaderVersion_Uint64 = 1044,
	ETrackedDeviceProperty_Prop_ReportsTimeSinceVSync_Bool = 2000,
	ETrackedDeviceProperty_Prop_SecondsFromVsyncToPhotons_Float = 2001,
	ETrackedDeviceProperty_Prop_DisplayFrequency_Float = 2002,
	ETrackedDeviceProperty_Prop_UserIpdMeters_Float = 2003,
	ETrackedDeviceProperty_Prop_CurrentUniverseId_Uint64 = 2004,
	ETrackedDeviceProperty_Prop_PreviousUniverseId_Uint64 = 2005,
	ETrackedDeviceProperty_Prop_DisplayFirmwareVersion_Uint64 = 2006,
	ETrackedDeviceProperty_Prop_IsOnDesktop_Bool = 2007,
	ETrackedDeviceProperty_Prop_DisplayMCType_Int32 = 2008,
	ETrackedDeviceProperty_Prop_DisplayMCOffset_Float = 2009,
	ETrackedDeviceProperty_Prop_DisplayMCScale_Float = 2010,
	ETrackedDeviceProperty_Prop_EdidVendorID_Int32 = 2011,
	ETrackedDeviceProperty_Prop_DisplayMCImageLeft_String = 2012,
	ETrackedDeviceProperty_Prop_DisplayMCImageRight_String = 2013,
	ETrackedDeviceProperty_Prop_DisplayGCBlackClamp_Float = 2014,
	ETrackedDeviceProperty_Prop_EdidProductID_Int32 = 2015,
	ETrackedDeviceProperty_Prop_CameraToHeadTransform_Matrix34 = 2016,
	ETrackedDeviceProperty_Prop_DisplayGCType_Int32 = 2017,
	ETrackedDeviceProperty_Prop_DisplayGCOffset_Float = 2018,
	ETrackedDeviceProperty_Prop_DisplayGCScale_Float = 2019,
	ETrackedDeviceProperty_Prop_DisplayGCPrescale_Float = 2020,
	ETrackedDeviceProperty_Prop_DisplayGCImage_String = 2021,
	ETrackedDeviceProperty_Prop_LensCenterLeftU_Float = 2022,
	ETrackedDeviceProperty_Prop_LensCenterLeftV_Float = 2023,
	ETrackedDeviceProperty_Prop_LensCenterRightU_Float = 2024,
	ETrackedDeviceProperty_Prop_LensCenterRightV_Float = 2025,
	ETrackedDeviceProperty_Prop_UserHeadToEyeDepthMeters_Float = 2026,
	ETrackedDeviceProperty_Prop_CameraFirmwareVersion_Uint64 = 2027,
	ETrackedDeviceProperty_Prop_CameraFirmwareDescription_String = 2028,
	ETrackedDeviceProperty_Prop_DisplayFPGAVersion_Uint64 = 2029,
	ETrackedDeviceProperty_Prop_DisplayBootloaderVersion_Uint64 = 2030,
	ETrackedDeviceProperty_Prop_DisplayHardwareVersion_Uint64 = 2031,
	ETrackedDeviceProperty_Prop_AudioFirmwareVersion_Uint64 = 2032,
	ETrackedDeviceProperty_Prop_CameraCompatibilityMode_Int32 = 2033,
	ETrackedDeviceProperty_Prop_ScreenshotHorizontalFieldOfViewDegrees_Float = 2034,
	ETrackedDeviceProperty_Prop_ScreenshotVerticalFieldOfViewDegrees_Float = 2035,
	ETrackedDeviceProperty_Prop_DisplaySuppressed_Bool = 2036,
	ETrackedDeviceProperty_Prop_DisplayAllowNightMode_Bool = 2037,
	ETrackedDeviceProperty_Prop_DisplayMCImageWidth_Int32 = 2038,
	ETrackedDeviceProperty_Prop_DisplayMCImageHeight_Int32 = 2039,
	ETrackedDeviceProperty_Prop_DisplayMCImageNumChannels_Int32 = 2040,
	ETrackedDeviceProperty_Prop_DisplayMCImageData_Binary = 2041,
	ETrackedDeviceProperty_Prop_SecondsFromPhotonsToVblank_Float = 2042,
	ETrackedDeviceProperty_Prop_DriverDirectModeSendsVsyncEvents_Bool = 2043,
	ETrackedDeviceProperty_Prop_DisplayDebugMode_Bool = 2044,
	ETrackedDeviceProperty_Prop_GraphicsAdapterLuid_Uint64 = 2045,
	ETrackedDeviceProperty_Prop_DriverProvidedChaperonePath_String = 2048,
	ETrackedDeviceProperty_Prop_ExpectedTrackingReferenceCount_Int32 = 2049,
	ETrackedDeviceProperty_Prop_ExpectedControllerCount_Int32 = 2050,
	ETrackedDeviceProperty_Prop_NamedIconPathControllerLeftDeviceOff_String = 2051,
	ETrackedDeviceProperty_Prop_NamedIconPathControllerRightDeviceOff_String = 2052,
	ETrackedDeviceProperty_Prop_NamedIconPathTrackingReferenceDeviceOff_String = 2053,
	ETrackedDeviceProperty_Prop_DoNotApplyPrediction_Bool = 2054,
	ETrackedDeviceProperty_Prop_CameraToHeadTransforms_Matrix34_Array = 2055,
	ETrackedDeviceProperty_Prop_DistortionMeshResolution_Int32 = 2056,
	ETrackedDeviceProperty_Prop_DriverIsDrawingControllers_Bool = 2057,
	ETrackedDeviceProperty_Prop_DriverRequestsApplicationPause_Bool = 2058,
	ETrackedDeviceProperty_Prop_DriverRequestsReducedRendering_Bool = 2059,
	ETrackedDeviceProperty_Prop_MinimumIpdStepMeters_Float = 2060,
	ETrackedDeviceProperty_Prop_AudioBridgeFirmwareVersion_Uint64 = 2061,
	ETrackedDeviceProperty_Prop_ImageBridgeFirmwareVersion_Uint64 = 2062,
	ETrackedDeviceProperty_Prop_ImuToHeadTransform_Matrix34 = 2063,
	ETrackedDeviceProperty_Prop_ImuFactoryGyroBias_Vector3 = 2064,
	ETrackedDeviceProperty_Prop_ImuFactoryGyroScale_Vector3 = 2065,
	ETrackedDeviceProperty_Prop_ImuFactoryAccelerometerBias_Vector3 = 2066,
	ETrackedDeviceProperty_Prop_ImuFactoryAccelerometerScale_Vector3 = 2067,
	ETrackedDeviceProperty_Prop_ConfigurationIncludesLighthouse20Features_Bool = 2069,
	ETrackedDeviceProperty_Prop_AdditionalRadioFeatures_Uint64 = 2070,
	ETrackedDeviceProperty_Prop_CameraWhiteBalance_Vector4_Array = 2071,
	ETrackedDeviceProperty_Prop_CameraDistortionFunction_Int32_Array = 2072,
	ETrackedDeviceProperty_Prop_CameraDistortionCoefficients_Float_Array = 2073,
	ETrackedDeviceProperty_Prop_ExpectedControllerType_String = 2074,
	ETrackedDeviceProperty_Prop_DriverRequestedMuraCorrectionMode_Int32 = 2200,
	ETrackedDeviceProperty_Prop_DriverRequestedMuraFeather_InnerLeft_Int32 = 2201,
	ETrackedDeviceProperty_Prop_DriverRequestedMuraFeather_InnerRight_Int32 = 2202,
	ETrackedDeviceProperty_Prop_DriverRequestedMuraFeather_InnerTop_Int32 = 2203,
	ETrackedDeviceProperty_Prop_DriverRequestedMuraFeather_InnerBottom_Int32 = 2204,
	ETrackedDeviceProperty_Prop_DriverRequestedMuraFeather_OuterLeft_Int32 = 2205,
	ETrackedDeviceProperty_Prop_DriverRequestedMuraFeather_OuterRight_Int32 = 2206,
	ETrackedDeviceProperty_Prop_DriverRequestedMuraFeather_OuterTop_Int32 = 2207,
	ETrackedDeviceProperty_Prop_DriverRequestedMuraFeather_OuterBottom_Int32 = 2208,
	ETrackedDeviceProperty_Prop_AttachedDeviceId_String = 3000,
	ETrackedDeviceProperty_Prop_SupportedButtons_Uint64 = 3001,
	ETrackedDeviceProperty_Prop_Axis0Type_Int32 = 3002,
	ETrackedDeviceProperty_Prop_Axis1Type_Int32 = 3003,
	ETrackedDeviceProperty_Prop_Axis2Type_Int32 = 3004,
	ETrackedDeviceProperty_Prop_Axis3Type_Int32 = 3005,
	ETrackedDeviceProperty_Prop_Axis4Type_Int32 = 3006,
	ETrackedDeviceProperty_Prop_ControllerRoleHint_Int32 = 3007,
	ETrackedDeviceProperty_Prop_FieldOfViewLeftDegrees_Float = 4000,
	ETrackedDeviceProperty_Prop_FieldOfViewRightDegrees_Float = 4001,
	ETrackedDeviceProperty_Prop_FieldOfViewTopDegrees_Float = 4002,
	ETrackedDeviceProperty_Prop_FieldOfViewBottomDegrees_Float = 4003,
	ETrackedDeviceProperty_Prop_TrackingRangeMinimumMeters_Float = 4004,
	ETrackedDeviceProperty_Prop_TrackingRangeMaximumMeters_Float = 4005,
	ETrackedDeviceProperty_Prop_ModeLabel_String = 4006,
	ETrackedDeviceProperty_Prop_IconPathName_String = 5000,
	ETrackedDeviceProperty_Prop_NamedIconPathDeviceOff_String = 5001,
	ETrackedDeviceProperty_Prop_NamedIconPathDeviceSearching_String = 5002,
	ETrackedDeviceProperty_Prop_NamedIconPathDeviceSearchingAlert_String = 5003,
	ETrackedDeviceProperty_Prop_NamedIconPathDeviceReady_String = 5004,
	ETrackedDeviceProperty_Prop_NamedIconPathDeviceReadyAlert_String = 5005,
	ETrackedDeviceProperty_Prop_NamedIconPathDeviceNotReady_String = 5006,
	ETrackedDeviceProperty_Prop_NamedIconPathDeviceStandby_String = 5007,
	ETrackedDeviceProperty_Prop_NamedIconPathDeviceAlertLow_String = 5008,
	ETrackedDeviceProperty_Prop_DisplayHiddenArea_Binary_Start = 5100,
	ETrackedDeviceProperty_Prop_DisplayHiddenArea_Binary_End = 5150,
	ETrackedDeviceProperty_Prop_ParentContainer = 5151,
	ETrackedDeviceProperty_Prop_UserConfigPath_String = 6000,
	ETrackedDeviceProperty_Prop_InstallPath_String = 6001,
	ETrackedDeviceProperty_Prop_HasDisplayComponent_Bool = 6002,
	ETrackedDeviceProperty_Prop_HasControllerComponent_Bool = 6003,
	ETrackedDeviceProperty_Prop_HasCameraComponent_Bool = 6004,
	ETrackedDeviceProperty_Prop_HasDriverDirectModeComponent_Bool = 6005,
	ETrackedDeviceProperty_Prop_HasVirtualDisplayComponent_Bool = 6006,
	ETrackedDeviceProperty_Prop_HasSpatialAnchorsSupport_Bool = 6007,
	ETrackedDeviceProperty_Prop_ControllerType_String = 7000,
	ETrackedDeviceProperty_Prop_LegacyInputProfile_String = 7001,
	ETrackedDeviceProperty_Prop_ControllerHandSelectionPriority_Int32 = 7002,
	ETrackedDeviceProperty_Prop_VendorSpecific_Reserved_Start = 10000,
	ETrackedDeviceProperty_Prop_VendorSpecific_Reserved_End = 10999,
	ETrackedDeviceProperty_Prop_TrackedDeviceProperty_Max = 1000000,
} ETrackedDeviceProperty;

typedef enum ETrackedPropertyError
{
	ETrackedPropertyError_TrackedProp_Success = 0,
	ETrackedPropertyError_TrackedProp_WrongDataType = 1,
	ETrackedPropertyError_TrackedProp_WrongDeviceClass = 2,
	ETrackedPropertyError_TrackedProp_BufferTooSmall = 3,
	ETrackedPropertyError_TrackedProp_UnknownProperty = 4,
	ETrackedPropertyError_TrackedProp_InvalidDevice = 5,
	ETrackedPropertyError_TrackedProp_CouldNotContactServer = 6,
	ETrackedPropertyError_TrackedProp_ValueNotProvidedByDevice = 7,
	ETrackedPropertyError_TrackedProp_StringExceedsMaximumLength = 8,
	ETrackedPropertyError_TrackedProp_NotYetAvailable = 9,
	ETrackedPropertyError_TrackedProp_PermissionDenied = 10,
	ETrackedPropertyError_TrackedProp_InvalidOperation = 11,
	ETrackedPropertyError_TrackedProp_CannotWriteToWildcards = 12,
	ETrackedPropertyError_TrackedProp_IPCReadFailure = 13,
} ETrackedPropertyError;

typedef enum EVRSubmitFlags
{
	EVRSubmitFlags_Submit_Default = 0,
	EVRSubmitFlags_Submit_LensDistortionAlreadyApplied = 1,
	EVRSubmitFlags_Submit_GlRenderBuffer = 2,
	EVRSubmitFlags_Submit_Reserved = 4,
	EVRSubmitFlags_Submit_TextureWithPose = 8,
	EVRSubmitFlags_Submit_TextureWithDepth = 16,
} EVRSubmitFlags;

typedef enum EVRState
{
	EVRState_VRState_Undefined = -1,
	EVRState_VRState_Off = 0,
	EVRState_VRState_Searching = 1,
	EVRState_VRState_Searching_Alert = 2,
	EVRState_VRState_Ready = 3,
	EVRState_VRState_Ready_Alert = 4,
	EVRState_VRState_NotReady = 5,
	EVRState_VRState_Standby = 6,
	EVRState_VRState_Ready_Alert_Low = 7,
} EVRState;

typedef enum EVREventType
{
	EVREventType_VREvent_None = 0,
	EVREventType_VREvent_TrackedDeviceActivated = 100,
	EVREventType_VREvent_TrackedDeviceDeactivated = 101,
	EVREventType_VREvent_TrackedDeviceUpdated = 102,
	EVREventType_VREvent_TrackedDeviceUserInteractionStarted = 103,
	EVREventType_VREvent_TrackedDeviceUserInteractionEnded = 104,
	EVREventType_VREvent_IpdChanged = 105,
	EVREventType_VREvent_EnterStandbyMode = 106,
	EVREventType_VREvent_LeaveStandbyMode = 107,
	EVREventType_VREvent_TrackedDeviceRoleChanged = 108,
	EVREventType_VREvent_WatchdogWakeUpRequested = 109,
	EVREventType_VREvent_LensDistortionChanged = 110,
	EVREventType_VREvent_PropertyChanged = 111,
	EVREventType_VREvent_WirelessDisconnect = 112,
	EVREventType_VREvent_WirelessReconnect = 113,
	EVREventType_VREvent_ButtonPress = 200,
	EVREventType_VREvent_ButtonUnpress = 201,
	EVREventType_VREvent_ButtonTouch = 202,
	EVREventType_VREvent_ButtonUntouch = 203,
	EVREventType_VREvent_DualAnalog_Press = 250,
	EVREventType_VREvent_DualAnalog_Unpress = 251,
	EVREventType_VREvent_DualAnalog_Touch = 252,
	EVREventType_VREvent_DualAnalog_Untouch = 253,
	EVREventType_VREvent_DualAnalog_Move = 254,
	EVREventType_VREvent_DualAnalog_ModeSwitch1 = 255,
	EVREventType_VREvent_DualAnalog_ModeSwitch2 = 256,
	EVREventType_VREvent_DualAnalog_Cancel = 257,
	EVREventType_VREvent_MouseMove = 300,
	EVREventType_VREvent_MouseButtonDown = 301,
	EVREventType_VREvent_MouseButtonUp = 302,
	EVREventType_VREvent_FocusEnter = 303,
	EVREventType_VREvent_FocusLeave = 304,
	EVREventType_VREvent_ScrollDiscrete = 305,
	EVREventType_VREvent_TouchPadMove = 306,
	EVREventType_VREvent_OverlayFocusChanged = 307,
	EVREventType_VREvent_ReloadOverlays = 308,
	EVREventType_VREvent_ScrollSmooth = 309,
	EVREventType_VREvent_InputFocusCaptured = 400,
	EVREventType_VREvent_InputFocusReleased = 401,
	EVREventType_VREvent_SceneFocusLost = 402,
	EVREventType_VREvent_SceneFocusGained = 403,
	EVREventType_VREvent_SceneApplicationChanged = 404,
	EVREventType_VREvent_SceneFocusChanged = 405,
	EVREventType_VREvent_InputFocusChanged = 406,
	EVREventType_VREvent_SceneApplicationSecondaryRenderingStarted = 407,
	EVREventType_VREvent_SceneApplicationUsingWrongGraphicsAdapter = 408,
	EVREventType_VREvent_ActionBindingReloaded = 409,
	EVREventType_VREvent_HideRenderModels = 410,
	EVREventType_VREvent_ShowRenderModels = 411,
	EVREventType_VREvent_ConsoleOpened = 420,
	EVREventType_VREvent_ConsoleClosed = 421,
	EVREventType_VREvent_OverlayShown = 500,
	EVREventType_VREvent_OverlayHidden = 501,
	EVREventType_VREvent_DashboardActivated = 502,
	EVREventType_VREvent_DashboardDeactivated = 503,
	EVREventType_VREvent_DashboardThumbSelected = 504,
	EVREventType_VREvent_DashboardRequested = 505,
	EVREventType_VREvent_ResetDashboard = 506,
	EVREventType_VREvent_RenderToast = 507,
	EVREventType_VREvent_ImageLoaded = 508,
	EVREventType_VREvent_ShowKeyboard = 509,
	EVREventType_VREvent_HideKeyboard = 510,
	EVREventType_VREvent_OverlayGamepadFocusGained = 511,
	EVREventType_VREvent_OverlayGamepadFocusLost = 512,
	EVREventType_VREvent_OverlaySharedTextureChanged = 513,
	EVREventType_VREvent_ScreenshotTriggered = 516,
	EVREventType_VREvent_ImageFailed = 517,
	EVREventType_VREvent_DashboardOverlayCreated = 518,
	EVREventType_VREvent_SwitchGamepadFocus = 519,
	EVREventType_VREvent_RequestScreenshot = 520,
	EVREventType_VREvent_ScreenshotTaken = 521,
	EVREventType_VREvent_ScreenshotFailed = 522,
	EVREventType_VREvent_SubmitScreenshotToDashboard = 523,
	EVREventType_VREvent_ScreenshotProgressToDashboard = 524,
	EVREventType_VREvent_PrimaryDashboardDeviceChanged = 525,
	EVREventType_VREvent_RoomViewShown = 526,
	EVREventType_VREvent_RoomViewHidden = 527,
	EVREventType_VREvent_ShowUI = 528,
	EVREventType_VREvent_Notification_Shown = 600,
	EVREventType_VREvent_Notification_Hidden = 601,
	EVREventType_VREvent_Notification_BeginInteraction = 602,
	EVREventType_VREvent_Notification_Destroyed = 603,
	EVREventType_VREvent_Quit = 700,
	EVREventType_VREvent_ProcessQuit = 701,
	EVREventType_VREvent_QuitAborted_UserPrompt = 702,
	EVREventType_VREvent_QuitAcknowledged = 703,
	EVREventType_VREvent_DriverRequestedQuit = 704,
	EVREventType_VREvent_ChaperoneDataHasChanged = 800,
	EVREventType_VREvent_ChaperoneUniverseHasChanged = 801,
	EVREventType_VREvent_ChaperoneTempDataHasChanged = 802,
	EVREventType_VREvent_ChaperoneSettingsHaveChanged = 803,
	EVREventType_VREvent_SeatedZeroPoseReset = 804,
	EVREventType_VREvent_ChaperoneFlushCache = 805,
	EVREventType_VREvent_AudioSettingsHaveChanged = 820,
	EVREventType_VREvent_BackgroundSettingHasChanged = 850,
	EVREventType_VREvent_CameraSettingsHaveChanged = 851,
	EVREventType_VREvent_ReprojectionSettingHasChanged = 852,
	EVREventType_VREvent_ModelSkinSettingsHaveChanged = 853,
	EVREventType_VREvent_EnvironmentSettingsHaveChanged = 854,
	EVREventType_VREvent_PowerSettingsHaveChanged = 855,
	EVREventType_VREvent_EnableHomeAppSettingsHaveChanged = 856,
	EVREventType_VREvent_SteamVRSectionSettingChanged = 857,
	EVREventType_VREvent_LighthouseSectionSettingChanged = 858,
	EVREventType_VREvent_NullSectionSettingChanged = 859,
	EVREventType_VREvent_UserInterfaceSectionSettingChanged = 860,
	EVREventType_VREvent_NotificationsSectionSettingChanged = 861,
	EVREventType_VREvent_KeyboardSectionSettingChanged = 862,
	EVREventType_VREvent_PerfSectionSettingChanged = 863,
	EVREventType_VREvent_DashboardSectionSettingChanged = 864,
	EVREventType_VREvent_WebInterfaceSectionSettingChanged = 865,
	EVREventType_VREvent_TrackersSectionSettingChanged = 866,
	EVREventType_VREvent_LastKnownSectionSettingChanged = 867,
	EVREventType_VREvent_DismissedWarningsSectionSettingChanged = 868,
	EVREventType_VREvent_StatusUpdate = 900,
	EVREventType_VREvent_WebInterface_InstallDriverCompleted = 950,
	EVREventType_VREvent_MCImageUpdated = 1000,
	EVREventType_VREvent_FirmwareUpdateStarted = 1100,
	EVREventType_VREvent_FirmwareUpdateFinished = 1101,
	EVREventType_VREvent_KeyboardClosed = 1200,
	EVREventType_VREvent_KeyboardCharInput = 1201,
	EVREventType_VREvent_KeyboardDone = 1202,
	EVREventType_VREvent_ApplicationTransitionStarted = 1300,
	EVREventType_VREvent_ApplicationTransitionAborted = 1301,
	EVREventType_VREvent_ApplicationTransitionNewAppStarted = 1302,
	EVREventType_VREvent_ApplicationListUpdated = 1303,
	EVREventType_VREvent_ApplicationMimeTypeLoad = 1304,
	EVREventType_VREvent_ApplicationTransitionNewAppLaunchComplete = 1305,
	EVREventType_VREvent_ProcessConnected = 1306,
	EVREventType_VREvent_ProcessDisconnected = 1307,
	EVREventType_VREvent_Compositor_MirrorWindowShown = 1400,
	EVREventType_VREvent_Compositor_MirrorWindowHidden = 1401,
	EVREventType_VREvent_Compositor_ChaperoneBoundsShown = 1410,
	EVREventType_VREvent_Compositor_ChaperoneBoundsHidden = 1411,
	EVREventType_VREvent_TrackedCamera_StartVideoStream = 1500,
	EVREventType_VREvent_TrackedCamera_StopVideoStream = 1501,
	EVREventType_VREvent_TrackedCamera_PauseVideoStream = 1502,
	EVREventType_VREvent_TrackedCamera_ResumeVideoStream = 1503,
	EVREventType_VREvent_TrackedCamera_EditingSurface = 1550,
	EVREventType_VREvent_PerformanceTest_EnableCapture = 1600,
	EVREventType_VREvent_PerformanceTest_DisableCapture = 1601,
	EVREventType_VREvent_PerformanceTest_FidelityLevel = 1602,
	EVREventType_VREvent_MessageOverlay_Closed = 1650,
	EVREventType_VREvent_MessageOverlayCloseRequested = 1651,
	EVREventType_VREvent_Input_HapticVibration = 1700,
	EVREventType_VREvent_Input_BindingLoadFailed = 1701,
	EVREventType_VREvent_Input_BindingLoadSuccessful = 1702,
	EVREventType_VREvent_Input_ActionManifestReloaded = 1703,
	EVREventType_VREvent_Input_ActionManifestLoadFailed = 1704,
	EVREventType_VREvent_Input_ProgressUpdate = 1705,
	EVREventType_VREvent_Input_TrackerActivated = 1706,
	EVREventType_VREvent_Input_BindingsUpdated = 1707,
	EVREventType_VREvent_SpatialAnchors_PoseUpdated = 1800,
	EVREventType_VREvent_SpatialAnchors_DescriptorUpdated = 1801,
	EVREventType_VREvent_SpatialAnchors_RequestPoseUpdate = 1802,
	EVREventType_VREvent_SpatialAnchors_RequestDescriptorUpdate = 1803,
	EVREventType_VREvent_VendorSpecific_Reserved_Start = 10000,
	EVREventType_VREvent_VendorSpecific_Reserved_End = 19999,
} EVREventType;

typedef enum EDeviceActivityLevel
{
	EDeviceActivityLevel_k_EDeviceActivityLevel_Unknown = -1,
	EDeviceActivityLevel_k_EDeviceActivityLevel_Idle = 0,
	EDeviceActivityLevel_k_EDeviceActivityLevel_UserInteraction = 1,
	EDeviceActivityLevel_k_EDeviceActivityLevel_UserInteraction_Timeout = 2,
	EDeviceActivityLevel_k_EDeviceActivityLevel_Standby = 3,
} EDeviceActivityLevel;

typedef enum EVRButtonId
{
	EVRButtonId_k_EButton_System = 0,
	EVRButtonId_k_EButton_ApplicationMenu = 1,
	EVRButtonId_k_EButton_Grip = 2,
	EVRButtonId_k_EButton_DPad_Left = 3,
	EVRButtonId_k_EButton_DPad_Up = 4,
	EVRButtonId_k_EButton_DPad_Right = 5,
	EVRButtonId_k_EButton_DPad_Down = 6,
	EVRButtonId_k_EButton_A = 7,
	EVRButtonId_k_EButton_ProximitySensor = 31,
	EVRButtonId_k_EButton_Axis0 = 32,
	EVRButtonId_k_EButton_Axis1 = 33,
	EVRButtonId_k_EButton_Axis2 = 34,
	EVRButtonId_k_EButton_Axis3 = 35,
	EVRButtonId_k_EButton_Axis4 = 36,
	EVRButtonId_k_EButton_SteamVR_Touchpad = 32,
	EVRButtonId_k_EButton_SteamVR_Trigger = 33,
	EVRButtonId_k_EButton_Dashboard_Back = 2,
	EVRButtonId_k_EButton_Knuckles_A = 2,
	EVRButtonId_k_EButton_Knuckles_B = 1,
	EVRButtonId_k_EButton_Knuckles_JoyStick = 35,
	EVRButtonId_k_EButton_Max = 64,
} EVRButtonId;

typedef enum EVRMouseButton
{
	EVRMouseButton_VRMouseButton_Left = 1,
	EVRMouseButton_VRMouseButton_Right = 2,
	EVRMouseButton_VRMouseButton_Middle = 4,
} EVRMouseButton;

typedef enum EDualAnalogWhich
{
	EDualAnalogWhich_k_EDualAnalog_Left = 0,
	EDualAnalogWhich_k_EDualAnalog_Right = 1,
} EDualAnalogWhich;

typedef enum EShowUIType
{
	EShowUIType_ShowUI_ControllerBinding = 0,
	EShowUIType_ShowUI_ManageTrackers = 1,
	EShowUIType_ShowUI_QuickStart = 2,
	EShowUIType_ShowUI_Pairing = 3,
} EShowUIType;

typedef enum EVRInputError
{
	EVRInputError_VRInputError_None = 0,
	EVRInputError_VRInputError_NameNotFound = 1,
	EVRInputError_VRInputError_WrongType = 2,
	EVRInputError_VRInputError_InvalidHandle = 3,
	EVRInputError_VRInputError_InvalidParam = 4,
	EVRInputError_VRInputError_NoSteam = 5,
	EVRInputError_VRInputError_MaxCapacityReached = 6,
	EVRInputError_VRInputError_IPCError = 7,
	EVRInputError_VRInputError_NoActiveActionSet = 8,
	EVRInputError_VRInputError_InvalidDevice = 9,
	EVRInputError_VRInputError_InvalidSkeleton = 10,
	EVRInputError_VRInputError_InvalidBoneCount = 11,
	EVRInputError_VRInputError_InvalidCompressedData = 12,
	EVRInputError_VRInputError_NoData = 13,
	EVRInputError_VRInputError_BufferTooSmall = 14,
	EVRInputError_VRInputError_MismatchedActionManifest = 15,
	EVRInputError_VRInputError_MissingSkeletonData = 16,
	EVRInputError_VRInputError_InvalidBoneIndex = 17,
} EVRInputError;

typedef enum EVRSpatialAnchorError
{
	EVRSpatialAnchorError_VRSpatialAnchorError_Success = 0,
	EVRSpatialAnchorError_VRSpatialAnchorError_Internal = 1,
	EVRSpatialAnchorError_VRSpatialAnchorError_UnknownHandle = 2,
	EVRSpatialAnchorError_VRSpatialAnchorError_ArrayTooSmall = 3,
	EVRSpatialAnchorError_VRSpatialAnchorError_InvalidDescriptorChar = 4,
	EVRSpatialAnchorError_VRSpatialAnchorError_NotYetAvailable = 5,
	EVRSpatialAnchorError_VRSpatialAnchorError_NotAvailableInThisUniverse = 6,
	EVRSpatialAnchorError_VRSpatialAnchorError_PermanentlyUnavailable = 7,
	EVRSpatialAnchorError_VRSpatialAnchorError_WrongDriver = 8,
	EVRSpatialAnchorError_VRSpatialAnchorError_DescriptorTooLong = 9,
	EVRSpatialAnchorError_VRSpatialAnchorError_Unknown = 10,
	EVRSpatialAnchorError_VRSpatialAnchorError_NoRoomCalibration = 11,
	EVRSpatialAnchorError_VRSpatialAnchorError_InvalidArgument = 12,
	EVRSpatialAnchorError_VRSpatialAnchorError_UnknownDriver = 13,
} EVRSpatialAnchorError;

typedef enum EHiddenAreaMeshType
{
	EHiddenAreaMeshType_k_eHiddenAreaMesh_Standard = 0,
	EHiddenAreaMeshType_k_eHiddenAreaMesh_Inverse = 1,
	EHiddenAreaMeshType_k_eHiddenAreaMesh_LineLoop = 2,
	EHiddenAreaMeshType_k_eHiddenAreaMesh_Max = 3,
} EHiddenAreaMeshType;

typedef enum EVRControllerAxisType
{
	EVRControllerAxisType_k_eControllerAxis_None = 0,
	EVRControllerAxisType_k_eControllerAxis_TrackPad = 1,
	EVRControllerAxisType_k_eControllerAxis_Joystick = 2,
	EVRControllerAxisType_k_eControllerAxis_Trigger = 3,
} EVRControllerAxisType;

typedef enum EVRControllerEventOutputType
{
	EVRControllerEventOutputType_ControllerEventOutput_OSEvents = 0,
	EVRControllerEventOutputType_ControllerEventOutput_VREvents = 1,
} EVRControllerEventOutputType;

typedef enum ECollisionBoundsStyle
{
	ECollisionBoundsStyle_COLLISION_BOUNDS_STYLE_BEGINNER = 0,
	ECollisionBoundsStyle_COLLISION_BOUNDS_STYLE_INTERMEDIATE = 1,
	ECollisionBoundsStyle_COLLISION_BOUNDS_STYLE_SQUARES = 2,
	ECollisionBoundsStyle_COLLISION_BOUNDS_STYLE_ADVANCED = 3,
	ECollisionBoundsStyle_COLLISION_BOUNDS_STYLE_NONE = 4,
	ECollisionBoundsStyle_COLLISION_BOUNDS_STYLE_COUNT = 5,
} ECollisionBoundsStyle;

typedef enum EVROverlayError
{
	EVROverlayError_VROverlayError_None = 0,
	EVROverlayError_VROverlayError_UnknownOverlay = 10,
	EVROverlayError_VROverlayError_InvalidHandle = 11,
	EVROverlayError_VROverlayError_PermissionDenied = 12,
	EVROverlayError_VROverlayError_OverlayLimitExceeded = 13,
	EVROverlayError_VROverlayError_WrongVisibilityType = 14,
	EVROverlayError_VROverlayError_KeyTooLong = 15,
	EVROverlayError_VROverlayError_NameTooLong = 16,
	EVROverlayError_VROverlayError_KeyInUse = 17,
	EVROverlayError_VROverlayError_WrongTransformType = 18,
	EVROverlayError_VROverlayError_InvalidTrackedDevice = 19,
	EVROverlayError_VROverlayError_InvalidParameter = 20,
	EVROverlayError_VROverlayError_ThumbnailCantBeDestroyed = 21,
	EVROverlayError_VROverlayError_ArrayTooSmall = 22,
	EVROverlayError_VROverlayError_RequestFailed = 23,
	EVROverlayError_VROverlayError_InvalidTexture = 24,
	EVROverlayError_VROverlayError_UnableToLoadFile = 25,
	EVROverlayError_VROverlayError_KeyboardAlreadyInUse = 26,
	EVROverlayError_VROverlayError_NoNeighbor = 27,
	EVROverlayError_VROverlayError_TooManyMaskPrimitives = 29,
	EVROverlayError_VROverlayError_BadMaskPrimitive = 30,
	EVROverlayError_VROverlayError_TextureAlreadyLocked = 31,
	EVROverlayError_VROverlayError_TextureLockCapacityReached = 32,
	EVROverlayError_VROverlayError_TextureNotLocked = 33,
} EVROverlayError;

typedef enum EVRApplicationType
{
	EVRApplicationType_VRApplication_Other = 0,
	EVRApplicationType_VRApplication_Scene = 1,
	EVRApplicationType_VRApplication_Overlay = 2,
	EVRApplicationType_VRApplication_Background = 3,
	EVRApplicationType_VRApplication_Utility = 4,
	EVRApplicationType_VRApplication_VRMonitor = 5,
	EVRApplicationType_VRApplication_SteamWatchdog = 6,
	EVRApplicationType_VRApplication_Bootstrapper = 7,
	EVRApplicationType_VRApplication_WebHelper = 8,
	EVRApplicationType_VRApplication_Max = 9,
} EVRApplicationType;

typedef enum EVRFirmwareError
{
	EVRFirmwareError_VRFirmwareError_None = 0,
	EVRFirmwareError_VRFirmwareError_Success = 1,
	EVRFirmwareError_VRFirmwareError_Fail = 2,
} EVRFirmwareError;

typedef enum EVRNotificationError
{
	EVRNotificationError_VRNotificationError_OK = 0,
	EVRNotificationError_VRNotificationError_InvalidNotificationId = 100,
	EVRNotificationError_VRNotificationError_NotificationQueueFull = 101,
	EVRNotificationError_VRNotificationError_InvalidOverlayHandle = 102,
	EVRNotificationError_VRNotificationError_SystemWithUserValueAlreadyExists = 103,
} EVRNotificationError;

typedef enum EVRSkeletalMotionRange
{
	EVRSkeletalMotionRange_VRSkeletalMotionRange_WithController = 0,
	EVRSkeletalMotionRange_VRSkeletalMotionRange_WithoutController = 1,
} EVRSkeletalMotionRange;

typedef enum EVRSkeletalTrackingLevel
{
	EVRSkeletalTrackingLevel_VRSkeletalTracking_Estimated = 0,
	EVRSkeletalTrackingLevel_VRSkeletalTracking_Partial = 1,
	EVRSkeletalTrackingLevel_VRSkeletalTracking_Full = 2,
	EVRSkeletalTrackingLevel_VRSkeletalTrackingLevel_Count = 3,
	EVRSkeletalTrackingLevel_VRSkeletalTrackingLevel_Max = 2,
} EVRSkeletalTrackingLevel;

typedef enum EVRInitError
{
	EVRInitError_VRInitError_None = 0,
	EVRInitError_VRInitError_Unknown = 1,
	EVRInitError_VRInitError_Init_InstallationNotFound = 100,
	EVRInitError_VRInitError_Init_InstallationCorrupt = 101,
	EVRInitError_VRInitError_Init_VRClientDLLNotFound = 102,
	EVRInitError_VRInitError_Init_FileNotFound = 103,
	EVRInitError_VRInitError_Init_FactoryNotFound = 104,
	EVRInitError_VRInitError_Init_InterfaceNotFound = 105,
	EVRInitError_VRInitError_Init_InvalidInterface = 106,
	EVRInitError_VRInitError_Init_UserConfigDirectoryInvalid = 107,
	EVRInitError_VRInitError_Init_HmdNotFound = 108,
	EVRInitError_VRInitError_Init_NotInitialized = 109,
	EVRInitError_VRInitError_Init_PathRegistryNotFound = 110,
	EVRInitError_VRInitError_Init_NoConfigPath = 111,
	EVRInitError_VRInitError_Init_NoLogPath = 112,
	EVRInitError_VRInitError_Init_PathRegistryNotWritable = 113,
	EVRInitError_VRInitError_Init_AppInfoInitFailed = 114,
	EVRInitError_VRInitError_Init_Retry = 115,
	EVRInitError_VRInitError_Init_InitCanceledByUser = 116,
	EVRInitError_VRInitError_Init_AnotherAppLaunching = 117,
	EVRInitError_VRInitError_Init_SettingsInitFailed = 118,
	EVRInitError_VRInitError_Init_ShuttingDown = 119,
	EVRInitError_VRInitError_Init_TooManyObjects = 120,
	EVRInitError_VRInitError_Init_NoServerForBackgroundApp = 121,
	EVRInitError_VRInitError_Init_NotSupportedWithCompositor = 122,
	EVRInitError_VRInitError_Init_NotAvailableToUtilityApps = 123,
	EVRInitError_VRInitError_Init_Internal = 124,
	EVRInitError_VRInitError_Init_HmdDriverIdIsNone = 125,
	EVRInitError_VRInitError_Init_HmdNotFoundPresenceFailed = 126,
	EVRInitError_VRInitError_Init_VRMonitorNotFound = 127,
	EVRInitError_VRInitError_Init_VRMonitorStartupFailed = 128,
	EVRInitError_VRInitError_Init_LowPowerWatchdogNotSupported = 129,
	EVRInitError_VRInitError_Init_InvalidApplicationType = 130,
	EVRInitError_VRInitError_Init_NotAvailableToWatchdogApps = 131,
	EVRInitError_VRInitError_Init_WatchdogDisabledInSettings = 132,
	EVRInitError_VRInitError_Init_VRDashboardNotFound = 133,
	EVRInitError_VRInitError_Init_VRDashboardStartupFailed = 134,
	EVRInitError_VRInitError_Init_VRHomeNotFound = 135,
	EVRInitError_VRInitError_Init_VRHomeStartupFailed = 136,
	EVRInitError_VRInitError_Init_RebootingBusy = 137,
	EVRInitError_VRInitError_Init_FirmwareUpdateBusy = 138,
	EVRInitError_VRInitError_Init_FirmwareRecoveryBusy = 139,
	EVRInitError_VRInitError_Init_USBServiceBusy = 140,
	EVRInitError_VRInitError_Init_VRWebHelperStartupFailed = 141,
	EVRInitError_VRInitError_Init_TrackerManagerInitFailed = 142,
	EVRInitError_VRInitError_Driver_Failed = 200,
	EVRInitError_VRInitError_Driver_Unknown = 201,
	EVRInitError_VRInitError_Driver_HmdUnknown = 202,
	EVRInitError_VRInitError_Driver_NotLoaded = 203,
	EVRInitError_VRInitError_Driver_RuntimeOutOfDate = 204,
	EVRInitError_VRInitError_Driver_HmdInUse = 205,
	EVRInitError_VRInitError_Driver_NotCalibrated = 206,
	EVRInitError_VRInitError_Driver_CalibrationInvalid = 207,
	EVRInitError_VRInitError_Driver_HmdDisplayNotFound = 208,
	EVRInitError_VRInitError_Driver_TrackedDeviceInterfaceUnknown = 209,
	EVRInitError_VRInitError_Driver_HmdDriverIdOutOfBounds = 211,
	EVRInitError_VRInitError_Driver_HmdDisplayMirrored = 212,
	EVRInitError_VRInitError_IPC_ServerInitFailed = 300,
	EVRInitError_VRInitError_IPC_ConnectFailed = 301,
	EVRInitError_VRInitError_IPC_SharedStateInitFailed = 302,
	EVRInitError_VRInitError_IPC_CompositorInitFailed = 303,
	EVRInitError_VRInitError_IPC_MutexInitFailed = 304,
	EVRInitError_VRInitError_IPC_Failed = 305,
	EVRInitError_VRInitError_IPC_CompositorConnectFailed = 306,
	EVRInitError_VRInitError_IPC_CompositorInvalidConnectResponse = 307,
	EVRInitError_VRInitError_IPC_ConnectFailedAfterMultipleAttempts = 308,
	EVRInitError_VRInitError_Compositor_Failed = 400,
	EVRInitError_VRInitError_Compositor_D3D11HardwareRequired = 401,
	EVRInitError_VRInitError_Compositor_FirmwareRequiresUpdate = 402,
	EVRInitError_VRInitError_Compositor_OverlayInitFailed = 403,
	EVRInitError_VRInitError_Compositor_ScreenshotsInitFailed = 404,
	EVRInitError_VRInitError_Compositor_UnableToCreateDevice = 405,
	EVRInitError_VRInitError_Compositor_SharedStateIsNull = 406,
	EVRInitError_VRInitError_Compositor_NotificationManagerIsNull = 407,
	EVRInitError_VRInitError_Compositor_ResourceManagerClientIsNull = 408,
	EVRInitError_VRInitError_Compositor_MessageOverlaySharedStateInitFailure = 409,
	EVRInitError_VRInitError_Compositor_PropertiesInterfaceIsNull = 410,
	EVRInitError_VRInitError_Compositor_CreateFullscreenWindowFailed = 411,
	EVRInitError_VRInitError_Compositor_SettingsInterfaceIsNull = 412,
	EVRInitError_VRInitError_Compositor_FailedToShowWindow = 413,
	EVRInitError_VRInitError_Compositor_DistortInterfaceIsNull = 414,
	EVRInitError_VRInitError_Compositor_DisplayFrequencyFailure = 415,
	EVRInitError_VRInitError_Compositor_RendererInitializationFailed = 416,
	EVRInitError_VRInitError_Compositor_DXGIFactoryInterfaceIsNull = 417,
	EVRInitError_VRInitError_Compositor_DXGIFactoryCreateFailed = 418,
	EVRInitError_VRInitError_Compositor_DXGIFactoryQueryFailed = 419,
	EVRInitError_VRInitError_Compositor_InvalidAdapterDesktop = 420,
	EVRInitError_VRInitError_Compositor_InvalidHmdAttachment = 421,
	EVRInitError_VRInitError_Compositor_InvalidOutputDesktop = 422,
	EVRInitError_VRInitError_Compositor_InvalidDeviceProvided = 423,
	EVRInitError_VRInitError_Compositor_D3D11RendererInitializationFailed = 424,
	EVRInitError_VRInitError_Compositor_FailedToFindDisplayMode = 425,
	EVRInitError_VRInitError_Compositor_FailedToCreateSwapChain = 426,
	EVRInitError_VRInitError_Compositor_FailedToGetBackBuffer = 427,
	EVRInitError_VRInitError_Compositor_FailedToCreateRenderTarget = 428,
	EVRInitError_VRInitError_Compositor_FailedToCreateDXGI2SwapChain = 429,
	EVRInitError_VRInitError_Compositor_FailedtoGetDXGI2BackBuffer = 430,
	EVRInitError_VRInitError_Compositor_FailedToCreateDXGI2RenderTarget = 431,
	EVRInitError_VRInitError_Compositor_FailedToGetDXGIDeviceInterface = 432,
	EVRInitError_VRInitError_Compositor_SelectDisplayMode = 433,
	EVRInitError_VRInitError_Compositor_FailedToCreateNvAPIRenderTargets = 434,
	EVRInitError_VRInitError_Compositor_NvAPISetDisplayMode = 435,
	EVRInitError_VRInitError_Compositor_FailedToCreateDirectModeDisplay = 436,
	EVRInitError_VRInitError_Compositor_InvalidHmdPropertyContainer = 437,
	EVRInitError_VRInitError_Compositor_UpdateDisplayFrequency = 438,
	EVRInitError_VRInitError_Compositor_CreateRasterizerState = 439,
	EVRInitError_VRInitError_Compositor_CreateWireframeRasterizerState = 440,
	EVRInitError_VRInitError_Compositor_CreateSamplerState = 441,
	EVRInitError_VRInitError_Compositor_CreateClampToBorderSamplerState = 442,
	EVRInitError_VRInitError_Compositor_CreateAnisoSamplerState = 443,
	EVRInitError_VRInitError_Compositor_CreateOverlaySamplerState = 444,
	EVRInitError_VRInitError_Compositor_CreatePanoramaSamplerState = 445,
	EVRInitError_VRInitError_Compositor_CreateFontSamplerState = 446,
	EVRInitError_VRInitError_Compositor_CreateNoBlendState = 447,
	EVRInitError_VRInitError_Compositor_CreateBlendState = 448,
	EVRInitError_VRInitError_Compositor_CreateAlphaBlendState = 449,
	EVRInitError_VRInitError_Compositor_CreateBlendStateMaskR = 450,
	EVRInitError_VRInitError_Compositor_CreateBlendStateMaskG = 451,
	EVRInitError_VRInitError_Compositor_CreateBlendStateMaskB = 452,
	EVRInitError_VRInitError_Compositor_CreateDepthStencilState = 453,
	EVRInitError_VRInitError_Compositor_CreateDepthStencilStateNoWrite = 454,
	EVRInitError_VRInitError_Compositor_CreateDepthStencilStateNoDepth = 455,
	EVRInitError_VRInitError_Compositor_CreateFlushTexture = 456,
	EVRInitError_VRInitError_Compositor_CreateDistortionSurfaces = 457,
	EVRInitError_VRInitError_Compositor_CreateConstantBuffer = 458,
	EVRInitError_VRInitError_Compositor_CreateHmdPoseConstantBuffer = 459,
	EVRInitError_VRInitError_Compositor_CreateHmdPoseStagingConstantBuffer = 460,
	EVRInitError_VRInitError_Compositor_CreateSharedFrameInfoConstantBuffer = 461,
	EVRInitError_VRInitError_Compositor_CreateOverlayConstantBuffer = 462,
	EVRInitError_VRInitError_Compositor_CreateSceneTextureIndexConstantBuffer = 463,
	EVRInitError_VRInitError_Compositor_CreateReadableSceneTextureIndexConstantBuffer = 464,
	EVRInitError_VRInitError_Compositor_CreateLayerGraphicsTextureIndexConstantBuffer = 465,
	EVRInitError_VRInitError_Compositor_CreateLayerComputeTextureIndexConstantBuffer = 466,
	EVRInitError_VRInitError_Compositor_CreateLayerComputeSceneTextureIndexConstantBuffer = 467,
	EVRInitError_VRInitError_Compositor_CreateComputeHmdPoseConstantBuffer = 468,
	EVRInitError_VRInitError_Compositor_CreateGeomConstantBuffer = 469,
	EVRInitError_VRInitError_Compositor_CreatePanelMaskConstantBuffer = 470,
	EVRInitError_VRInitError_Compositor_CreatePixelSimUBO = 471,
	EVRInitError_VRInitError_Compositor_CreateMSAARenderTextures = 472,
	EVRInitError_VRInitError_Compositor_CreateResolveRenderTextures = 473,
	EVRInitError_VRInitError_Compositor_CreateComputeResolveRenderTextures = 474,
	EVRInitError_VRInitError_Compositor_CreateDriverDirectModeResolveTextures = 475,
	EVRInitError_VRInitError_Compositor_OpenDriverDirectModeResolveTextures = 476,
	EVRInitError_VRInitError_Compositor_CreateFallbackSyncTexture = 477,
	EVRInitError_VRInitError_Compositor_ShareFallbackSyncTexture = 478,
	EVRInitError_VRInitError_Compositor_CreateOverlayIndexBuffer = 479,
	EVRInitError_VRInitError_Compositor_CreateOverlayVertextBuffer = 480,
	EVRInitError_VRInitError_Compositor_CreateTextVertexBuffer = 481,
	EVRInitError_VRInitError_Compositor_CreateTextIndexBuffer = 482,
	EVRInitError_VRInitError_Compositor_CreateMirrorTextures = 483,
	EVRInitError_VRInitError_Compositor_CreateLastFrameRenderTexture = 484,
	EVRInitError_VRInitError_VendorSpecific_UnableToConnectToOculusRuntime = 1000,
	EVRInitError_VRInitError_VendorSpecific_WindowsNotInDevMode = 1001,
	EVRInitError_VRInitError_VendorSpecific_HmdFound_CantOpenDevice = 1101,
	EVRInitError_VRInitError_VendorSpecific_HmdFound_UnableToRequestConfigStart = 1102,
	EVRInitError_VRInitError_VendorSpecific_HmdFound_NoStoredConfig = 1103,
	EVRInitError_VRInitError_VendorSpecific_HmdFound_ConfigTooBig = 1104,
	EVRInitError_VRInitError_VendorSpecific_HmdFound_ConfigTooSmall = 1105,
	EVRInitError_VRInitError_VendorSpecific_HmdFound_UnableToInitZLib = 1106,
	EVRInitError_VRInitError_VendorSpecific_HmdFound_CantReadFirmwareVersion = 1107,
	EVRInitError_VRInitError_VendorSpecific_HmdFound_UnableToSendUserDataStart = 1108,
	EVRInitError_VRInitError_VendorSpecific_HmdFound_UnableToGetUserDataStart = 1109,
	EVRInitError_VRInitError_VendorSpecific_HmdFound_UnableToGetUserDataNext = 1110,
	EVRInitError_VRInitError_VendorSpecific_HmdFound_UserDataAddressRange = 1111,
	EVRInitError_VRInitError_VendorSpecific_HmdFound_UserDataError = 1112,
	EVRInitError_VRInitError_VendorSpecific_HmdFound_ConfigFailedSanityCheck = 1113,
	EVRInitError_VRInitError_Steam_SteamInstallationNotFound = 2000,
} EVRInitError;

typedef enum EVRScreenshotType
{
	EVRScreenshotType_VRScreenshotType_None = 0,
	EVRScreenshotType_VRScreenshotType_Mono = 1,
	EVRScreenshotType_VRScreenshotType_Stereo = 2,
	EVRScreenshotType_VRScreenshotType_Cubemap = 3,
	EVRScreenshotType_VRScreenshotType_MonoPanorama = 4,
	EVRScreenshotType_VRScreenshotType_StereoPanorama = 5,
} EVRScreenshotType;

typedef enum EVRScreenshotPropertyFilenames
{
	EVRScreenshotPropertyFilenames_VRScreenshotPropertyFilenames_Preview = 0,
	EVRScreenshotPropertyFilenames_VRScreenshotPropertyFilenames_VR = 1,
} EVRScreenshotPropertyFilenames;

typedef enum EVRTrackedCameraError
{
	EVRTrackedCameraError_VRTrackedCameraError_None = 0,
	EVRTrackedCameraError_VRTrackedCameraError_OperationFailed = 100,
	EVRTrackedCameraError_VRTrackedCameraError_InvalidHandle = 101,
	EVRTrackedCameraError_VRTrackedCameraError_InvalidFrameHeaderVersion = 102,
	EVRTrackedCameraError_VRTrackedCameraError_OutOfHandles = 103,
	EVRTrackedCameraError_VRTrackedCameraError_IPCFailure = 104,
	EVRTrackedCameraError_VRTrackedCameraError_NotSupportedForThisDevice = 105,
	EVRTrackedCameraError_VRTrackedCameraError_SharedMemoryFailure = 106,
	EVRTrackedCameraError_VRTrackedCameraError_FrameBufferingFailure = 107,
	EVRTrackedCameraError_VRTrackedCameraError_StreamSetupFailure = 108,
	EVRTrackedCameraError_VRTrackedCameraError_InvalidGLTextureId = 109,
	EVRTrackedCameraError_VRTrackedCameraError_InvalidSharedTextureHandle = 110,
	EVRTrackedCameraError_VRTrackedCameraError_FailedToGetGLTextureId = 111,
	EVRTrackedCameraError_VRTrackedCameraError_SharedTextureFailure = 112,
	EVRTrackedCameraError_VRTrackedCameraError_NoFrameAvailable = 113,
	EVRTrackedCameraError_VRTrackedCameraError_InvalidArgument = 114,
	EVRTrackedCameraError_VRTrackedCameraError_InvalidFrameBufferSize = 115,
} EVRTrackedCameraError;

typedef enum EVRTrackedCameraFrameLayout
{
	EVRTrackedCameraFrameLayout_Mono = 1,
	EVRTrackedCameraFrameLayout_Stereo = 2,
	EVRTrackedCameraFrameLayout_VerticalLayout = 16,
	EVRTrackedCameraFrameLayout_HorizontalLayout = 32,
} EVRTrackedCameraFrameLayout;

typedef enum EVRTrackedCameraFrameType
{
	EVRTrackedCameraFrameType_VRTrackedCameraFrameType_Distorted = 0,
	EVRTrackedCameraFrameType_VRTrackedCameraFrameType_Undistorted = 1,
	EVRTrackedCameraFrameType_VRTrackedCameraFrameType_MaximumUndistorted = 2,
	EVRTrackedCameraFrameType_MAX_CAMERA_FRAME_TYPES = 3,
} EVRTrackedCameraFrameType;

typedef enum EVRDistortionFunctionType
{
	EVRDistortionFunctionType_VRDistortionFunctionType_None = 0,
	EVRDistortionFunctionType_VRDistortionFunctionType_FTheta = 1,
	EVRDistortionFunctionType_VRDistortionFunctionType_Extended_FTheta = 2,
	EVRDistortionFunctionType_MAX_DISTORTION_FUNCTION_TYPES = 3,
} EVRDistortionFunctionType;

typedef enum EVSync
{
	EVSync_VSync_None = 0,
	EVSync_VSync_WaitRender = 1,
	EVSync_VSync_NoWaitRender = 2,
} EVSync;

typedef enum EVRMuraCorrectionMode
{
	EVRMuraCorrectionMode_Default = 0,
	EVRMuraCorrectionMode_NoCorrection = 1,
} EVRMuraCorrectionMode;

typedef enum Imu_OffScaleFlags
{
	Imu_OffScaleFlags_OffScale_AccelX = 1,
	Imu_OffScaleFlags_OffScale_AccelY = 2,
	Imu_OffScaleFlags_OffScale_AccelZ = 4,
	Imu_OffScaleFlags_OffScale_GyroX = 8,
	Imu_OffScaleFlags_OffScale_GyroY = 16,
	Imu_OffScaleFlags_OffScale_GyroZ = 32,
} Imu_OffScaleFlags;

typedef enum EVRApplicationError
{
	EVRApplicationError_VRApplicationError_None = 0,
	EVRApplicationError_VRApplicationError_AppKeyAlreadyExists = 100,
	EVRApplicationError_VRApplicationError_NoManifest = 101,
	EVRApplicationError_VRApplicationError_NoApplication = 102,
	EVRApplicationError_VRApplicationError_InvalidIndex = 103,
	EVRApplicationError_VRApplicationError_UnknownApplication = 104,
	EVRApplicationError_VRApplicationError_IPCFailed = 105,
	EVRApplicationError_VRApplicationError_ApplicationAlreadyRunning = 106,
	EVRApplicationError_VRApplicationError_InvalidManifest = 107,
	EVRApplicationError_VRApplicationError_InvalidApplication = 108,
	EVRApplicationError_VRApplicationError_LaunchFailed = 109,
	EVRApplicationError_VRApplicationError_ApplicationAlreadyStarting = 110,
	EVRApplicationError_VRApplicationError_LaunchInProgress = 111,
	EVRApplicationError_VRApplicationError_OldApplicationQuitting = 112,
	EVRApplicationError_VRApplicationError_TransitionAborted = 113,
	EVRApplicationError_VRApplicationError_IsTemplate = 114,
	EVRApplicationError_VRApplicationError_SteamVRIsExiting = 115,
	EVRApplicationError_VRApplicationError_BufferTooSmall = 200,
	EVRApplicationError_VRApplicationError_PropertyNotSet = 201,
	EVRApplicationError_VRApplicationError_UnknownProperty = 202,
	EVRApplicationError_VRApplicationError_InvalidParameter = 203,
} EVRApplicationError;

typedef enum EVRApplicationProperty
{
	EVRApplicationProperty_VRApplicationProperty_Name_String = 0,
	EVRApplicationProperty_VRApplicationProperty_LaunchType_String = 11,
	EVRApplicationProperty_VRApplicationProperty_WorkingDirectory_String = 12,
	EVRApplicationProperty_VRApplicationProperty_BinaryPath_String = 13,
	EVRApplicationProperty_VRApplicationProperty_Arguments_String = 14,
	EVRApplicationProperty_VRApplicationProperty_URL_String = 15,
	EVRApplicationProperty_VRApplicationProperty_Description_String = 50,
	EVRApplicationProperty_VRApplicationProperty_NewsURL_String = 51,
	EVRApplicationProperty_VRApplicationProperty_ImagePath_String = 52,
	EVRApplicationProperty_VRApplicationProperty_Source_String = 53,
	EVRApplicationProperty_VRApplicationProperty_ActionManifestURL_String = 54,
	EVRApplicationProperty_VRApplicationProperty_IsDashboardOverlay_Bool = 60,
	EVRApplicationProperty_VRApplicationProperty_IsTemplate_Bool = 61,
	EVRApplicationProperty_VRApplicationProperty_IsInstanced_Bool = 62,
	EVRApplicationProperty_VRApplicationProperty_IsInternal_Bool = 63,
	EVRApplicationProperty_VRApplicationProperty_WantsCompositorPauseInStandby_Bool = 64,
	EVRApplicationProperty_VRApplicationProperty_LastLaunchTime_Uint64 = 70,
} EVRApplicationProperty;

typedef enum EVRApplicationTransitionState
{
	EVRApplicationTransitionState_VRApplicationTransition_None = 0,
	EVRApplicationTransitionState_VRApplicationTransition_OldAppQuitSent = 10,
	EVRApplicationTransitionState_VRApplicationTransition_WaitingForExternalLaunch = 11,
	EVRApplicationTransitionState_VRApplicationTransition_NewAppLaunched = 20,
} EVRApplicationTransitionState;

typedef enum ChaperoneCalibrationState
{
	ChaperoneCalibrationState_OK = 1,
	ChaperoneCalibrationState_Warning = 100,
	ChaperoneCalibrationState_Warning_BaseStationMayHaveMoved = 101,
	ChaperoneCalibrationState_Warning_BaseStationRemoved = 102,
	ChaperoneCalibrationState_Warning_SeatedBoundsInvalid = 103,
	ChaperoneCalibrationState_Error = 200,
	ChaperoneCalibrationState_Error_BaseStationUninitialized = 201,
	ChaperoneCalibrationState_Error_BaseStationConflict = 202,
	ChaperoneCalibrationState_Error_PlayAreaInvalid = 203,
	ChaperoneCalibrationState_Error_CollisionBoundsInvalid = 204,
} ChaperoneCalibrationState;

typedef enum EChaperoneConfigFile
{
	EChaperoneConfigFile_Live = 1,
	EChaperoneConfigFile_Temp = 2,
} EChaperoneConfigFile;

typedef enum EChaperoneImportFlags
{
	EChaperoneImportFlags_EChaperoneImport_BoundsOnly = 1,
} EChaperoneImportFlags;

typedef enum EVRCompositorError
{
	EVRCompositorError_VRCompositorError_None = 0,
	EVRCompositorError_VRCompositorError_RequestFailed = 1,
	EVRCompositorError_VRCompositorError_IncompatibleVersion = 100,
	EVRCompositorError_VRCompositorError_DoNotHaveFocus = 101,
	EVRCompositorError_VRCompositorError_InvalidTexture = 102,
	EVRCompositorError_VRCompositorError_IsNotSceneApplication = 103,
	EVRCompositorError_VRCompositorError_TextureIsOnWrongDevice = 104,
	EVRCompositorError_VRCompositorError_TextureUsesUnsupportedFormat = 105,
	EVRCompositorError_VRCompositorError_SharedTexturesNotSupported = 106,
	EVRCompositorError_VRCompositorError_IndexOutOfRange = 107,
	EVRCompositorError_VRCompositorError_AlreadySubmitted = 108,
	EVRCompositorError_VRCompositorError_InvalidBounds = 109,
} EVRCompositorError;

typedef enum EVRCompositorTimingMode
{
	EVRCompositorTimingMode_VRCompositorTimingMode_Implicit = 0,
	EVRCompositorTimingMode_VRCompositorTimingMode_Explicit_RuntimePerformsPostPresentHandoff = 1,
	EVRCompositorTimingMode_VRCompositorTimingMode_Explicit_ApplicationPerformsPostPresentHandoff = 2,
} EVRCompositorTimingMode;

typedef enum VROverlayInputMethod
{
	VROverlayInputMethod_None = 0,
	VROverlayInputMethod_Mouse = 1,
	VROverlayInputMethod_DualAnalog = 2,
} VROverlayInputMethod;

typedef enum VROverlayTransformType
{
	VROverlayTransformType_VROverlayTransform_Absolute = 0,
	VROverlayTransformType_VROverlayTransform_TrackedDeviceRelative = 1,
	VROverlayTransformType_VROverlayTransform_SystemOverlay = 2,
	VROverlayTransformType_VROverlayTransform_TrackedComponent = 3,
} VROverlayTransformType;

typedef enum VROverlayFlags
{
	VROverlayFlags_None = 0,
	VROverlayFlags_Curved = 1,
	VROverlayFlags_RGSS4X = 2,
	VROverlayFlags_NoDashboardTab = 3,
	VROverlayFlags_AcceptsGamepadEvents = 4,
	VROverlayFlags_ShowGamepadFocus = 5,
	VROverlayFlags_SendVRDiscreteScrollEvents = 6,
	VROverlayFlags_SendVRTouchpadEvents = 7,
	VROverlayFlags_ShowTouchPadScrollWheel = 8,
	VROverlayFlags_TransferOwnershipToInternalProcess = 9,
	VROverlayFlags_SideBySide_Parallel = 10,
	VROverlayFlags_SideBySide_Crossed = 11,
	VROverlayFlags_Panorama = 12,
	VROverlayFlags_StereoPanorama = 13,
	VROverlayFlags_SortWithNonSceneOverlays = 14,
	VROverlayFlags_VisibleInDashboard = 15,
	VROverlayFlags_MakeOverlaysInteractiveIfVisible = 16,
	VROverlayFlags_SendVRSmoothScrollEvents = 17,
} VROverlayFlags;

typedef enum VRMessageOverlayResponse
{
	VRMessageOverlayResponse_ButtonPress_0 = 0,
	VRMessageOverlayResponse_ButtonPress_1 = 1,
	VRMessageOverlayResponse_ButtonPress_2 = 2,
	VRMessageOverlayResponse_ButtonPress_3 = 3,
	VRMessageOverlayResponse_CouldntFindSystemOverlay = 4,
	VRMessageOverlayResponse_CouldntFindOrCreateClientOverlay = 5,
	VRMessageOverlayResponse_ApplicationQuit = 6,
} VRMessageOverlayResponse;

typedef enum EGamepadTextInputMode
{
	EGamepadTextInputMode_k_EGamepadTextInputModeNormal = 0,
	EGamepadTextInputMode_k_EGamepadTextInputModePassword = 1,
	EGamepadTextInputMode_k_EGamepadTextInputModeSubmit = 2,
} EGamepadTextInputMode;

typedef enum EGamepadTextInputLineMode
{
	EGamepadTextInputLineMode_k_EGamepadTextInputLineModeSingleLine = 0,
	EGamepadTextInputLineMode_k_EGamepadTextInputLineModeMultipleLines = 1,
} EGamepadTextInputLineMode;

typedef enum EOverlayDirection
{
	EOverlayDirection_OverlayDirection_Up = 0,
	EOverlayDirection_OverlayDirection_Down = 1,
	EOverlayDirection_OverlayDirection_Left = 2,
	EOverlayDirection_OverlayDirection_Right = 3,
	EOverlayDirection_OverlayDirection_Count = 4,
} EOverlayDirection;

typedef enum EVROverlayIntersectionMaskPrimitiveType
{
	EVROverlayIntersectionMaskPrimitiveType_OverlayIntersectionPrimitiveType_Rectangle = 0,
	EVROverlayIntersectionMaskPrimitiveType_OverlayIntersectionPrimitiveType_Circle = 1,
} EVROverlayIntersectionMaskPrimitiveType;

typedef enum EVRRenderModelError
{
	EVRRenderModelError_VRRenderModelError_None = 0,
	EVRRenderModelError_VRRenderModelError_Loading = 100,
	EVRRenderModelError_VRRenderModelError_NotSupported = 200,
	EVRRenderModelError_VRRenderModelError_InvalidArg = 300,
	EVRRenderModelError_VRRenderModelError_InvalidModel = 301,
	EVRRenderModelError_VRRenderModelError_NoShapes = 302,
	EVRRenderModelError_VRRenderModelError_MultipleShapes = 303,
	EVRRenderModelError_VRRenderModelError_TooManyVertices = 304,
	EVRRenderModelError_VRRenderModelError_MultipleTextures = 305,
	EVRRenderModelError_VRRenderModelError_BufferTooSmall = 306,
	EVRRenderModelError_VRRenderModelError_NotEnoughNormals = 307,
	EVRRenderModelError_VRRenderModelError_NotEnoughTexCoords = 308,
	EVRRenderModelError_VRRenderModelError_InvalidTexture = 400,
} EVRRenderModelError;

typedef enum EVRComponentProperty
{
	EVRComponentProperty_VRComponentProperty_IsStatic = 1,
	EVRComponentProperty_VRComponentProperty_IsVisible = 2,
	EVRComponentProperty_VRComponentProperty_IsTouched = 4,
	EVRComponentProperty_VRComponentProperty_IsPressed = 8,
	EVRComponentProperty_VRComponentProperty_IsScrolled = 16,
} EVRComponentProperty;

typedef enum EVRNotificationType
{
	EVRNotificationType_Transient = 0,
	EVRNotificationType_Persistent = 1,
	EVRNotificationType_Transient_SystemWithUserValue = 2,
} EVRNotificationType;

typedef enum EVRNotificationStyle
{
	EVRNotificationStyle_None = 0,
	EVRNotificationStyle_Application = 100,
	EVRNotificationStyle_Contact_Disabled = 200,
	EVRNotificationStyle_Contact_Enabled = 201,
	EVRNotificationStyle_Contact_Active = 202,
} EVRNotificationStyle;

typedef enum EVRSettingsError
{
	EVRSettingsError_VRSettingsError_None = 0,
	EVRSettingsError_VRSettingsError_IPCFailed = 1,
	EVRSettingsError_VRSettingsError_WriteFailed = 2,
	EVRSettingsError_VRSettingsError_ReadFailed = 3,
	EVRSettingsError_VRSettingsError_JsonParseFailed = 4,
	EVRSettingsError_VRSettingsError_UnsetSettingHasNoDefault = 5,
} EVRSettingsError;

typedef enum EVRScreenshotError
{
	EVRScreenshotError_VRScreenshotError_None = 0,
	EVRScreenshotError_VRScreenshotError_RequestFailed = 1,
	EVRScreenshotError_VRScreenshotError_IncompatibleVersion = 100,
	EVRScreenshotError_VRScreenshotError_NotFound = 101,
	EVRScreenshotError_VRScreenshotError_BufferTooSmall = 102,
	EVRScreenshotError_VRScreenshotError_ScreenshotAlreadyInProgress = 108,
} EVRScreenshotError;

typedef enum EVRSkeletalTransformSpace
{
	EVRSkeletalTransformSpace_VRSkeletalTransformSpace_Model = 0,
	EVRSkeletalTransformSpace_VRSkeletalTransformSpace_Parent = 1,
} EVRSkeletalTransformSpace;

typedef enum EVRSkeletalReferencePose
{
	EVRSkeletalReferencePose_VRSkeletalReferencePose_BindPose = 0,
	EVRSkeletalReferencePose_VRSkeletalReferencePose_OpenHand = 1,
	EVRSkeletalReferencePose_VRSkeletalReferencePose_Fist = 2,
	EVRSkeletalReferencePose_VRSkeletalReferencePose_GripLimit = 3,
} EVRSkeletalReferencePose;

typedef enum EVRFinger
{
	EVRFinger_VRFinger_Thumb = 0,
	EVRFinger_VRFinger_Index = 1,
	EVRFinger_VRFinger_Middle = 2,
	EVRFinger_VRFinger_Ring = 3,
	EVRFinger_VRFinger_Pinky = 4,
	EVRFinger_VRFinger_Count = 5,
} EVRFinger;

typedef enum EVRFingerSplay
{
	EVRFingerSplay_VRFingerSplay_Thumb_Index = 0,
	EVRFingerSplay_VRFingerSplay_Index_Middle = 1,
	EVRFingerSplay_VRFingerSplay_Middle_Ring = 2,
	EVRFingerSplay_VRFingerSplay_Ring_Pinky = 3,
	EVRFingerSplay_VRFingerSplay_Count = 4,
} EVRFingerSplay;

typedef enum EVRInputFilterCancelType
{
	EVRInputFilterCancelType_VRInputFilterCancel_Timers = 0,
	EVRInputFilterCancelType_VRInputFilterCancel_Momentum = 1,
} EVRInputFilterCancelType;

typedef enum EVRInputStringBits
{
	EVRInputStringBits_VRInputString_Hand = 1,
	EVRInputStringBits_VRInputString_ControllerType = 2,
	EVRInputStringBits_VRInputString_InputSource = 4,
	EVRInputStringBits_VRInputString_All = -1,
} EVRInputStringBits;

typedef enum EIOBufferError
{
	EIOBufferError_IOBuffer_Success = 0,
	EIOBufferError_IOBuffer_OperationFailed = 100,
	EIOBufferError_IOBuffer_InvalidHandle = 101,
	EIOBufferError_IOBuffer_InvalidArgument = 102,
	EIOBufferError_IOBuffer_PathExists = 103,
	EIOBufferError_IOBuffer_PathDoesNotExist = 104,
	EIOBufferError_IOBuffer_Permission = 105,
} EIOBufferError;

typedef enum EIOBufferMode
{
	EIOBufferMode_IOBufferMode_Read = 1,
	EIOBufferMode_IOBufferMode_Write = 2,
	EIOBufferMode_IOBufferMode_Create = 512,
} EIOBufferMode;

// OpenVR typedefs

typedef uint32_t TrackedDeviceIndex_t;
typedef uint32_t VRNotificationId;
typedef uint64_t VROverlayHandle_t;

typedef uint32_t SpatialAnchorHandle_t;
typedef void * glSharedTextureHandle_t;
typedef int32_t glInt_t;
typedef uint32_t glUInt_t;
typedef uint64_t SharedTextureHandle_t;
typedef uint32_t DriverId_t;
typedef uint32_t TrackedDeviceIndex_t;
typedef uint64_t WebConsoleHandle_t;
typedef uint64_t PropertyContainerHandle_t;
typedef uint32_t PropertyTypeTag_t;
typedef PropertyContainerHandle_t DriverHandle_t;
typedef uint64_t VRActionHandle_t;
typedef uint64_t VRActionSetHandle_t;
typedef uint64_t VRInputValueHandle_t;
typedef uint64_t VROverlayHandle_t;
typedef int32_t BoneIndex_t;
typedef uint64_t TrackedCameraHandle_t;
typedef uint32_t ScreenshotHandle_t;
typedef uint32_t VRComponentProperties;
typedef int32_t TextureID_t;
typedef uint32_t VRNotificationId;
typedef uint64_t IOBufferHandle_t;
typedef EVRInitError HmdError;
typedef EVREye Hmd_Eye;
typedef EColorSpace ColorSpace;
typedef ETrackingResult HmdTrackingResult;
typedef ETrackedDeviceClass TrackedDeviceClass;
typedef ETrackingUniverseOrigin TrackingUniverseOrigin;
typedef ETrackedDeviceProperty TrackedDeviceProperty;
typedef ETrackedPropertyError TrackedPropertyError;
typedef EVRSubmitFlags VRSubmitFlags_t;
typedef EVRState VRState_t;
typedef ECollisionBoundsStyle CollisionBoundsStyle_t;
typedef EVROverlayError VROverlayError;
typedef EVRFirmwareError VRFirmwareError;
typedef EVRCompositorError VRCompositorError;
typedef EVRScreenshotError VRScreenshotsError;

// OpenVR Structs

typedef struct HmdMatrix34_t
{
	float m[3][4]; //float[3][4]
} HmdMatrix34_t;

typedef struct HmdMatrix33_t
{
	float m[3][3]; //float[3][3]
} HmdMatrix33_t;

typedef struct HmdMatrix44_t
{
	float m[4][4]; //float[4][4]
} HmdMatrix44_t;

typedef struct HmdVector3_t
{
	float v[3]; //float[3]
} HmdVector3_t;

typedef struct HmdVector4_t
{
	float v[4]; //float[4]
} HmdVector4_t;

typedef struct HmdVector3d_t
{
	double v[3]; //double[3]
} HmdVector3d_t;

typedef struct HmdVector2_t
{
	float v[2]; //float[2]
} HmdVector2_t;

typedef struct HmdQuaternion_t
{
	double w;
	double x;
	double y;
	double z;
} HmdQuaternion_t;

typedef struct HmdQuaternionf_t
{
	float w;
	float x;
	float y;
	float z;
} HmdQuaternionf_t;

typedef struct HmdColor_t
{
	float r;
	float g;
	float b;
	float a;
} HmdColor_t;

typedef struct HmdQuad_t
{
	struct HmdVector3_t vCorners[4]; //struct vr::HmdVector3_t[4]
} HmdQuad_t;

typedef struct HmdRect2_t
{
	struct HmdVector2_t vTopLeft;
	struct HmdVector2_t vBottomRight;
} HmdRect2_t;

typedef struct DistortionCoordinates_t
{
	float rfRed[2]; //float[2]
	float rfGreen[2]; //float[2]
	float rfBlue[2]; //float[2]
} DistortionCoordinates_t;

typedef struct Texture_t
{
	void * handle; // void *
	enum ETextureType eType;
	enum EColorSpace eColorSpace;
} Texture_t;

typedef struct TrackedDevicePose_t
{
	struct HmdMatrix34_t mDeviceToAbsoluteTracking;
	struct HmdVector3_t vVelocity;
	struct HmdVector3_t vAngularVelocity;
	enum ETrackingResult eTrackingResult;
	bool bPoseIsValid;
	bool bDeviceIsConnected;
} TrackedDevicePose_t;

typedef struct VRTextureBounds_t
{
	float uMin;
	float vMin;
	float uMax;
	float vMax;
} VRTextureBounds_t;

typedef struct VRTextureWithPose_t
{
	struct HmdMatrix34_t mDeviceToAbsoluteTracking;
} VRTextureWithPose_t;

typedef struct VRTextureDepthInfo_t
{
	void * handle; // void *
	struct HmdMatrix44_t mProjection;
	struct HmdVector2_t vRange;
} VRTextureDepthInfo_t;

typedef struct VRTextureWithDepth_t
{
	struct VRTextureDepthInfo_t depth;
} VRTextureWithDepth_t;

typedef struct VRTextureWithPoseAndDepth_t
{
	struct VRTextureDepthInfo_t depth;
} VRTextureWithPoseAndDepth_t;

typedef struct VkInstance_T VkInstance_T;
typedef struct VkPhysicalDevice_T VkPhysicalDevice_T;
typedef struct VkQueue_T VkQueue_T;
typedef struct VkDevice_T VkDevice_T;

typedef struct VRVulkanTextureData_t
{
	uint64_t m_nImage;
	VkDevice_T * m_pDevice; // struct VkDevice_T *
	VkPhysicalDevice_T * m_pPhysicalDevice; // struct VkPhysicalDevice_T *
	VkInstance_T * m_pInstance; // struct VkInstance_T *
	VkQueue_T * m_pQueue; // struct VkQueue_T *
	uint32_t m_nQueueFamilyIndex;
	uint32_t m_nWidth;
	uint32_t m_nHeight;
	uint32_t m_nFormat;
	uint32_t m_nSampleCount;
} VRVulkanTextureData_t;

typedef struct D3D12TextureData_t
{
	struct ID3D12Resource * m_pResource; // struct ID3D12Resource *
	struct ID3D12CommandQueue * m_pCommandQueue; // struct ID3D12CommandQueue *
	uint32_t m_nNodeMask;
} D3D12TextureData_t;

typedef struct VREvent_Controller_t
{
	uint32_t button;
} VREvent_Controller_t;

typedef struct VREvent_Mouse_t
{
	float x;
	float y;
	uint32_t button;
} VREvent_Mouse_t;

typedef struct VREvent_Scroll_t
{
	float xdelta;
	float ydelta;
	uint32_t repeatCount;
} VREvent_Scroll_t;

typedef struct VREvent_TouchPadMove_t
{
	bool bFingerDown;
	float flSecondsFingerDown;
	float fValueXFirst;
	float fValueYFirst;
	float fValueXRaw;
	float fValueYRaw;
} VREvent_TouchPadMove_t;

typedef struct VREvent_Notification_t
{
	uint64_t ulUserValue;
	uint32_t notificationId;
} VREvent_Notification_t;

typedef struct VREvent_Process_t
{
	uint32_t pid;
	uint32_t oldPid;
	bool bForced;
	bool bConnectionLost;
} VREvent_Process_t;

typedef struct VREvent_Overlay_t
{
	uint64_t overlayHandle;
	uint64_t devicePath;
} VREvent_Overlay_t;

typedef struct VREvent_Status_t
{
	uint32_t statusState;
} VREvent_Status_t;

typedef struct VREvent_Keyboard_t
{
	char cNewInput[8]; //char[8]
	uint64_t uUserValue;
} VREvent_Keyboard_t;

typedef struct VREvent_Ipd_t
{
	float ipdMeters;
} VREvent_Ipd_t;

typedef struct VREvent_Chaperone_t
{
	uint64_t m_nPreviousUniverse;
	uint64_t m_nCurrentUniverse;
} VREvent_Chaperone_t;

typedef struct VREvent_Reserved_t
{
	uint64_t reserved0;
	uint64_t reserved1;
	uint64_t reserved2;
	uint64_t reserved3;
	uint64_t reserved4;
	uint64_t reserved5;
} VREvent_Reserved_t;

typedef struct VREvent_PerformanceTest_t
{
	uint32_t m_nFidelityLevel;
} VREvent_PerformanceTest_t;

typedef struct VREvent_SeatedZeroPoseReset_t
{
	bool bResetBySystemMenu;
} VREvent_SeatedZeroPoseReset_t;

typedef struct VREvent_Screenshot_t
{
	uint32_t handle;
	uint32_t type;
} VREvent_Screenshot_t;

typedef struct VREvent_ScreenshotProgress_t
{
	float progress;
} VREvent_ScreenshotProgress_t;

typedef struct VREvent_ApplicationLaunch_t
{
	uint32_t pid;
	uint32_t unArgsHandle;
} VREvent_ApplicationLaunch_t;

typedef struct VREvent_EditingCameraSurface_t
{
	uint64_t overlayHandle;
	uint32_t nVisualMode;
} VREvent_EditingCameraSurface_t;

typedef struct VREvent_MessageOverlay_t
{
	uint32_t unVRMessageOverlayResponse;
} VREvent_MessageOverlay_t;

typedef struct VREvent_Property_t
{
	PropertyContainerHandle_t container;
	enum ETrackedDeviceProperty prop;
} VREvent_Property_t;

typedef struct VREvent_DualAnalog_t
{
	float x;
	float y;
	float transformedX;
	float transformedY;
	enum EDualAnalogWhich which;
} VREvent_DualAnalog_t;

typedef struct VREvent_HapticVibration_t
{
	uint64_t containerHandle;
	uint64_t componentHandle;
	float fDurationSeconds;
	float fFrequency;
	float fAmplitude;
} VREvent_HapticVibration_t;

typedef struct VREvent_WebConsole_t
{
	WebConsoleHandle_t webConsoleHandle;
} VREvent_WebConsole_t;

typedef struct VREvent_InputBindingLoad_t
{
	PropertyContainerHandle_t ulAppContainer;
	uint64_t pathMessage;
	uint64_t pathUrl;
	uint64_t pathControllerType;
} VREvent_InputBindingLoad_t;

typedef struct VREvent_InputActionManifestLoad_t
{
	uint64_t pathAppKey;
	uint64_t pathMessage;
	uint64_t pathMessageParam;
	uint64_t pathManifestPath;
} VREvent_InputActionManifestLoad_t;

typedef struct VREvent_SpatialAnchor_t
{
	SpatialAnchorHandle_t unHandle;
} VREvent_SpatialAnchor_t;

typedef struct VREvent_ProgressUpdate_t
{
	uint64_t ulApplicationPropertyContainer;
	uint64_t pathDevice;
	uint64_t pathInputSource;
	uint64_t pathProgressAction;
	uint64_t pathIcon;
	float fProgress;
} VREvent_ProgressUpdate_t;

typedef struct VREvent_ShowUI_t
{
	enum EShowUIType eType;
} VREvent_ShowUI_t;

typedef struct HiddenAreaMesh_t
{
	struct HmdVector2_t * pVertexData; // const struct vr::HmdVector2_t *
	uint32_t unTriangleCount;
} HiddenAreaMesh_t;

typedef struct VRControllerAxis_t
{
	float x;
	float y;
} VRControllerAxis_t;

typedef struct VRControllerState_t
{
	uint32_t unPacketNum;
	uint64_t ulButtonPressed;
	uint64_t ulButtonTouched;
	struct VRControllerAxis_t rAxis[5]; //struct vr::VRControllerAxis_t[5]
} VRControllerState_t;

typedef struct Compositor_OverlaySettings
{
	uint32_t size;
	bool curved;
	bool antialias;
	float scale;
	float distance;
	float alpha;
	float uOffset;
	float vOffset;
	float uScale;
	float vScale;
	float gridDivs;
	float gridWidth;
	float gridScale;
	struct HmdMatrix44_t transform;
} Compositor_OverlaySettings;

typedef struct VRBoneTransform_t
{
	struct HmdVector4_t position;
	struct HmdQuaternionf_t orientation;
} VRBoneTransform_t;

typedef struct CameraVideoStreamFrameHeader_t
{
	enum EVRTrackedCameraFrameType eFrameType;
	uint32_t nWidth;
	uint32_t nHeight;
	uint32_t nBytesPerPixel;
	uint32_t nFrameSequence;
	struct TrackedDevicePose_t standingTrackedDevicePose;
	uint64_t ulFrameExposureTime;
} CameraVideoStreamFrameHeader_t;

typedef struct DriverDirectMode_FrameTiming
{
	uint32_t m_nSize;
	uint32_t m_nNumFramePresents;
	uint32_t m_nNumMisPresented;
	uint32_t m_nNumDroppedFrames;
	uint32_t m_nReprojectionFlags;
} DriverDirectMode_FrameTiming;

typedef struct ImuSample_t
{
	double fSampleTime;
	struct HmdVector3d_t vAccel;
	struct HmdVector3d_t vGyro;
	uint32_t unOffScaleFlags;
} ImuSample_t;

typedef struct AppOverrideKeys_t
{
	char * pchKey; // const char *
	char * pchValue; // const char *
} AppOverrideKeys_t;

typedef struct Compositor_FrameTiming
{
	uint32_t m_nSize;
	uint32_t m_nFrameIndex;
	uint32_t m_nNumFramePresents;
	uint32_t m_nNumMisPresented;
	uint32_t m_nNumDroppedFrames;
	uint32_t m_nReprojectionFlags;
	double m_flSystemTimeInSeconds;
	float m_flPreSubmitGpuMs;
	float m_flPostSubmitGpuMs;
	float m_flTotalRenderGpuMs;
	float m_flCompositorRenderGpuMs;
	float m_flCompositorRenderCpuMs;
	float m_flCompositorIdleCpuMs;
	float m_flClientFrameIntervalMs;
	float m_flPresentCallCpuMs;
	float m_flWaitForPresentCpuMs;
	float m_flSubmitFrameMs;
	float m_flWaitGetPosesCalledMs;
	float m_flNewPosesReadyMs;
	float m_flNewFrameReadyMs;
	float m_flCompositorUpdateStartMs;
	float m_flCompositorUpdateEndMs;
	float m_flCompositorRenderStartMs;
	TrackedDevicePose_t m_HmdPose;
	uint32_t m_nNumVSyncsReadyForUse;
	uint32_t m_nNumVSyncsToFirstView;
} Compositor_FrameTiming;

typedef struct Compositor_CumulativeStats
{
	uint32_t m_nPid;
	uint32_t m_nNumFramePresents;
	uint32_t m_nNumDroppedFrames;
	uint32_t m_nNumReprojectedFrames;
	uint32_t m_nNumFramePresentsOnStartup;
	uint32_t m_nNumDroppedFramesOnStartup;
	uint32_t m_nNumReprojectedFramesOnStartup;
	uint32_t m_nNumLoading;
	uint32_t m_nNumFramePresentsLoading;
	uint32_t m_nNumDroppedFramesLoading;
	uint32_t m_nNumReprojectedFramesLoading;
	uint32_t m_nNumTimedOut;
	uint32_t m_nNumFramePresentsTimedOut;
	uint32_t m_nNumDroppedFramesTimedOut;
	uint32_t m_nNumReprojectedFramesTimedOut;
} Compositor_CumulativeStats;

typedef struct VROverlayIntersectionParams_t
{
	struct HmdVector3_t vSource;
	struct HmdVector3_t vDirection;
	enum ETrackingUniverseOrigin eOrigin;
} VROverlayIntersectionParams_t;

typedef struct VROverlayIntersectionResults_t
{
	struct HmdVector3_t vPoint;
	struct HmdVector3_t vNormal;
	struct HmdVector2_t vUVs;
	float fDistance;
} VROverlayIntersectionResults_t;

typedef struct IntersectionMaskRectangle_t
{
	float m_flTopLeftX;
	float m_flTopLeftY;
	float m_flWidth;
	float m_flHeight;
} IntersectionMaskRectangle_t;

typedef struct IntersectionMaskCircle_t
{
	float m_flCenterX;
	float m_flCenterY;
	float m_flRadius;
} IntersectionMaskCircle_t;

typedef struct RenderModel_ComponentState_t
{
	struct HmdMatrix34_t mTrackingToComponentRenderModel;
	struct HmdMatrix34_t mTrackingToComponentLocal;
	VRComponentProperties uProperties;
} RenderModel_ComponentState_t;

typedef struct RenderModel_Vertex_t
{
	struct HmdVector3_t vPosition;
	struct HmdVector3_t vNormal;
	float rfTextureCoord[2]; //float[2]
} RenderModel_Vertex_t;

typedef struct RenderModel_TextureMap_t
{
	uint16_t unWidth;
	uint16_t unHeight;
	uint8_t * rubTextureMapData; // const uint8_t *
} RenderModel_TextureMap_t;

typedef struct RenderModel_t
{
	struct RenderModel_Vertex_t * rVertexData; // const struct vr::RenderModel_Vertex_t *
	uint32_t unVertexCount;
	uint16_t * rIndexData; // const uint16_t *
	uint32_t unTriangleCount;
	TextureID_t diffuseTextureId;
} RenderModel_t;

typedef struct RenderModel_ControllerMode_State_t
{
	bool bScrollWheelVisible;
} RenderModel_ControllerMode_State_t;

typedef struct NotificationBitmap_t
{
	void * m_pImageData; // void *
	int32_t m_nWidth;
	int32_t m_nHeight;
	int32_t m_nBytesPerPixel;
} NotificationBitmap_t;

typedef struct CVRSettingHelper
{
	intptr_t m_pSettings; // class vr::IVRSettings *
} CVRSettingHelper;

typedef struct InputAnalogActionData_t
{
	bool bActive;
	VRInputValueHandle_t activeOrigin;
	float x;
	float y;
	float z;
	float deltaX;
	float deltaY;
	float deltaZ;
	float fUpdateTime;
} InputAnalogActionData_t;

typedef struct InputDigitalActionData_t
{
	bool bActive;
	VRInputValueHandle_t activeOrigin;
	bool bState;
	bool bChanged;
	float fUpdateTime;
} InputDigitalActionData_t;

typedef struct InputPoseActionData_t
{
	bool bActive;
	VRInputValueHandle_t activeOrigin;
	struct TrackedDevicePose_t pose;
} InputPoseActionData_t;

typedef struct InputSkeletalActionData_t
{
	bool bActive;
	VRInputValueHandle_t activeOrigin;
} InputSkeletalActionData_t;

typedef struct InputOriginInfo_t
{
	VRInputValueHandle_t devicePath;
	TrackedDeviceIndex_t trackedDeviceIndex;
	char rchRenderModelComponentName[128]; //char[128]
} InputOriginInfo_t;

typedef struct VRActiveActionSet_t
{
	VRActionSetHandle_t ulActionSet;
	VRInputValueHandle_t ulRestrictedToDevice;
	VRActionSetHandle_t ulSecondaryActionSet;
	uint32_t unPadding;
	int32_t nPriority;
} VRActiveActionSet_t;

typedef struct VRSkeletalSummaryData_t
{
	float flFingerCurl[5]; //float[5]
	float flFingerSplay[4]; //float[4]
} VRSkeletalSummaryData_t;

typedef struct SpatialAnchorPose_t
{
	struct HmdMatrix34_t mAnchorToAbsoluteTracking;
} SpatialAnchorPose_t;

typedef struct COpenVRContext
{
	intptr_t m_pVRSystem; // class vr::IVRSystem *
	intptr_t m_pVRChaperone; // class vr::IVRChaperone *
	intptr_t m_pVRChaperoneSetup; // class vr::IVRChaperoneSetup *
	intptr_t m_pVRCompositor; // class vr::IVRCompositor *
	intptr_t m_pVROverlay; // class vr::IVROverlay *
	intptr_t m_pVRResources; // class vr::IVRResources *
	intptr_t m_pVRRenderModels; // class vr::IVRRenderModels *
	intptr_t m_pVRExtendedDisplay; // class vr::IVRExtendedDisplay *
	intptr_t m_pVRSettings; // class vr::IVRSettings *
	intptr_t m_pVRApplications; // class vr::IVRApplications *
	intptr_t m_pVRTrackedCamera; // class vr::IVRTrackedCamera *
	intptr_t m_pVRScreenshots; // class vr::IVRScreenshots *
	intptr_t m_pVRDriverManager; // class vr::IVRDriverManager *
	intptr_t m_pVRInput; // class vr::IVRInput *
	intptr_t m_pVRIOBuffer; // class vr::IVRIOBuffer *
	intptr_t m_pVRSpatialAnchors; // class vr::IVRSpatialAnchors *
	intptr_t m_pVRNotifications; // class vr::IVRNotifications *
} COpenVRContext;


typedef union
{
	VREvent_Reserved_t reserved;
	VREvent_Controller_t controller;
	VREvent_Mouse_t mouse;
	VREvent_Scroll_t scroll;
	VREvent_Process_t process;
	VREvent_Notification_t notification;
	VREvent_Overlay_t overlay;
	VREvent_Status_t status;
	VREvent_Keyboard_t keyboard;
	VREvent_Ipd_t ipd;
	VREvent_Chaperone_t chaperone;
	VREvent_PerformanceTest_t performanceTest;
	VREvent_TouchPadMove_t touchPadMove;
	VREvent_SeatedZeroPoseReset_t seatedZeroPoseReset;
	VREvent_Screenshot_t screenshot;
	VREvent_ScreenshotProgress_t screenshotProgress;
	VREvent_ApplicationLaunch_t applicationLaunch;
	VREvent_EditingCameraSurface_t cameraSurface;
	VREvent_MessageOverlay_t messageOverlay;
	VREvent_Property_t property;
	VREvent_DualAnalog_t dualAnalog;
	VREvent_HapticVibration_t hapticVibration;
	VREvent_WebConsole_t webConsole;
	VREvent_InputBindingLoad_t inputBinding;
	VREvent_InputActionManifestLoad_t actionManifest;
	VREvent_SpatialAnchor_t spatialAnchor;
} VREvent_Data_t;

/** An event posted by the server to all running applications */
typedef struct 
{
	uint32_t eventType; // EVREventType enum
	TrackedDeviceIndex_t trackedDeviceIndex;
	float eventAgeSeconds;
	// event data must be the end of the struct as its size is variable
	VREvent_Data_t data;
} VREvent_t;

typedef union
{
	IntersectionMaskRectangle_t m_Rectangle;
	IntersectionMaskCircle_t m_Circle;
} VROverlayIntersectionMaskPrimitive_Data_t;

typedef struct 
{
	EVROverlayIntersectionMaskPrimitiveType m_nPrimitiveType;
	VROverlayIntersectionMaskPrimitive_Data_t m_Primitive;
} VROverlayIntersectionMaskPrimitive_t;

// OpenVR Function Pointer Tables (here replaced with static bindings)

void tr_ovw_GetRecommendedRenderTargetSize(IVRSystem* self, uint32_t * pnWidth, uint32_t * pnHeight);
HmdMatrix44_t tr_ovw_GetProjectionMatrix(IVRSystem* self, EVREye eEye, float fNearZ, float fFarZ);
void tr_ovw_GetProjectionRaw(IVRSystem* self, EVREye eEye, float * pfLeft, float * pfRight, float * pfTop, float * pfBottom);
bool tr_ovw_ComputeDistortion(IVRSystem* self, EVREye eEye, float fU, float fV, DistortionCoordinates_t * pDistortionCoordinates);
HmdMatrix34_t tr_ovw_GetEyeToHeadTransform(IVRSystem* self, EVREye eEye);
bool tr_ovw_GetTimeSinceLastVsync(IVRSystem* self, float * pfSecondsSinceLastVsync, uint64_t * pulFrameCounter);
int32_t tr_ovw_GetD3D9AdapterIndex(IVRSystem* self);
void tr_ovw_GetDXGIOutputInfo(IVRSystem* self, int32_t * pnAdapterIndex);
void tr_ovw_GetOutputDevice(IVRSystem* self, uint64_t * pnDevice, ETextureType textureType, VkInstance_T * pInstance);
bool tr_ovw_IsDisplayOnDesktop(IVRSystem* self);
bool tr_ovw_SetDisplayVisibility(IVRSystem* self, bool bIsVisibleOnDesktop);
void tr_ovw_GetDeviceToAbsoluteTrackingPose(IVRSystem* self, ETrackingUniverseOrigin eOrigin, float fPredictedSecondsToPhotonsFromNow, TrackedDevicePose_t * pTrackedDevicePoseArray, uint32_t unTrackedDevicePoseArrayCount);
void tr_ovw_ResetSeatedZeroPose(IVRSystem* self);
HmdMatrix34_t tr_ovw_GetSeatedZeroPoseToStandingAbsoluteTrackingPose(IVRSystem* self);
HmdMatrix34_t tr_ovw_GetRawZeroPoseToStandingAbsoluteTrackingPose(IVRSystem* self);
uint32_t tr_ovw_GetSortedTrackedDeviceIndicesOfClass(IVRSystem* self, ETrackedDeviceClass eTrackedDeviceClass, TrackedDeviceIndex_t * punTrackedDeviceIndexArray, uint32_t unTrackedDeviceIndexArrayCount, TrackedDeviceIndex_t unRelativeToTrackedDeviceIndex);
EDeviceActivityLevel tr_ovw_GetTrackedDeviceActivityLevel(IVRSystem* self, TrackedDeviceIndex_t unDeviceId);
void tr_ovw_ApplyTransform(IVRSystem* self, TrackedDevicePose_t * pOutputPose, TrackedDevicePose_t * pTrackedDevicePose, HmdMatrix34_t * pTransform);
TrackedDeviceIndex_t tr_ovw_GetTrackedDeviceIndexForControllerRole(IVRSystem* self, ETrackedControllerRole unDeviceType);
ETrackedControllerRole tr_ovw_GetControllerRoleForTrackedDeviceIndex(IVRSystem* self, TrackedDeviceIndex_t unDeviceIndex);
ETrackedDeviceClass tr_ovw_GetTrackedDeviceClass(IVRSystem* self, TrackedDeviceIndex_t unDeviceIndex);
bool tr_ovw_IsTrackedDeviceConnected(IVRSystem* self, TrackedDeviceIndex_t unDeviceIndex);
bool tr_ovw_GetBoolTrackedDeviceProperty(IVRSystem* self, TrackedDeviceIndex_t unDeviceIndex, ETrackedDeviceProperty prop, ETrackedPropertyError * pError);
float tr_ovw_GetFloatTrackedDeviceProperty(IVRSystem* self, TrackedDeviceIndex_t unDeviceIndex, ETrackedDeviceProperty prop, ETrackedPropertyError * pError);
int32_t tr_ovw_GetInt32TrackedDeviceProperty(IVRSystem* self, TrackedDeviceIndex_t unDeviceIndex, ETrackedDeviceProperty prop, ETrackedPropertyError * pError);
uint64_t tr_ovw_GetUint64TrackedDeviceProperty(IVRSystem* self, TrackedDeviceIndex_t unDeviceIndex, ETrackedDeviceProperty prop, ETrackedPropertyError * pError);
HmdMatrix34_t tr_ovw_GetMatrix34TrackedDeviceProperty(IVRSystem* self, TrackedDeviceIndex_t unDeviceIndex, ETrackedDeviceProperty prop, ETrackedPropertyError * pError);
uint32_t tr_ovw_GetArrayTrackedDeviceProperty(IVRSystem* self, TrackedDeviceIndex_t unDeviceIndex, ETrackedDeviceProperty prop, PropertyTypeTag_t propType, void * pBuffer, uint32_t unBufferSize, ETrackedPropertyError * pError);
uint32_t tr_ovw_GetStringTrackedDeviceProperty(IVRSystem* self, TrackedDeviceIndex_t unDeviceIndex, ETrackedDeviceProperty prop, char * pchValue, uint32_t unBufferSize, ETrackedPropertyError * pError);
const char * tr_ovw_GetPropErrorNameFromEnum(IVRSystem* self, ETrackedPropertyError error);
bool tr_ovw_PollNextEvent(IVRSystem* self, VREvent_t * pEvent, uint32_t uncbVREvent);
bool tr_ovw_PollNextEventWithPose(IVRSystem* self, ETrackingUniverseOrigin eOrigin, VREvent_t * pEvent, uint32_t uncbVREvent, TrackedDevicePose_t * pTrackedDevicePose);
const char * tr_ovw_GetEventTypeNameFromEnum(IVRSystem* self, EVREventType eType);
HiddenAreaMesh_t tr_ovw_GetHiddenAreaMesh(IVRSystem* self, EVREye eEye, EHiddenAreaMeshType type);
bool tr_ovw_GetControllerState(IVRSystem* self, TrackedDeviceIndex_t unControllerDeviceIndex, VRControllerState_t * pControllerState, uint32_t unControllerStateSize);
bool tr_ovw_GetControllerStateWithPose(IVRSystem* self, ETrackingUniverseOrigin eOrigin, TrackedDeviceIndex_t unControllerDeviceIndex, VRControllerState_t * pControllerState, uint32_t unControllerStateSize, TrackedDevicePose_t * pTrackedDevicePose);
void tr_ovw_TriggerHapticPulse(IVRSystem* self, TrackedDeviceIndex_t unControllerDeviceIndex, uint32_t unAxisId, unsigned short usDurationMicroSec);
const char * tr_ovw_GetButtonIdNameFromEnum(IVRSystem* self, EVRButtonId eButtonId);
const char * tr_ovw_GetControllerAxisTypeNameFromEnum(IVRSystem* self, EVRControllerAxisType eAxisType);
bool tr_ovw_IsInputAvailable(IVRSystem* self);
bool tr_ovw_IsSteamVRDrawingControllers(IVRSystem* self);
bool tr_ovw_ShouldApplicationPause(IVRSystem* self);
bool tr_ovw_ShouldApplicationReduceRenderingWork(IVRSystem* self);
uint32_t tr_ovw_DriverDebugRequest(IVRSystem* self, TrackedDeviceIndex_t unDeviceIndex, const char * pchRequest, char * pchResponseBuffer, uint32_t unResponseBufferSize);
EVRFirmwareError tr_ovw_PerformFirmwareUpdate(IVRSystem* self, TrackedDeviceIndex_t unDeviceIndex);
void tr_ovw_AcknowledgeQuit_Exiting(IVRSystem* self);
void tr_ovw_AcknowledgeQuit_UserPrompt(IVRSystem* self);
void tr_ovw_GetWindowBounds(IVRExtendedDisplay* self, int32_t * pnX, int32_t * pnY, uint32_t * pnWidth, uint32_t * pnHeight);
void tr_ovw_GetEyeOutputViewport(IVRExtendedDisplay* self, EVREye eEye, uint32_t * pnX, uint32_t * pnY, uint32_t * pnWidth, uint32_t * pnHeight);
//void tr_ovw_GetDXGIOutputInfo(IVRExtendedDisplay* self, int32_t * pnAdapterIndex, int32_t * pnAdapterOutputIndex);
const char * tr_ovw_GetCameraErrorNameFromEnum(IVRTrackedCamera* self, EVRTrackedCameraError eCameraError);
EVRTrackedCameraError tr_ovw_HasCamera(IVRTrackedCamera* self, TrackedDeviceIndex_t nDeviceIndex, bool * pHasCamera);
EVRTrackedCameraError tr_ovw_GetCameraFrameSize(IVRTrackedCamera* self, TrackedDeviceIndex_t nDeviceIndex, EVRTrackedCameraFrameType eFrameType, uint32_t * pnWidth, uint32_t * pnHeight, uint32_t * pnFrameBufferSize);
EVRTrackedCameraError tr_ovw_GetCameraIntrinsics(IVRTrackedCamera* self, TrackedDeviceIndex_t nDeviceIndex, uint32_t nCameraIndex, EVRTrackedCameraFrameType eFrameType, HmdVector2_t * pFocalLength, HmdVector2_t * pCenter);
EVRTrackedCameraError tr_ovw_GetCameraProjection(IVRTrackedCamera* self, TrackedDeviceIndex_t nDeviceIndex, uint32_t nCameraIndex, EVRTrackedCameraFrameType eFrameType, float flZNear, float flZFar, HmdMatrix44_t * pProjection);
EVRTrackedCameraError tr_ovw_AcquireVideoStreamingService(IVRTrackedCamera* self, TrackedDeviceIndex_t nDeviceIndex, TrackedCameraHandle_t * pHandle);
EVRTrackedCameraError tr_ovw_ReleaseVideoStreamingService(IVRTrackedCamera* self, TrackedCameraHandle_t hTrackedCamera);
EVRTrackedCameraError tr_ovw_GetVideoStreamFrameBuffer(IVRTrackedCamera* self, TrackedCameraHandle_t hTrackedCamera, EVRTrackedCameraFrameType eFrameType, void * pFrameBuffer, uint32_t nFrameBufferSize, CameraVideoStreamFrameHeader_t * pFrameHeader, uint32_t nFrameHeaderSize);
EVRTrackedCameraError tr_ovw_GetVideoStreamTextureSize(IVRTrackedCamera* self, TrackedDeviceIndex_t nDeviceIndex, EVRTrackedCameraFrameType eFrameType, VRTextureBounds_t * pTextureBounds, uint32_t * pnWidth, uint32_t * pnHeight);
EVRTrackedCameraError tr_ovw_GetVideoStreamTextureD3D11(IVRTrackedCamera* self, TrackedCameraHandle_t hTrackedCamera, EVRTrackedCameraFrameType eFrameType, void * pD3D11DeviceOrResource, void ** ppD3D11ShaderResourceView, CameraVideoStreamFrameHeader_t * pFrameHeader, uint32_t nFrameHeaderSize);
EVRTrackedCameraError tr_ovw_GetVideoStreamTextureGL(IVRTrackedCamera* self, TrackedCameraHandle_t hTrackedCamera, EVRTrackedCameraFrameType eFrameType, glUInt_t * pglTextureId, CameraVideoStreamFrameHeader_t * pFrameHeader, uint32_t nFrameHeaderSize);
EVRTrackedCameraError tr_ovw_ReleaseVideoStreamTextureGL(IVRTrackedCamera* self, TrackedCameraHandle_t hTrackedCamera, glUInt_t glTextureId);
EVRApplicationError tr_ovw_AddApplicationManifest(IVRApplications* self, const char * pchApplicationManifestFullPath, bool bTemporary);
EVRApplicationError tr_ovw_RemoveApplicationManifest(IVRApplications* self, const char * pchApplicationManifestFullPath);
bool tr_ovw_IsApplicationInstalled(IVRApplications* self, const char * pchAppKey);
uint32_t tr_ovw_GetApplicationCount(IVRApplications* self);
EVRApplicationError tr_ovw_GetApplicationKeyByIndex(IVRApplications* self, uint32_t unApplicationIndex, char * pchAppKeyBuffer, uint32_t unAppKeyBufferLen);
EVRApplicationError tr_ovw_GetApplicationKeyByProcessId(IVRApplications* self, uint32_t unProcessId, char * pchAppKeyBuffer, uint32_t unAppKeyBufferLen);
EVRApplicationError tr_ovw_LaunchApplication(IVRApplications* self, const char * pchAppKey);
EVRApplicationError tr_ovw_LaunchTemplateApplication(IVRApplications* self, const char * pchTemplateAppKey, const char * pchNewAppKey, AppOverrideKeys_t * pKeys, uint32_t unKeys);
EVRApplicationError tr_ovw_LaunchApplicationFromMimeType(IVRApplications* self, const char * pchMimeType, const char * pchArgs);
EVRApplicationError tr_ovw_LaunchDashboardOverlay(IVRApplications* self, const char * pchAppKey);
bool tr_ovw_CancelApplicationLaunch(IVRApplications* self, const char * pchAppKey);
EVRApplicationError tr_ovw_IdentifyApplication(IVRApplications* self, uint32_t unProcessId, const char * pchAppKey);
uint32_t tr_ovw_GetApplicationProcessId(IVRApplications* self, const char * pchAppKey);
const char * tr_ovw_GetApplicationsErrorNameFromEnum(IVRApplications* self, EVRApplicationError error);
uint32_t tr_ovw_GetApplicationPropertyString(IVRApplications* self, const char * pchAppKey, EVRApplicationProperty eProperty, char * pchPropertyValueBuffer, uint32_t unPropertyValueBufferLen, EVRApplicationError * peError);
bool tr_ovw_GetApplicationPropertyBool(IVRApplications* self, const char * pchAppKey, EVRApplicationProperty eProperty, EVRApplicationError * peError);
uint64_t tr_ovw_GetApplicationPropertyUint64(IVRApplications* self, const char * pchAppKey, EVRApplicationProperty eProperty, EVRApplicationError * peError);
EVRApplicationError tr_ovw_SetApplicationAutoLaunch(IVRApplications* self, const char * pchAppKey, bool bAutoLaunch);
bool tr_ovw_GetApplicationAutoLaunch(IVRApplications* self, const char * pchAppKey);
EVRApplicationError tr_ovw_SetDefaultApplicationForMimeType(IVRApplications* self, const char * pchAppKey, const char * pchMimeType);
bool tr_ovw_GetDefaultApplicationForMimeType(IVRApplications* self, const char * pchMimeType, char * pchAppKeyBuffer, uint32_t unAppKeyBufferLen);
bool tr_ovw_GetApplicationSupportedMimeTypes(IVRApplications* self, const char * pchAppKey, char * pchMimeTypesBuffer, uint32_t unMimeTypesBuffer);
uint32_t tr_ovw_GetApplicationsThatSupportMimeType(IVRApplications* self, const char * pchMimeType, char * pchAppKeysThatSupportBuffer, uint32_t unAppKeysThatSupportBuffer);
uint32_t tr_ovw_GetApplicationLaunchArguments(IVRApplications* self, uint32_t unHandle, char * pchArgs, uint32_t unArgs);
EVRApplicationError tr_ovw_GetStartingApplication(IVRApplications* self, char * pchAppKeyBuffer, uint32_t unAppKeyBufferLen);
EVRApplicationTransitionState tr_ovw_GetTransitionState(IVRApplications* self);
EVRApplicationError tr_ovw_PerformApplicationPrelaunchCheck(IVRApplications* self, const char * pchAppKey);
const char * tr_ovw_GetApplicationsTransitionStateNameFromEnum(IVRApplications* self, EVRApplicationTransitionState state);
bool tr_ovw_IsQuitUserPromptRequested(IVRApplications* self);
EVRApplicationError tr_ovw_LaunchInternalProcess(IVRApplications* self, const char * pchBinaryPath, const char * pchArguments, const char * pchWorkingDirectory);
uint32_t tr_ovw_GetCurrentSceneProcessId(IVRApplications* self);
ChaperoneCalibrationState tr_ovw_GetCalibrationState(IVRChaperone* self);
bool tr_ovw_GetPlayAreaSize(IVRChaperone* self, float * pSizeX, float * pSizeZ);
bool tr_ovw_GetPlayAreaRect(IVRChaperone* self, HmdQuad_t * rect);
void tr_ovw_ReloadInfo(IVRChaperone* self);
void tr_ovw_SetSceneColor(IVRChaperone* self, HmdColor_t color);
void tr_ovw_GetBoundsColor(IVRChaperone* self, HmdColor_t * pOutputColorArray, int nNumOutputColors, float flCollisionBoundsFadeDistance, HmdColor_t * pOutputCameraColor);
bool tr_ovw_AreBoundsVisible(IVRChaperone* self);
void tr_ovw_ForceBoundsVisible(IVRChaperone* self, bool bForce);
bool tr_ovw_CommitWorkingCopy(IVRChaperoneSetup* self, EChaperoneConfigFile configFile);
void tr_ovw_RevertWorkingCopy(IVRChaperoneSetup* self);
bool tr_ovw_GetWorkingPlayAreaSize(IVRChaperoneSetup* self, float * pSizeX, float * pSizeZ);
bool tr_ovw_GetWorkingPlayAreaRect(IVRChaperoneSetup* self, HmdQuad_t * rect);
bool tr_ovw_GetWorkingCollisionBoundsInfo(IVRChaperoneSetup* self, HmdQuad_t * pQuadsBuffer, uint32_t * punQuadsCount);
bool tr_ovw_GetLiveCollisionBoundsInfo(IVRChaperoneSetup* self, HmdQuad_t * pQuadsBuffer, uint32_t * punQuadsCount);
bool tr_ovw_GetWorkingSeatedZeroPoseToRawTrackingPose(IVRChaperoneSetup* self, HmdMatrix34_t * pmatSeatedZeroPoseToRawTrackingPose);
bool tr_ovw_GetWorkingStandingZeroPoseToRawTrackingPose(IVRChaperoneSetup* self, HmdMatrix34_t * pmatStandingZeroPoseToRawTrackingPose);
void tr_ovw_SetWorkingPlayAreaSize(IVRChaperoneSetup* self, float sizeX, float sizeZ);
void tr_ovw_SetWorkingCollisionBoundsInfo(IVRChaperoneSetup* self, HmdQuad_t * pQuadsBuffer, uint32_t unQuadsCount);
void tr_ovw_SetWorkingPerimeter(IVRChaperoneSetup* self, HmdVector2_t * pPointBuffer, uint32_t unPointCount);
void tr_ovw_SetWorkingSeatedZeroPoseToRawTrackingPose(IVRChaperoneSetup* self, HmdMatrix34_t * pMatSeatedZeroPoseToRawTrackingPose);
void tr_ovw_SetWorkingStandingZeroPoseToRawTrackingPose(IVRChaperoneSetup* self, HmdMatrix34_t * pMatStandingZeroPoseToRawTrackingPose);
void tr_ovw_ReloadFromDisk(IVRChaperoneSetup* self, EChaperoneConfigFile configFile);
bool tr_ovw_GetLiveSeatedZeroPoseToRawTrackingPose(IVRChaperoneSetup* self, HmdMatrix34_t * pmatSeatedZeroPoseToRawTrackingPose);
bool tr_ovw_ExportLiveToBuffer(IVRChaperoneSetup* self, char * pBuffer, uint32_t * pnBufferLength);
bool tr_ovw_ImportFromBufferToWorking(IVRChaperoneSetup* self, const char * pBuffer, uint32_t nImportFlags);
void tr_ovw_ShowWorkingSetPreview(IVRChaperoneSetup* self);
void tr_ovw_HideWorkingSetPreview(IVRChaperoneSetup* self);
void tr_ovw_SetTrackingSpace(IVRCompositor* self, ETrackingUniverseOrigin eOrigin);
ETrackingUniverseOrigin tr_ovw_GetTrackingSpace(IVRCompositor* self);
EVRCompositorError tr_ovw_WaitGetPoses(IVRCompositor* self, TrackedDevicePose_t * pRenderPoseArray, uint32_t unRenderPoseArrayCount, TrackedDevicePose_t * pGamePoseArray, uint32_t unGamePoseArrayCount);
EVRCompositorError tr_ovw_GetLastPoses(IVRCompositor* self, TrackedDevicePose_t * pRenderPoseArray, uint32_t unRenderPoseArrayCount, TrackedDevicePose_t * pGamePoseArray, uint32_t unGamePoseArrayCount);
EVRCompositorError tr_ovw_GetLastPoseForTrackedDeviceIndex(IVRCompositor* self, TrackedDeviceIndex_t unDeviceIndex, TrackedDevicePose_t * pOutputPose, TrackedDevicePose_t * pOutputGamePose);
EVRCompositorError tr_ovw_Submit(IVRCompositor* self, EVREye eEye, Texture_t * pTexture, VRTextureBounds_t * pBounds, EVRSubmitFlags nSubmitFlags);
void tr_ovw_ClearLastSubmittedFrame(IVRCompositor* self);
void tr_ovw_PostPresentHandoff(IVRCompositor* self);
bool tr_ovw_GetFrameTiming(IVRCompositor* self, Compositor_FrameTiming * pTiming, uint32_t unFramesAgo);
uint32_t tr_ovw_GetFrameTimings(IVRCompositor* self, Compositor_FrameTiming * pTiming, uint32_t nFrames);
float tr_ovw_GetFrameTimeRemaining(IVRCompositor* self);
void tr_ovw_GetCumulativeStats(IVRCompositor* self, Compositor_CumulativeStats * pStats, uint32_t nStatsSizeInBytes);
void tr_ovw_FadeToColor(IVRCompositor* self, float fSeconds, float fRed, float fGreen, float fBlue, float fAlpha, bool bBackground);
HmdColor_t tr_ovw_GetCurrentFadeColor(IVRCompositor* self, bool bBackground);
void tr_ovw_FadeGrid(IVRCompositor* self, float fSeconds, bool bFadeIn);
float tr_ovw_GetCurrentGridAlpha(IVRCompositor* self);
EVRCompositorError tr_ovw_SetSkyboxOverride(IVRCompositor* self, Texture_t * pTextures, uint32_t unTextureCount);
void tr_ovw_ClearSkyboxOverride(IVRCompositor* self);
void tr_ovw_CompositorBringToFront(IVRCompositor* self);
void tr_ovw_CompositorGoToBack(IVRCompositor* self);
void tr_ovw_CompositorQuit(IVRCompositor* self);
bool tr_ovw_IsFullscreen(IVRCompositor* self);
uint32_t tr_ovw_GetCurrentSceneFocusProcess(IVRCompositor* self);
uint32_t tr_ovw_GetLastFrameRenderer(IVRCompositor* self);
bool tr_ovw_CanRenderScene(IVRCompositor* self);
void tr_ovw_ShowMirrorWindow(IVRCompositor* self);
void tr_ovw_HideMirrorWindow(IVRCompositor* self);
bool tr_ovw_IsMirrorWindowVisible(IVRCompositor* self);
void tr_ovw_CompositorDumpImages(IVRCompositor* self);
bool tr_ovw_ShouldAppRenderWithLowResources(IVRCompositor* self);
void tr_ovw_ForceInterleavedReprojectionOn(IVRCompositor* self, bool bOverride);
void tr_ovw_ForceReconnectProcess(IVRCompositor* self);
void tr_ovw_SuspendRendering(IVRCompositor* self, bool bSuspend);
EVRCompositorError tr_ovw_GetMirrorTextureD3D11(IVRCompositor* self, EVREye eEye, void * pD3D11DeviceOrResource, void ** ppD3D11ShaderResourceView);
void tr_ovw_ReleaseMirrorTextureD3D11(IVRCompositor* self, void * pD3D11ShaderResourceView);
EVRCompositorError tr_ovw_GetMirrorTextureGL(IVRCompositor* self, EVREye eEye, glUInt_t * pglTextureId, glSharedTextureHandle_t * pglSharedTextureHandle);
bool tr_ovw_ReleaseSharedGLTexture(IVRCompositor* self, glUInt_t glTextureId, glSharedTextureHandle_t glSharedTextureHandle);
void tr_ovw_LockGLSharedTextureForAccess(IVRCompositor* self, glSharedTextureHandle_t glSharedTextureHandle);
void tr_ovw_UnlockGLSharedTextureForAccess(IVRCompositor* self, glSharedTextureHandle_t glSharedTextureHandle);
uint32_t tr_ovw_GetVulkanInstanceExtensionsRequired(IVRCompositor* self, char * pchValue, uint32_t unBufferSize);
uint32_t tr_ovw_GetVulkanDeviceExtensionsRequired(IVRCompositor* self, VkPhysicalDevice_T * pPhysicalDevice, char * pchValue, uint32_t unBufferSize);
void tr_ovw_SetExplicitTimingMode(IVRCompositor* self, EVRCompositorTimingMode eTimingMode);
EVRCompositorError tr_ovw_SubmitExplicitTimingData(IVRCompositor* self);
bool tr_ovw_IsMotionSmoothingEnabled(IVRCompositor* self);
EVROverlayError tr_ovw_FindOverlay(IVROverlay* self, const char * pchOverlayKey, VROverlayHandle_t * pOverlayHandle);
EVROverlayError tr_ovw_CreateOverlay(IVROverlay* self, const char * pchOverlayKey, const char * pchOverlayName, VROverlayHandle_t * pOverlayHandle);
EVROverlayError tr_ovw_DestroyOverlay(IVROverlay* self, VROverlayHandle_t ulOverlayHandle);
EVROverlayError tr_ovw_SetHighQualityOverlay(IVROverlay* self, VROverlayHandle_t ulOverlayHandle);
VROverlayHandle_t tr_ovw_GetHighQualityOverlay(IVROverlay* self);
uint32_t tr_ovw_GetOverlayKey(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, char * pchValue, uint32_t unBufferSize, EVROverlayError * pError);
uint32_t tr_ovw_GetOverlayName(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, char * pchValue, uint32_t unBufferSize, EVROverlayError * pError);
EVROverlayError tr_ovw_SetOverlayName(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, const char * pchName);
EVROverlayError tr_ovw_GetOverlayImageData(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, void * pvBuffer, uint32_t unBufferSize, uint32_t * punWidth, uint32_t * punHeight);
const char * tr_ovw_GetOverlayErrorNameFromEnum(IVROverlay* self, EVROverlayError error);
EVROverlayError tr_ovw_SetOverlayRenderingPid(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, uint32_t unPID);
uint32_t tr_ovw_GetOverlayRenderingPid(IVROverlay* self, VROverlayHandle_t ulOverlayHandle);
EVROverlayError tr_ovw_SetOverlayFlag(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, VROverlayFlags eOverlayFlag, bool bEnabled);
EVROverlayError tr_ovw_GetOverlayFlag(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, VROverlayFlags eOverlayFlag, bool * pbEnabled);
EVROverlayError tr_ovw_SetOverlayColor(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, float fRed, float fGreen, float fBlue);
EVROverlayError tr_ovw_GetOverlayColor(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, float * pfRed, float * pfGreen, float * pfBlue);
EVROverlayError tr_ovw_SetOverlayAlpha(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, float fAlpha);
EVROverlayError tr_ovw_GetOverlayAlpha(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, float * pfAlpha);
EVROverlayError tr_ovw_SetOverlayTexelAspect(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, float fTexelAspect);
EVROverlayError tr_ovw_GetOverlayTexelAspect(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, float * pfTexelAspect);
EVROverlayError tr_ovw_SetOverlaySortOrder(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, uint32_t unSortOrder);
EVROverlayError tr_ovw_GetOverlaySortOrder(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, uint32_t * punSortOrder);
EVROverlayError tr_ovw_SetOverlayWidthInMeters(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, float fWidthInMeters);
EVROverlayError tr_ovw_GetOverlayWidthInMeters(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, float * pfWidthInMeters);
EVROverlayError tr_ovw_SetOverlayAutoCurveDistanceRangeInMeters(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, float fMinDistanceInMeters, float fMaxDistanceInMeters);
EVROverlayError tr_ovw_GetOverlayAutoCurveDistanceRangeInMeters(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, float * pfMinDistanceInMeters, float * pfMaxDistanceInMeters);
EVROverlayError tr_ovw_SetOverlayTextureColorSpace(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, EColorSpace eTextureColorSpace);
EVROverlayError tr_ovw_GetOverlayTextureColorSpace(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, EColorSpace * peTextureColorSpace);
EVROverlayError tr_ovw_SetOverlayTextureBounds(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, VRTextureBounds_t * pOverlayTextureBounds);
EVROverlayError tr_ovw_GetOverlayTextureBounds(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, VRTextureBounds_t * pOverlayTextureBounds);
uint32_t tr_ovw_GetOverlayRenderModel(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, char * pchValue, uint32_t unBufferSize, HmdColor_t * pColor, EVROverlayError * pError);
EVROverlayError tr_ovw_SetOverlayRenderModel(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, const char * pchRenderModel, HmdColor_t * pColor);
EVROverlayError tr_ovw_GetOverlayTransformType(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, VROverlayTransformType * peTransformType);
EVROverlayError tr_ovw_SetOverlayTransformAbsolute(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, ETrackingUniverseOrigin eTrackingOrigin, HmdMatrix34_t * pmatTrackingOriginToOverlayTransform);
EVROverlayError tr_ovw_GetOverlayTransformAbsolute(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, ETrackingUniverseOrigin * peTrackingOrigin, HmdMatrix34_t * pmatTrackingOriginToOverlayTransform);
EVROverlayError tr_ovw_SetOverlayTransformTrackedDeviceRelative(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, TrackedDeviceIndex_t unTrackedDevice, HmdMatrix34_t * pmatTrackedDeviceToOverlayTransform);
EVROverlayError tr_ovw_GetOverlayTransformTrackedDeviceRelative(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, TrackedDeviceIndex_t * punTrackedDevice, HmdMatrix34_t * pmatTrackedDeviceToOverlayTransform);
EVROverlayError tr_ovw_SetOverlayTransformTrackedDeviceComponent(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, TrackedDeviceIndex_t unDeviceIndex, const char * pchComponentName);
EVROverlayError tr_ovw_GetOverlayTransformTrackedDeviceComponent(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, TrackedDeviceIndex_t * punDeviceIndex, char * pchComponentName, uint32_t unComponentNameSize);
EVROverlayError tr_ovw_GetOverlayTransformOverlayRelative(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, VROverlayHandle_t * ulOverlayHandleParent, HmdMatrix34_t * pmatParentOverlayToOverlayTransform);
EVROverlayError tr_ovw_SetOverlayTransformOverlayRelative(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, VROverlayHandle_t ulOverlayHandleParent, HmdMatrix34_t * pmatParentOverlayToOverlayTransform);
EVROverlayError tr_ovw_ShowOverlay(IVROverlay* self, VROverlayHandle_t ulOverlayHandle);
EVROverlayError tr_ovw_HideOverlay(IVROverlay* self, VROverlayHandle_t ulOverlayHandle);
bool tr_ovw_IsOverlayVisible(IVROverlay* self, VROverlayHandle_t ulOverlayHandle);
EVROverlayError tr_ovw_GetTransformForOverlayCoordinates(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, ETrackingUniverseOrigin eTrackingOrigin, HmdVector2_t coordinatesInOverlay, HmdMatrix34_t * pmatTransform);
bool tr_ovw_PollNextOverlayEvent(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, VREvent_t * pEvent, uint32_t uncbVREvent);
EVROverlayError tr_ovw_GetOverlayInputMethod(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, VROverlayInputMethod * peInputMethod);
EVROverlayError tr_ovw_SetOverlayInputMethod(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, VROverlayInputMethod eInputMethod);
EVROverlayError tr_ovw_GetOverlayMouseScale(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, HmdVector2_t * pvecMouseScale);
EVROverlayError tr_ovw_SetOverlayMouseScale(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, HmdVector2_t * pvecMouseScale);
bool tr_ovw_ComputeOverlayIntersection(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, VROverlayIntersectionParams_t * pParams, VROverlayIntersectionResults_t * pResults);
bool tr_ovw_IsHoverTargetOverlay(IVROverlay* self, VROverlayHandle_t ulOverlayHandle);
VROverlayHandle_t tr_ovw_GetGamepadFocusOverlay(IVROverlay* self);
EVROverlayError tr_ovw_SetGamepadFocusOverlay(IVROverlay* self, VROverlayHandle_t ulNewFocusOverlay);
EVROverlayError tr_ovw_SetOverlayNeighbor(IVROverlay* self, EOverlayDirection eDirection, VROverlayHandle_t ulFrom, VROverlayHandle_t ulTo);
EVROverlayError tr_ovw_MoveGamepadFocusToNeighbor(IVROverlay* self, EOverlayDirection eDirection, VROverlayHandle_t ulFrom);
EVROverlayError tr_ovw_SetOverlayDualAnalogTransform(IVROverlay* self, VROverlayHandle_t ulOverlay, EDualAnalogWhich eWhich, HmdVector2_t * pvCenter, float fRadius);
EVROverlayError tr_ovw_GetOverlayDualAnalogTransform(IVROverlay* self, VROverlayHandle_t ulOverlay, EDualAnalogWhich eWhich, HmdVector2_t * pvCenter, float * pfRadius);
EVROverlayError tr_ovw_SetOverlayTexture(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, Texture_t * pTexture);
EVROverlayError tr_ovw_ClearOverlayTexture(IVROverlay* self, VROverlayHandle_t ulOverlayHandle);
EVROverlayError tr_ovw_SetOverlayRaw(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, void * pvBuffer, uint32_t unWidth, uint32_t unHeight, uint32_t unDepth);
EVROverlayError tr_ovw_SetOverlayFromFile(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, const char * pchFilePath);
EVROverlayError tr_ovw_GetOverlayTexture(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, void ** pNativeTextureHandle, void * pNativeTextureRef, uint32_t * pWidth, uint32_t * pHeight, uint32_t * pNativeFormat, ETextureType * pAPIType, EColorSpace * pColorSpace, VRTextureBounds_t * pTextureBounds);
EVROverlayError tr_ovw_ReleaseNativeOverlayHandle(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, void * pNativeTextureHandle);
EVROverlayError tr_ovw_GetOverlayTextureSize(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, uint32_t * pWidth, uint32_t * pHeight);
EVROverlayError tr_ovw_CreateDashboardOverlay(IVROverlay* self, const char * pchOverlayKey, const char * pchOverlayFriendlyName, VROverlayHandle_t * pMainHandle, VROverlayHandle_t * pThumbnailHandle);
bool tr_ovw_IsDashboardVisible(IVROverlay* self);
bool tr_ovw_IsActiveDashboardOverlay(IVROverlay* self, VROverlayHandle_t ulOverlayHandle);
EVROverlayError tr_ovw_SetDashboardOverlaySceneProcess(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, uint32_t unProcessId);
EVROverlayError tr_ovw_GetDashboardOverlaySceneProcess(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, uint32_t * punProcessId);
void tr_ovw_ShowDashboard(IVROverlay* self, const char * pchOverlayToShow);
TrackedDeviceIndex_t tr_ovw_GetPrimaryDashboardDevice(IVROverlay* self);
EVROverlayError tr_ovw_ShowKeyboard(IVROverlay* self, EGamepadTextInputMode eInputMode, EGamepadTextInputLineMode eLineInputMode, const char * pchDescription, uint32_t unCharMax, const char * pchExistingText, bool bUseMinimalMode, uint64_t uUserValue);
EVROverlayError tr_ovw_ShowKeyboardForOverlay(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, EGamepadTextInputMode eInputMode, EGamepadTextInputLineMode eLineInputMode, const char * pchDescription, uint32_t unCharMax, const char * pchExistingText, bool bUseMinimalMode, uint64_t uUserValue);
uint32_t tr_ovw_GetKeyboardText(IVROverlay* self, char * pchText, uint32_t cchText);
void tr_ovw_HideKeyboard(IVROverlay* self);
void tr_ovw_SetKeyboardTransformAbsolute(IVROverlay* self, ETrackingUniverseOrigin eTrackingOrigin, HmdMatrix34_t * pmatTrackingOriginToKeyboardTransform);
void tr_ovw_SetKeyboardPositionForOverlay(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, HmdRect2_t avoidRect);
EVROverlayError tr_ovw_SetOverlayIntersectionMask(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, VROverlayIntersectionMaskPrimitive_t * pMaskPrimitives, uint32_t unNumMaskPrimitives, uint32_t unPrimitiveSize);
EVROverlayError tr_ovw_GetOverlayFlags(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, uint32_t * pFlags);
VRMessageOverlayResponse tr_ovw_ShowMessageOverlay(IVROverlay* self, const char * pchText, const char * pchCaption, const char * pchButton0Text, const char * pchButton1Text, const char * pchButton2Text, const char * pchButton3Text);
void tr_ovw_CloseMessageOverlay(IVROverlay* self);
EVRRenderModelError tr_ovw_LoadRenderModel_Async(IVRRenderModels* self, const char * pchRenderModelName, RenderModel_t ** ppRenderModel);
void tr_ovw_FreeRenderModel(IVRRenderModels* self, RenderModel_t * pRenderModel);
EVRRenderModelError tr_ovw_LoadTexture_Async(IVRRenderModels* self, TextureID_t textureId, RenderModel_TextureMap_t ** ppTexture);
void tr_ovw_FreeTexture(IVRRenderModels* self, RenderModel_TextureMap_t * pTexture);
EVRRenderModelError tr_ovw_LoadTextureD3D11_Async(IVRRenderModels* self, TextureID_t textureId, void * pD3D11Device, void ** ppD3D11Texture2D);
EVRRenderModelError tr_ovw_LoadIntoTextureD3D11_Async(IVRRenderModels* self, TextureID_t textureId, void * pDstTexture);
void tr_ovw_FreeTextureD3D11(IVRRenderModels* self, void * pD3D11Texture2D);
uint32_t tr_ovw_GetRenderModelName(IVRRenderModels* self, uint32_t unRenderModelIndex, char * pchRenderModelName, uint32_t unRenderModelNameLen);
uint32_t tr_ovw_GetRenderModelCount(IVRRenderModels* self);
uint32_t tr_ovw_GetComponentCount(IVRRenderModels* self, const char * pchRenderModelName);
uint32_t tr_ovw_GetComponentName(IVRRenderModels* self, const char * pchRenderModelName, uint32_t unComponentIndex, char * pchComponentName, uint32_t unComponentNameLen);
uint64_t tr_ovw_GetComponentButtonMask(IVRRenderModels* self, const char * pchRenderModelName, const char * pchComponentName);
uint32_t tr_ovw_GetComponentRenderModelName(IVRRenderModels* self, const char * pchRenderModelName, const char * pchComponentName, char * pchComponentRenderModelName, uint32_t unComponentRenderModelNameLen);
bool tr_ovw_GetComponentStateForDevicePath(IVRRenderModels* self, const char * pchRenderModelName, const char * pchComponentName, VRInputValueHandle_t devicePath, RenderModel_ControllerMode_State_t * pState, RenderModel_ComponentState_t * pComponentState);
bool tr_ovw_GetComponentState(IVRRenderModels* self, const char * pchRenderModelName, const char * pchComponentName, VRControllerState_t * pControllerState, RenderModel_ControllerMode_State_t * pState, RenderModel_ComponentState_t * pComponentState);
bool tr_ovw_RenderModelHasComponent(IVRRenderModels* self, const char * pchRenderModelName, const char * pchComponentName);
uint32_t tr_ovw_GetRenderModelThumbnailURL(IVRRenderModels* self, const char * pchRenderModelName, char * pchThumbnailURL, uint32_t unThumbnailURLLen, EVRRenderModelError * peError);
uint32_t tr_ovw_GetRenderModelOriginalPath(IVRRenderModels* self, const char * pchRenderModelName, char * pchOriginalPath, uint32_t unOriginalPathLen, EVRRenderModelError * peError);
const char * tr_ovw_GetRenderModelErrorNameFromEnum(IVRRenderModels* self, EVRRenderModelError error);
EVRNotificationError tr_ovw_CreateNotification(IVRNotifications* self, VROverlayHandle_t ulOverlayHandle, uint64_t ulUserValue, EVRNotificationType type, const char * pchText, EVRNotificationStyle style, NotificationBitmap_t * pImage, VRNotificationId * pNotificationId);
EVRNotificationError tr_ovw_RemoveNotification(IVRNotifications* self, VRNotificationId notificationId);
const char * tr_ovw_GetSettingsErrorNameFromEnum(IVRSettings* self, EVRSettingsError eError);
bool tr_ovw_Sync(IVRSettings* self, bool bForce, EVRSettingsError * peError);
void tr_ovw_SetBool(IVRSettings* self, const char * pchSection, const char * pchSettingsKey, bool bValue, EVRSettingsError * peError);
void tr_ovw_SetInt32(IVRSettings* self, const char * pchSection, const char * pchSettingsKey, int32_t nValue, EVRSettingsError * peError);
void tr_ovw_SetFloat(IVRSettings* self, const char * pchSection, const char * pchSettingsKey, float flValue, EVRSettingsError * peError);
void tr_ovw_SetString(IVRSettings* self, const char * pchSection, const char * pchSettingsKey, const char * pchValue, EVRSettingsError * peError);
bool tr_ovw_GetBool(IVRSettings* self, const char * pchSection, const char * pchSettingsKey, EVRSettingsError * peError);
int32_t tr_ovw_GetInt32(IVRSettings* self, const char * pchSection, const char * pchSettingsKey, EVRSettingsError * peError);
float tr_ovw_GetFloat(IVRSettings* self, const char * pchSection, const char * pchSettingsKey, EVRSettingsError * peError);
void tr_ovw_GetString(IVRSettings* self, const char * pchSection, const char * pchSettingsKey, char * pchValue, uint32_t unValueLen, EVRSettingsError * peError);
void tr_ovw_RemoveSection(IVRSettings* self, const char * pchSection, EVRSettingsError * peError);
void tr_ovw_RemoveKeyInSection(IVRSettings* self, const char * pchSection, const char * pchSettingsKey, EVRSettingsError * peError);
EVRScreenshotError tr_ovw_RequestScreenshot(IVRScreenshots* self, ScreenshotHandle_t * pOutScreenshotHandle, EVRScreenshotType type, const char * pchPreviewFilename, const char * pchVRFilename);
EVRScreenshotError tr_ovw_HookScreenshot(IVRScreenshots* self, EVRScreenshotType * pSupportedTypes, int numTypes);
EVRScreenshotType tr_ovw_GetScreenshotPropertyType(IVRScreenshots* self, ScreenshotHandle_t screenshotHandle, EVRScreenshotError * pError);
uint32_t tr_ovw_GetScreenshotPropertyFilename(IVRScreenshots* self, ScreenshotHandle_t screenshotHandle, EVRScreenshotPropertyFilenames filenameType, char * pchFilename, uint32_t cchFilename, EVRScreenshotError * pError);
EVRScreenshotError tr_ovw_UpdateScreenshotProgress(IVRScreenshots* self, ScreenshotHandle_t screenshotHandle, float flProgress);
EVRScreenshotError tr_ovw_TakeStereoScreenshot(IVRScreenshots* self, ScreenshotHandle_t * pOutScreenshotHandle, const char * pchPreviewFilename, const char * pchVRFilename);
EVRScreenshotError tr_ovw_SubmitScreenshot(IVRScreenshots* self, ScreenshotHandle_t screenshotHandle, EVRScreenshotType type, const char * pchSourcePreviewFilename, const char * pchSourceVRFilename);
uint32_t tr_ovw_LoadSharedResource(IVRResources* self, const char * pchResourceName, char * pchBuffer, uint32_t unBufferLen);
uint32_t tr_ovw_GetResourceFullPath(IVRResources* self, const char * pchResourceName, const char * pchResourceTypeDirectory, char * pchPathBuffer, uint32_t unBufferLen);
uint32_t tr_ovw_GetDriverCount(IVRDriverManager* self);
uint32_t tr_ovw_GetDriverName(IVRDriverManager* self, DriverId_t nDriver, char * pchValue, uint32_t unBufferSize);
DriverHandle_t tr_ovw_GetDriverHandle(IVRDriverManager* self, const char * pchDriverName);
EVRInputError tr_ovw_SetActionManifestPath(IVRInput* self, const char * pchActionManifestPath);
EVRInputError tr_ovw_GetActionSetHandle(IVRInput* self, const char * pchActionSetName, VRActionSetHandle_t * pHandle);
EVRInputError tr_ovw_GetActionHandle(IVRInput* self, const char * pchActionName, VRActionHandle_t * pHandle);
EVRInputError tr_ovw_GetInputSourceHandle(IVRInput* self, const char * pchInputSourcePath, VRInputValueHandle_t * pHandle);
EVRInputError tr_ovw_UpdateActionState(IVRInput* self, VRActiveActionSet_t * pSets, uint32_t unSizeOfVRSelectedActionSet_t, uint32_t unSetCount);
EVRInputError tr_ovw_GetDigitalActionData(IVRInput* self, VRActionHandle_t action, InputDigitalActionData_t * pActionData, uint32_t unActionDataSize, VRInputValueHandle_t ulRestrictToDevice);
EVRInputError tr_ovw_GetAnalogActionData(IVRInput* self, VRActionHandle_t action, InputAnalogActionData_t * pActionData, uint32_t unActionDataSize, VRInputValueHandle_t ulRestrictToDevice);
EVRInputError tr_ovw_GetPoseActionData(IVRInput* self, VRActionHandle_t action, ETrackingUniverseOrigin eOrigin, float fPredictedSecondsFromNow, InputPoseActionData_t * pActionData, uint32_t unActionDataSize, VRInputValueHandle_t ulRestrictToDevice);
EVRInputError tr_ovw_GetSkeletalActionData(IVRInput* self, VRActionHandle_t action, InputSkeletalActionData_t * pActionData, uint32_t unActionDataSize);
EVRInputError tr_ovw_GetBoneCount(IVRInput* self, VRActionHandle_t action, uint32_t * pBoneCount);
EVRInputError tr_ovw_GetBoneHierarchy(IVRInput* self, VRActionHandle_t action, BoneIndex_t * pParentIndices, uint32_t unIndexArayCount);
EVRInputError tr_ovw_GetBoneName(IVRInput* self, VRActionHandle_t action, BoneIndex_t nBoneIndex, char * pchBoneName, uint32_t unNameBufferSize);
EVRInputError tr_ovw_GetSkeletalReferenceTransforms(IVRInput* self, VRActionHandle_t action, EVRSkeletalTransformSpace eTransformSpace, EVRSkeletalReferencePose eReferencePose, VRBoneTransform_t * pTransformArray, uint32_t unTransformArrayCount);
EVRInputError tr_ovw_GetSkeletalTrackingLevel(IVRInput* self, VRActionHandle_t action, EVRSkeletalTrackingLevel * pSkeletalTrackingLevel);
EVRInputError tr_ovw_GetSkeletalBoneData(IVRInput* self, VRActionHandle_t action, EVRSkeletalTransformSpace eTransformSpace, EVRSkeletalMotionRange eMotionRange, VRBoneTransform_t * pTransformArray, uint32_t unTransformArrayCount);
EVRInputError tr_ovw_GetSkeletalSummaryData(IVRInput* self, VRActionHandle_t action, VRSkeletalSummaryData_t * pSkeletalSummaryData);
EVRInputError tr_ovw_GetSkeletalBoneDataCompressed(IVRInput* self, VRActionHandle_t action, EVRSkeletalMotionRange eMotionRange, void * pvCompressedData, uint32_t unCompressedSize, uint32_t * punRequiredCompressedSize);
EVRInputError tr_ovw_DecompressSkeletalBoneData(IVRInput* self, void * pvCompressedBuffer, uint32_t unCompressedBufferSize, EVRSkeletalTransformSpace eTransformSpace, VRBoneTransform_t * pTransformArray, uint32_t unTransformArrayCount);
EVRInputError tr_ovw_TriggerHapticVibrationAction(IVRInput* self, VRActionHandle_t action, float fStartSecondsFromNow, float fDurationSeconds, float fFrequency, float fAmplitude, VRInputValueHandle_t ulRestrictToDevice);
EVRInputError tr_ovw_GetActionOrigins(IVRInput* self, VRActionSetHandle_t actionSetHandle, VRActionHandle_t digitalActionHandle, VRInputValueHandle_t * originsOut, uint32_t originOutCount);
EVRInputError tr_ovw_GetOriginLocalizedName(IVRInput* self, VRInputValueHandle_t origin, char * pchNameArray, uint32_t unNameArraySize, int32_t unStringSectionsToInclude);
EVRInputError tr_ovw_GetOriginTrackedDeviceInfo(IVRInput* self, VRInputValueHandle_t origin, InputOriginInfo_t * pOriginInfo, uint32_t unOriginInfoSize);
EVRInputError tr_ovw_ShowActionOrigins(IVRInput* self, VRActionSetHandle_t actionSetHandle, VRActionHandle_t ulActionHandle);
EVRInputError tr_ovw_ShowBindingsForActionSet(IVRInput* self, VRActiveActionSet_t * pSets, uint32_t unSizeOfVRSelectedActionSet_t, uint32_t unSetCount, VRInputValueHandle_t originToHighlight);
EIOBufferError tr_ovw_Open(IVRIOBuffer* self, const char * pchPath, EIOBufferMode mode, uint32_t unElementSize, uint32_t unElements, IOBufferHandle_t * pulBuffer);
EIOBufferError tr_ovw_Close(IVRIOBuffer* self, IOBufferHandle_t ulBuffer);
EIOBufferError tr_ovw_Read(IVRIOBuffer* self, IOBufferHandle_t ulBuffer, void * pDst, uint32_t unBytes, uint32_t * punRead);
EIOBufferError tr_ovw_Write(IVRIOBuffer* self, IOBufferHandle_t ulBuffer, void * pSrc, uint32_t unBytes);
PropertyContainerHandle_t tr_ovw_PropertyContainer(IVRIOBuffer* self, IOBufferHandle_t ulBuffer);
bool tr_ovw_HasReaders(IVRIOBuffer* self, IOBufferHandle_t ulBuffer);
EVRSpatialAnchorError tr_ovw_CreateSpatialAnchorFromDescriptor(IVRSpatialAnchors* self, const char * pchDescriptor, SpatialAnchorHandle_t * pHandleOut);
EVRSpatialAnchorError tr_ovw_CreateSpatialAnchorFromPose(IVRSpatialAnchors* self, TrackedDeviceIndex_t unDeviceIndex, ETrackingUniverseOrigin eOrigin, SpatialAnchorPose_t * pPose, SpatialAnchorHandle_t * pHandleOut);
EVRSpatialAnchorError tr_ovw_GetSpatialAnchorPose(IVRSpatialAnchors* self, SpatialAnchorHandle_t unHandle, ETrackingUniverseOrigin eOrigin, SpatialAnchorPose_t * pPoseOut);
EVRSpatialAnchorError tr_ovw_GetSpatialAnchorDescriptor(IVRSpatialAnchors* self, SpatialAnchorHandle_t unHandle, char * pchDescriptorOut, uint32_t * punDescriptorBufferLenInOut);