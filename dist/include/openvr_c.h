// Mostly auto generated c api to openvr 0.9.20

#include <stdint.h>

#if defined( __WIN32 )
typedef char bool;
#endif


// OpenVR Constants

static const unsigned int k_unTrackingStringSize = 32;
static const unsigned int k_unMaxDriverDebugResponseSize = 32768;
static const unsigned int k_unTrackedDeviceIndex_Hmd = 0;
static const unsigned int k_unMaxTrackedDeviceCount = 16;
static const unsigned int k_unTrackedDeviceIndexInvalid = 4294967295;
static const unsigned int k_unMaxPropertyStringSize = 32768;
static const unsigned int k_unControllerStateAxisCount = 5;
static const unsigned long k_ulOverlayHandleInvalid = 0;
static const char * IVRSystem_Version = "IVRSystem_012";
static const char * IVRExtendedDisplay_Version = "IVRExtendedDisplay_001";
static const unsigned int k_unMaxApplicationKeyLength = 128;
static const char * IVRApplications_Version = "IVRApplications_005";
static const char * IVRChaperone_Version = "IVRChaperone_003";
static const char * IVRChaperoneSetup_Version = "IVRChaperoneSetup_005";
static const char * IVRCompositor_Version = "IVRCompositor_014";
static const unsigned int k_unVROverlayMaxKeyLength = 128;
static const unsigned int k_unVROverlayMaxNameLength = 128;
static const unsigned int k_unMaxOverlayCount = 32;
static const char * IVROverlay_Version = "IVROverlay_011";
static const char * k_pch_Controller_Component_GDC2015 = "gdc2015";
static const char * k_pch_Controller_Component_Base = "base";
static const char * k_pch_Controller_Component_Tip = "tip";
static const char * k_pch_Controller_Component_HandGrip = "handgrip";
static const char * k_pch_Controller_Component_Status = "status";
static const char * IVRRenderModels_Version = "IVRRenderModels_005";
static const unsigned int k_unNotificationTextMaxSize = 256;
static const char * IVRNotifications_Version = "IVRNotifications_002";
static const unsigned int k_unMaxSettingsKeyLength = 128;
static const char * IVRSettings_Version = "IVRSettings_001";
static const char * k_pch_SteamVR_Section = "steamvr";
static const char * k_pch_SteamVR_RequireHmd_String = "requireHmd";
static const char * k_pch_SteamVR_ForcedDriverKey_String = "forcedDriver";
static const char * k_pch_SteamVR_ForcedHmdKey_String = "forcedHmd";
static const char * k_pch_SteamVR_DisplayDebug_Bool = "displayDebug";
static const char * k_pch_SteamVR_DebugProcessPipe_String = "debugProcessPipe";
static const char * k_pch_SteamVR_EnableDistortion_Bool = "enableDistortion";
static const char * k_pch_SteamVR_DisplayDebugX_Int32 = "displayDebugX";
static const char * k_pch_SteamVR_DisplayDebugY_Int32 = "displayDebugY";
static const char * k_pch_SteamVR_SendSystemButtonToAllApps_Bool = "sendSystemButtonToAllApps";
static const char * k_pch_SteamVR_LogLevel_Int32 = "loglevel";
static const char * k_pch_SteamVR_IPD_Float = "ipd";
static const char * k_pch_SteamVR_Background_String = "background";
static const char * k_pch_SteamVR_GridColor_String = "gridColor";
static const char * k_pch_SteamVR_PlayAreaColor_String = "playAreaColor";
static const char * k_pch_SteamVR_ActivateMultipleDrivers_Bool = "activateMultipleDrivers";
static const char * k_pch_SteamVR_PowerOffOnExit_Bool = "powerOffOnExit";
static const char * k_pch_SteamVR_StandbyAppRunningTimeout_Float = "standbyAppRunningTimeout";
static const char * k_pch_SteamVR_StandbyNoAppTimeout_Float = "standbyNoAppTimeout";
static const char * k_pch_SteamVR_DirectMode_Bool = "directMode";
static const char * k_pch_SteamVR_DirectModeEdidVid_Int32 = "directModeEdidVid";
static const char * k_pch_SteamVR_DirectModeEdidPid_Int32 = "directModeEdidPid";
static const char * k_pch_SteamVR_UsingSpeakers_Bool = "usingSpeakers";
static const char * k_pch_SteamVR_SpeakersForwardYawOffsetDegrees_Float = "speakersForwardYawOffsetDegrees";
static const char * k_pch_SteamVR_BaseStationPowerManagement_Bool = "basestationPowerManagement";
static const char * k_pch_SteamVR_NeverKillProcesses_Bool = "neverKillProcesses";
static const char * k_pch_SteamVR_RenderTargetMultiplier_Float = "renderTargetMultiplier";
static const char * k_pch_SteamVR_AllowReprojection_Bool = "allowReprojection";
static const char * k_pch_Lighthouse_Section = "driver_lighthouse";
static const char * k_pch_Lighthouse_DisableIMU_Bool = "disableimu";
static const char * k_pch_Lighthouse_UseDisambiguation_String = "usedisambiguation";
static const char * k_pch_Lighthouse_DisambiguationDebug_Int32 = "disambiguationdebug";
static const char * k_pch_Lighthouse_PrimaryBasestation_Int32 = "primarybasestation";
static const char * k_pch_Lighthouse_LighthouseName_String = "lighthousename";
static const char * k_pch_Lighthouse_MaxIncidenceAngleDegrees_Float = "maxincidenceangledegrees";
static const char * k_pch_Lighthouse_UseLighthouseDirect_Bool = "uselighthousedirect";
static const char * k_pch_Lighthouse_DBHistory_Bool = "dbhistory";
static const char * k_pch_Lighthouse_OriginOffsetX_Float = "originoffsetx";
static const char * k_pch_Lighthouse_OriginOffsetY_Float = "originoffsety";
static const char * k_pch_Lighthouse_OriginOffsetZ_Float = "originoffsetz";
static const char * k_pch_Lighthouse_HeadingOffset_Float = "headingoffset";
static const char * k_pch_Null_Section = "driver_null";
static const char * k_pch_Null_EnableNullDriver_Bool = "enable";
static const char * k_pch_Null_SerialNumber_String = "serialNumber";
static const char * k_pch_Null_ModelNumber_String = "modelNumber";
static const char * k_pch_Null_WindowX_Int32 = "windowX";
static const char * k_pch_Null_WindowY_Int32 = "windowY";
static const char * k_pch_Null_WindowWidth_Int32 = "windowWidth";
static const char * k_pch_Null_WindowHeight_Int32 = "windowHeight";
static const char * k_pch_Null_RenderWidth_Int32 = "renderWidth";
static const char * k_pch_Null_RenderHeight_Int32 = "renderHeight";
static const char * k_pch_Null_SecondsFromVsyncToPhotons_Float = "secondsFromVsyncToPhotons";
static const char * k_pch_Null_DisplayFrequency_Float = "displayFrequency";
static const char * k_pch_UserInterface_Section = "userinterface";
static const char * k_pch_UserInterface_StatusAlwaysOnTop_Bool = "StatusAlwaysOnTop";
static const char * k_pch_Notifications_Section = "notifications";
static const char * k_pch_Notifications_DoNotDisturb_Bool = "DoNotDisturb";
static const char * k_pch_Keyboard_Section = "keyboard";
static const char * k_pch_Keyboard_TutorialCompletions = "TutorialCompletions";
static const char * k_pch_Keyboard_ScaleX = "ScaleX";
static const char * k_pch_Keyboard_ScaleY = "ScaleY";
static const char * k_pch_Keyboard_OffsetLeftX = "OffsetLeftX";
static const char * k_pch_Keyboard_OffsetRightX = "OffsetRightX";
static const char * k_pch_Keyboard_OffsetY = "OffsetY";
static const char * k_pch_Keyboard_Smoothing = "Smoothing";
static const char * k_pch_Perf_Section = "perfcheck";
static const char * k_pch_Perf_HeuristicActive_Bool = "heuristicActive";
static const char * k_pch_Perf_NotifyInHMD_Bool = "warnInHMD";
static const char * k_pch_Perf_NotifyOnlyOnce_Bool = "warnOnlyOnce";
static const char * k_pch_Perf_AllowTimingStore_Bool = "allowTimingStore";
static const char * k_pch_Perf_SaveTimingsOnExit_Bool = "saveTimingsOnExit";
static const char * k_pch_Perf_TestData_Float = "perfTestData";
static const char * k_pch_CollisionBounds_Section = "collisionBounds";
static const char * k_pch_CollisionBounds_Style_Int32 = "CollisionBoundsStyle";
static const char * k_pch_CollisionBounds_GroundPerimeterOn_Bool = "CollisionBoundsGroundPerimeterOn";
static const char * k_pch_CollisionBounds_CenterMarkerOn_Bool = "CollisionBoundsCenterMarkerOn";
static const char * k_pch_CollisionBounds_PlaySpaceOn_Bool = "CollisionBoundsPlaySpaceOn";
static const char * k_pch_CollisionBounds_FadeDistance_Float = "CollisionBoundsFadeDistance";
static const char * k_pch_CollisionBounds_ColorGammaR_Int32 = "CollisionBoundsColorGammaR";
static const char * k_pch_CollisionBounds_ColorGammaG_Int32 = "CollisionBoundsColorGammaG";
static const char * k_pch_CollisionBounds_ColorGammaB_Int32 = "CollisionBoundsColorGammaB";
static const char * k_pch_CollisionBounds_ColorGammaA_Int32 = "CollisionBoundsColorGammaA";
static const char * k_pch_Camera_Section = "camera";
static const char * k_pch_Camera_EnableCamera_Bool = "enableCamera";
static const char * k_pch_Camera_EnableCameraInDashboard_Bool = "enableCameraInDashboard";
static const char * k_pch_Camera_EnableCameraForCollisionBounds_Bool = "enableCameraForCollisionBounds";
static const char * k_pch_Camera_EnableCameraForRoomView_Bool = "enableCameraForRoomView";
static const char * k_pch_Camera_BoundsColorGammaR_Int32 = "cameraBoundsColorGammaR";
static const char * k_pch_Camera_BoundsColorGammaG_Int32 = "cameraBoundsColorGammaG";
static const char * k_pch_Camera_BoundsColorGammaB_Int32 = "cameraBoundsColorGammaB";
static const char * k_pch_Camera_BoundsColorGammaA_Int32 = "cameraBoundsColorGammaA";
static const char * k_pch_audio_Section = "audio";
static const char * k_pch_audio_OnPlaybackDevice_String = "onPlaybackDevice";
static const char * k_pch_audio_OnRecordDevice_String = "onRecordDevice";
static const char * k_pch_audio_OnPlaybackMirrorDevice_String = "onPlaybackMirrorDevice";
static const char * k_pch_audio_OffPlaybackDevice_String = "offPlaybackDevice";
static const char * k_pch_audio_OffRecordDevice_String = "offRecordDevice";
static const char * k_pch_audio_VIVEHDMIGain = "viveHDMIGain";

// OpenVR Enums

typedef enum EVREye
{
	EVREye_Eye_Left = 0,
	EVREye_Eye_Right = 1,
} EVREye;

typedef enum EGraphicsAPIConvention
{
	EGraphicsAPIConvention_API_DirectX = 0,
	EGraphicsAPIConvention_API_OpenGL = 1,
} EGraphicsAPIConvention;

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
} ETrackingResult;

typedef enum ETrackedDeviceClass
{
	ETrackedDeviceClass_TrackedDeviceClass_Invalid = 0,
	ETrackedDeviceClass_TrackedDeviceClass_HMD = 1,
	ETrackedDeviceClass_TrackedDeviceClass_Controller = 2,
	ETrackedDeviceClass_TrackedDeviceClass_TrackingReference = 4,
	ETrackedDeviceClass_TrackedDeviceClass_Other = 1000,
} ETrackedDeviceClass;

typedef enum ETrackedControllerRole
{
	ETrackedControllerRole_TrackedControllerRole_Invalid = 0,
	ETrackedControllerRole_TrackedControllerRole_LeftHand = 1,
	ETrackedControllerRole_TrackedControllerRole_RightHand = 2,
} ETrackedControllerRole;

typedef enum ETrackingUniverseOrigin
{
	ETrackingUniverseOrigin_TrackingUniverseSeated = 0,
	ETrackingUniverseOrigin_TrackingUniverseStanding = 1,
	ETrackingUniverseOrigin_TrackingUniverseRawAndUncalibrated = 2,
} ETrackingUniverseOrigin;

typedef enum ETrackedDeviceProperty
{
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
	ETrackedDeviceProperty_Prop_AttachedDeviceId_String = 3000,
	ETrackedDeviceProperty_Prop_SupportedButtons_Uint64 = 3001,
	ETrackedDeviceProperty_Prop_Axis0Type_Int32 = 3002,
	ETrackedDeviceProperty_Prop_Axis1Type_Int32 = 3003,
	ETrackedDeviceProperty_Prop_Axis2Type_Int32 = 3004,
	ETrackedDeviceProperty_Prop_Axis3Type_Int32 = 3005,
	ETrackedDeviceProperty_Prop_Axis4Type_Int32 = 3006,
	ETrackedDeviceProperty_Prop_FieldOfViewLeftDegrees_Float = 4000,
	ETrackedDeviceProperty_Prop_FieldOfViewRightDegrees_Float = 4001,
	ETrackedDeviceProperty_Prop_FieldOfViewTopDegrees_Float = 4002,
	ETrackedDeviceProperty_Prop_FieldOfViewBottomDegrees_Float = 4003,
	ETrackedDeviceProperty_Prop_TrackingRangeMinimumMeters_Float = 4004,
	ETrackedDeviceProperty_Prop_TrackingRangeMaximumMeters_Float = 4005,
	ETrackedDeviceProperty_Prop_ModeLabel_String = 4006,
	ETrackedDeviceProperty_Prop_VendorSpecific_Reserved_Start = 10000,
	ETrackedDeviceProperty_Prop_VendorSpecific_Reserved_End = 10999,
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
} ETrackedPropertyError;

typedef enum EVRSubmitFlags
{
	EVRSubmitFlags_Submit_Default = 0,
	EVRSubmitFlags_Submit_LensDistortionAlreadyApplied = 1,
	EVRSubmitFlags_Submit_GlRenderBuffer = 2,
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
	EVREventType_VREvent_ButtonPress = 200,
	EVREventType_VREvent_ButtonUnpress = 201,
	EVREventType_VREvent_ButtonTouch = 202,
	EVREventType_VREvent_ButtonUntouch = 203,
	EVREventType_VREvent_MouseMove = 300,
	EVREventType_VREvent_MouseButtonDown = 301,
	EVREventType_VREvent_MouseButtonUp = 302,
	EVREventType_VREvent_FocusEnter = 303,
	EVREventType_VREvent_FocusLeave = 304,
	EVREventType_VREvent_Scroll = 305,
	EVREventType_VREvent_TouchPadMove = 306,
	EVREventType_VREvent_InputFocusCaptured = 400,
	EVREventType_VREvent_InputFocusReleased = 401,
	EVREventType_VREvent_SceneFocusLost = 402,
	EVREventType_VREvent_SceneFocusGained = 403,
	EVREventType_VREvent_SceneApplicationChanged = 404,
	EVREventType_VREvent_SceneFocusChanged = 405,
	EVREventType_VREvent_InputFocusChanged = 406,
	EVREventType_VREvent_HideRenderModels = 410,
	EVREventType_VREvent_ShowRenderModels = 411,
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
	EVREventType_VREvent_DashboardGuideButtonDown = 514,
	EVREventType_VREvent_DashboardGuideButtonUp = 515,
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
	EVREventType_VREvent_AudioSettingsHaveChanged = 820,
	EVREventType_VREvent_BackgroundSettingHasChanged = 850,
	EVREventType_VREvent_CameraSettingsHaveChanged = 851,
	EVREventType_VREvent_ReprojectionSettingHasChanged = 852,
	EVREventType_VREvent_StatusUpdate = 900,
	EVREventType_VREvent_MCImageUpdated = 1000,
	EVREventType_VREvent_FirmwareUpdateStarted = 1100,
	EVREventType_VREvent_FirmwareUpdateFinished = 1101,
	EVREventType_VREvent_KeyboardClosed = 1200,
	EVREventType_VREvent_KeyboardCharInput = 1201,
	EVREventType_VREvent_KeyboardDone = 1202,
	EVREventType_VREvent_ApplicationTransitionStarted = 1300,
	EVREventType_VREvent_ApplicationTransitionAborted = 1301,
	EVREventType_VREvent_ApplicationTransitionNewAppStarted = 1302,
	EVREventType_VREvent_Compositor_MirrorWindowShown = 1400,
	EVREventType_VREvent_Compositor_MirrorWindowHidden = 1401,
	EVREventType_VREvent_Compositor_ChaperoneBoundsShown = 1410,
	EVREventType_VREvent_Compositor_ChaperoneBoundsHidden = 1411,
	EVREventType_VREvent_TrackedCamera_StartVideoStream = 1500,
	EVREventType_VREvent_TrackedCamera_StopVideoStream = 1501,
	EVREventType_VREvent_TrackedCamera_PauseVideoStream = 1502,
	EVREventType_VREvent_TrackedCamera_ResumeVideoStream = 1503,
	EVREventType_VREvent_PerformanceTest_EnableCapture = 1600,
	EVREventType_VREvent_PerformanceTest_DisableCapture = 1601,
	EVREventType_VREvent_PerformanceTest_FidelityLevel = 1602,
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
	EVRButtonId_k_EButton_Axis0 = 32,
	EVRButtonId_k_EButton_Axis1 = 33,
	EVRButtonId_k_EButton_Axis2 = 34,
	EVRButtonId_k_EButton_Axis3 = 35,
	EVRButtonId_k_EButton_Axis4 = 36,
	EVRButtonId_k_EButton_SteamVR_Touchpad = 32,
	EVRButtonId_k_EButton_SteamVR_Trigger = 33,
	EVRButtonId_k_EButton_Dashboard_Back = 2,
	EVRButtonId_k_EButton_Max = 64,
} EVRButtonId;

typedef enum EVRMouseButton
{
	EVRMouseButton_VRMouseButton_Left = 1,
	EVRMouseButton_VRMouseButton_Right = 2,
	EVRMouseButton_VRMouseButton_Middle = 4,
} EVRMouseButton;

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
	EVROverlayError_VROVerlayError_KeyboardAlreadyInUse = 26,
	EVROverlayError_VROverlayError_NoNeighbor = 27,
} EVROverlayError;

typedef enum EVRApplicationType
{
	EVRApplicationType_VRApplication_Other = 0,
	EVRApplicationType_VRApplication_Scene = 1,
	EVRApplicationType_VRApplication_Overlay = 2,
	EVRApplicationType_VRApplication_Background = 3,
	EVRApplicationType_VRApplication_Utility = 4,
	EVRApplicationType_VRApplication_VRMonitor = 5,
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
} EVRNotificationError;

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
	EVRInitError_VRInitError_Driver_Failed = 200,
	EVRInitError_VRInitError_Driver_Unknown = 201,
	EVRInitError_VRInitError_Driver_HmdUnknown = 202,
	EVRInitError_VRInitError_Driver_NotLoaded = 203,
	EVRInitError_VRInitError_Driver_RuntimeOutOfDate = 204,
	EVRInitError_VRInitError_Driver_HmdInUse = 205,
	EVRInitError_VRInitError_Driver_NotCalibrated = 206,
	EVRInitError_VRInitError_Driver_CalibrationInvalid = 207,
	EVRInitError_VRInitError_Driver_HmdDisplayNotFound = 208,
	EVRInitError_VRInitError_IPC_ServerInitFailed = 300,
	EVRInitError_VRInitError_IPC_ConnectFailed = 301,
	EVRInitError_VRInitError_IPC_SharedStateInitFailed = 302,
	EVRInitError_VRInitError_IPC_CompositorInitFailed = 303,
	EVRInitError_VRInitError_IPC_MutexInitFailed = 304,
	EVRInitError_VRInitError_IPC_Failed = 305,
	EVRInitError_VRInitError_Compositor_Failed = 400,
	EVRInitError_VRInitError_Compositor_D3D11HardwareRequired = 401,
	EVRInitError_VRInitError_Compositor_FirmwareRequiresUpdate = 402,
	EVRInitError_VRInitError_VendorSpecific_UnableToConnectToOculusRuntime = 1000,
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
	EVRApplicationProperty_VRApplicationProperty_IsDashboardOverlay_Bool = 60,
	EVRApplicationProperty_VRApplicationProperty_IsTemplate_Bool = 61,
	EVRApplicationProperty_VRApplicationProperty_IsInstanced_Bool = 62,
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
	ChaperoneCalibrationState_Error_BaseStationUninitalized = 201,
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
	EVRCompositorError_VRCompositorError_IncompatibleVersion = 100,
	EVRCompositorError_VRCompositorError_DoNotHaveFocus = 101,
	EVRCompositorError_VRCompositorError_InvalidTexture = 102,
	EVRCompositorError_VRCompositorError_IsNotSceneApplication = 103,
	EVRCompositorError_VRCompositorError_TextureIsOnWrongDevice = 104,
	EVRCompositorError_VRCompositorError_TextureUsesUnsupportedFormat = 105,
	EVRCompositorError_VRCompositorError_SharedTexturesNotSupported = 106,
	EVRCompositorError_VRCompositorError_IndexOutOfRange = 107,
} EVRCompositorError;

typedef enum VROverlayInputMethod
{
	VROverlayInputMethod_None = 0,
	VROverlayInputMethod_Mouse = 1,
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
	VROverlayFlags_SendVRScrollEvents = 6,
	VROverlayFlags_SendVRTouchpadEvents = 7,
	VROverlayFlags_ShowTouchPadScrollWheel = 8,
	VROverlayFlags_TransferOwnershipToInternalProcess = 9,
} VROverlayFlags;

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

typedef enum EVRRenderModelError
{
	EVRRenderModelError_VRRenderModelError_None = 0,
	EVRRenderModelError_VRRenderModelError_Loading = 100,
	EVRRenderModelError_VRRenderModelError_NotSupported = 200,
	EVRRenderModelError_VRRenderModelError_InvalidArg = 300,
	EVRRenderModelError_VRRenderModelError_InvalidModel = 301,
	EVRRenderModelError_VRRenderModelError_NoShapes = 302,
	EVRRenderModelError_VRRenderModelError_MultipleShapes = 303,
	EVRRenderModelError_VRRenderModelError_TooManyIndices = 304,
	EVRRenderModelError_VRRenderModelError_MultipleTextures = 305,
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
} EVRSettingsError;


// OpenVR typedefs

typedef uint32_t TrackedDeviceIndex_t;
typedef uint32_t VRNotificationId;
typedef uint64_t VROverlayHandle_t;
typedef void * glSharedTextureHandle_t;
typedef int32_t glInt_t;
typedef uint32_t glUInt_t;
typedef uint32_t TrackedDeviceIndex_t;
typedef uint64_t VROverlayHandle_t;
typedef uint32_t VRComponentProperties;
typedef int32_t TextureID_t;
typedef uint32_t VRNotificationId;
typedef EVRInitError HmdError;
typedef EVREye Hmd_Eye;
typedef EGraphicsAPIConvention GraphicsAPIConvention;
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

// OpenVR Structs

typedef struct HmdMatrix34_t
{
	float m[3][4]; //float[3][4]
} HmdMatrix34_t;

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
	enum EGraphicsAPIConvention eType;
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
} VREvent_Process_t;

typedef struct VREvent_Overlay_t
{
	uint64_t overlayHandle;
} VREvent_Overlay_t;

typedef struct VREvent_Status_t
{
	uint32_t statusState;
} VREvent_Status_t;

typedef struct VREvent_Keyboard_t
{
	char * cNewInput[8]; //char[8]
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
} VREvent_Reserved_t;

typedef struct VREvent_PerformanceTest_t
{
	uint32_t m_nFidelityLevel;
} VREvent_PerformanceTest_t;

typedef struct VREvent_SeatedZeroPoseReset_t
{
	bool bResetBySystemMenu;
} VREvent_SeatedZeroPoseReset_t;

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
	uint32_t m_nNumDroppedFrames;
	double m_flSystemTimeInSeconds;
	float m_flSceneRenderGpuMs;
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
	int32_t m_nFidelityLevel;
	uint32_t m_nReprojectionFlags;
} Compositor_FrameTiming;

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
	void * bytes; // void *
	int32_t width;
	int32_t height;
	int32_t depth;
} NotificationBitmap_t;

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
} VREvent_Data_t;

/** An event posted by the server to all running applications */
struct VREvent_t
{
	uint32_t eventType; // EVREventType enum
	TrackedDeviceIndex_t trackedDeviceIndex;
	float eventAgeSeconds;
	// event data must be the end of the struct as its size is variable
	VREvent_Data_t data;
};

typedef struct IVRSystem IVRSystem;
typedef struct IVRChaperone IVRChaperone;
typedef struct IVROverlay IVROverlay;
typedef struct IVRApplications IVRApplications;
typedef struct IVRCompositor IVRCompositor;
typedef struct IVRExtendedDisplay IVRExtendedDisplay;
typedef struct IVRSettings IVRSettings;
typedef struct IVRRenderModels IVRRenderModels;

void tr_ovw_GetRecommendedRenderTargetSize(IVRSystem* self, uint32_t * pnWidth, uint32_t * pnHeight);
HmdMatrix44_t tr_ovw_GetProjectionMatrix(IVRSystem* self, EVREye eEye, float fNearZ, float fFarZ, EGraphicsAPIConvention eProjType);
void tr_ovw_GetProjectionRaw(IVRSystem* self, EVREye eEye, float * pfLeft, float * pfRight, float * pfTop, float * pfBottom);
DistortionCoordinates_t tr_ovw_ComputeDistortion(IVRSystem* self, EVREye eEye, float fU, float fV);
HmdMatrix34_t tr_ovw_GetEyeToHeadTransform(IVRSystem* self, EVREye eEye);
bool tr_ovw_GetTimeSinceLastVsync(IVRSystem* self, float * pfSecondsSinceLastVsync, uint64_t * pulFrameCounter);
int32_t tr_ovw_GetD3D9AdapterIndex(IVRSystem* self);
void tr_ovw_GetDXGIOutputInfo(IVRSystem* self, int32_t * pnAdapterIndex);
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
uint32_t tr_ovw_GetStringTrackedDeviceProperty(IVRSystem* self, TrackedDeviceIndex_t unDeviceIndex, ETrackedDeviceProperty prop, char * pchValue, uint32_t unBufferSize, ETrackedPropertyError * pError);
const char * tr_ovw_GetPropErrorNameFromEnum(IVRSystem* self, ETrackedPropertyError error);
bool tr_ovw_PollNextEvent(IVRSystem* self, VREvent_t * pEvent, uint32_t uncbVREvent);
bool tr_ovw_PollNextEventWithPose(IVRSystem* self, ETrackingUniverseOrigin eOrigin, VREvent_t * pEvent, uint32_t uncbVREvent, TrackedDevicePose_t * pTrackedDevicePose);
const char * tr_ovw_GetEventTypeNameFromEnum(IVRSystem* self, EVREventType eType);
HiddenAreaMesh_t tr_ovw_GetHiddenAreaMesh(IVRSystem* self, EVREye eEye);
bool tr_ovw_GetControllerState(IVRSystem* self, TrackedDeviceIndex_t unControllerDeviceIndex, VRControllerState_t * pControllerState);
bool tr_ovw_GetControllerStateWithPose(IVRSystem* self, ETrackingUniverseOrigin eOrigin, TrackedDeviceIndex_t unControllerDeviceIndex, VRControllerState_t * pControllerState, TrackedDevicePose_t * pTrackedDevicePose);
void tr_ovw_TriggerHapticPulse(IVRSystem* self, TrackedDeviceIndex_t unControllerDeviceIndex, uint32_t unAxisId, unsigned short usDurationMicroSec);
const char * tr_ovw_GetButtonIdNameFromEnum(IVRSystem* self, EVRButtonId eButtonId);
const char * tr_ovw_GetControllerAxisTypeNameFromEnum(IVRSystem* self, EVRControllerAxisType eAxisType);
bool tr_ovw_CaptureInputFocus(IVRSystem* self);
void tr_ovw_ReleaseInputFocus(IVRSystem* self);
bool tr_ovw_IsInputFocusCapturedByAnotherProcess(IVRSystem* self);
uint32_t tr_ovw_DriverDebugRequest(IVRSystem* self, TrackedDeviceIndex_t unDeviceIndex, char * pchRequest, char * pchResponseBuffer, uint32_t unResponseBufferSize);
EVRFirmwareError tr_ovw_PerformFirmwareUpdate(IVRSystem* self, TrackedDeviceIndex_t unDeviceIndex);
void tr_ovw_AcknowledgeQuit_Exiting(IVRSystem* self);
void tr_ovw_AcknowledgeQuit_UserPrompt(IVRSystem* self);
void tr_ovw_GetWindowBounds(IVRExtendedDisplay* self, int32_t * pnX, int32_t * pnY, uint32_t * pnWidth, uint32_t * pnHeight);
void tr_ovw_GetEyeOutputViewport(IVRExtendedDisplay* self, EVREye eEye, uint32_t * pnX, uint32_t * pnY, uint32_t * pnWidth, uint32_t * pnHeight);
//void tr_ovw_GetDXGIOutputInfo(IVRExtendedDisplay* self, int32_t * pnAdapterIndex, int32_t * pnAdapterOutputIndex);
EVRApplicationError tr_ovw_AddApplicationManifest(IVRApplications* self, char * pchApplicationManifestFullPath, bool bTemporary);
EVRApplicationError tr_ovw_RemoveApplicationManifest(IVRApplications* self, char * pchApplicationManifestFullPath);
bool tr_ovw_IsApplicationInstalled(IVRApplications* self, char * pchAppKey);
uint32_t tr_ovw_GetApplicationCount(IVRApplications* self);
EVRApplicationError tr_ovw_GetApplicationKeyByIndex(IVRApplications* self, uint32_t unApplicationIndex, char * pchAppKeyBuffer, uint32_t unAppKeyBufferLen);
EVRApplicationError tr_ovw_GetApplicationKeyByProcessId(IVRApplications* self, uint32_t unProcessId, char * pchAppKeyBuffer, uint32_t unAppKeyBufferLen);
EVRApplicationError tr_ovw_LaunchApplication(IVRApplications* self, char * pchAppKey);
EVRApplicationError tr_ovw_LaunchTemplateApplication(IVRApplications* self, char * pchTemplateAppKey, char * pchNewAppKey, AppOverrideKeys_t * pKeys, uint32_t unKeys);
EVRApplicationError tr_ovw_LaunchDashboardOverlay(IVRApplications* self, char * pchAppKey);
bool tr_ovw_CancelApplicationLaunch(IVRApplications* self, char * pchAppKey);
EVRApplicationError tr_ovw_IdentifyApplication(IVRApplications* self, uint32_t unProcessId, char * pchAppKey);
uint32_t tr_ovw_GetApplicationProcessId(IVRApplications* self, char * pchAppKey);
const char * tr_ovw_GetApplicationsErrorNameFromEnum(IVRApplications* self, EVRApplicationError error);
uint32_t tr_ovw_GetApplicationPropertyString(IVRApplications* self, char * pchAppKey, EVRApplicationProperty eProperty, char * pchPropertyValueBuffer, uint32_t unPropertyValueBufferLen, EVRApplicationError * peError);
bool tr_ovw_GetApplicationPropertyBool(IVRApplications* self, char * pchAppKey, EVRApplicationProperty eProperty, EVRApplicationError * peError);
uint64_t tr_ovw_GetApplicationPropertyUint64(IVRApplications* self, char * pchAppKey, EVRApplicationProperty eProperty, EVRApplicationError * peError);
EVRApplicationError tr_ovw_SetApplicationAutoLaunch(IVRApplications* self, char * pchAppKey, bool bAutoLaunch);
bool tr_ovw_GetApplicationAutoLaunch(IVRApplications* self, char * pchAppKey);
EVRApplicationError tr_ovw_GetStartingApplication(IVRApplications* self, char * pchAppKeyBuffer, uint32_t unAppKeyBufferLen);
EVRApplicationTransitionState tr_ovw_GetTransitionState(IVRApplications* self);
EVRApplicationError tr_ovw_PerformApplicationPrelaunchCheck(IVRApplications* self, char * pchAppKey);
const char * tr_ovw_GetApplicationsTransitionStateNameFromEnum(IVRApplications* self, EVRApplicationTransitionState state);
bool tr_ovw_IsQuitUserPromptRequested(IVRApplications* self);
EVRApplicationError tr_ovw_LaunchInternalProcess(IVRApplications* self, char * pchBinaryPath, char * pchArguments, char * pchWorkingDirectory);
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
void tr_ovw_SetWorkingSeatedZeroPoseToRawTrackingPose(IVRChaperoneSetup* self, HmdMatrix34_t * pMatSeatedZeroPoseToRawTrackingPose);
void tr_ovw_SetWorkingStandingZeroPoseToRawTrackingPose(IVRChaperoneSetup* self, HmdMatrix34_t * pMatStandingZeroPoseToRawTrackingPose);
void tr_ovw_ReloadFromDisk(IVRChaperoneSetup* self, EChaperoneConfigFile configFile);
bool tr_ovw_GetLiveSeatedZeroPoseToRawTrackingPose(IVRChaperoneSetup* self, HmdMatrix34_t * pmatSeatedZeroPoseToRawTrackingPose);
void tr_ovw_SetWorkingCollisionBoundsTagsInfo(IVRChaperoneSetup* self, uint8_t * pTagsBuffer, uint32_t unTagCount);
bool tr_ovw_GetLiveCollisionBoundsTagsInfo(IVRChaperoneSetup* self, uint8_t * pTagsBuffer, uint32_t * punTagCount);
bool tr_ovw_SetWorkingPhysicalBoundsInfo(IVRChaperoneSetup* self, HmdQuad_t * pQuadsBuffer, uint32_t unQuadsCount);
bool tr_ovw_GetLivePhysicalBoundsInfo(IVRChaperoneSetup* self, HmdQuad_t * pQuadsBuffer, uint32_t * punQuadsCount);
bool tr_ovw_ExportLiveToBuffer(IVRChaperoneSetup* self, char * pBuffer, uint32_t * pnBufferLength);
bool tr_ovw_ImportFromBufferToWorking(IVRChaperoneSetup* self, char * pBuffer, uint32_t nImportFlags);
void tr_ovw_SetTrackingSpace(IVRCompositor* self, ETrackingUniverseOrigin eOrigin);
ETrackingUniverseOrigin tr_ovw_GetTrackingSpace(IVRCompositor* self);
EVRCompositorError tr_ovw_WaitGetPoses(IVRCompositor* self, TrackedDevicePose_t * pRenderPoseArray, uint32_t unRenderPoseArrayCount, TrackedDevicePose_t * pGamePoseArray, uint32_t unGamePoseArrayCount);
EVRCompositorError tr_ovw_GetLastPoses(IVRCompositor* self, TrackedDevicePose_t * pRenderPoseArray, uint32_t unRenderPoseArrayCount, TrackedDevicePose_t * pGamePoseArray, uint32_t unGamePoseArrayCount);
EVRCompositorError tr_ovw_GetLastPoseForTrackedDeviceIndex(IVRCompositor* self, TrackedDeviceIndex_t unDeviceIndex, TrackedDevicePose_t * pOutputPose, TrackedDevicePose_t * pOutputGamePose);
EVRCompositorError tr_ovw_Submit(IVRCompositor* self, EVREye eEye, Texture_t * pTexture, VRTextureBounds_t * pBounds, EVRSubmitFlags nSubmitFlags);
void tr_ovw_ClearLastSubmittedFrame(IVRCompositor* self);
void tr_ovw_PostPresentHandoff(IVRCompositor* self);
bool tr_ovw_GetFrameTiming(IVRCompositor* self, Compositor_FrameTiming * pTiming, uint32_t unFramesAgo);
float tr_ovw_GetFrameTimeRemaining(IVRCompositor* self);
void tr_ovw_FadeToColor(IVRCompositor* self, float fSeconds, float fRed, float fGreen, float fBlue, float fAlpha, bool bBackground);
void tr_ovw_FadeGrid(IVRCompositor* self, float fSeconds, bool bFadeIn);
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
EVROverlayError tr_ovw_FindOverlay(IVROverlay* self, char * pchOverlayKey, VROverlayHandle_t * pOverlayHandle);
EVROverlayError tr_ovw_CreateOverlay(IVROverlay* self, char * pchOverlayKey, char * pchOverlayFriendlyName, VROverlayHandle_t * pOverlayHandle);
EVROverlayError tr_ovw_DestroyOverlay(IVROverlay* self, VROverlayHandle_t ulOverlayHandle);
EVROverlayError tr_ovw_SetHighQualityOverlay(IVROverlay* self, VROverlayHandle_t ulOverlayHandle);
VROverlayHandle_t tr_ovw_GetHighQualityOverlay(IVROverlay* self);
uint32_t tr_ovw_GetOverlayKey(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, char * pchValue, uint32_t unBufferSize, EVROverlayError * pError);
uint32_t tr_ovw_GetOverlayName(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, char * pchValue, uint32_t unBufferSize, EVROverlayError * pError);
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
EVROverlayError tr_ovw_SetOverlayWidthInMeters(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, float fWidthInMeters);
EVROverlayError tr_ovw_GetOverlayWidthInMeters(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, float * pfWidthInMeters);
EVROverlayError tr_ovw_SetOverlayAutoCurveDistanceRangeInMeters(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, float fMinDistanceInMeters, float fMaxDistanceInMeters);
EVROverlayError tr_ovw_GetOverlayAutoCurveDistanceRangeInMeters(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, float * pfMinDistanceInMeters, float * pfMaxDistanceInMeters);
EVROverlayError tr_ovw_SetOverlayTextureColorSpace(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, EColorSpace eTextureColorSpace);
EVROverlayError tr_ovw_GetOverlayTextureColorSpace(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, EColorSpace * peTextureColorSpace);
EVROverlayError tr_ovw_SetOverlayTextureBounds(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, VRTextureBounds_t * pOverlayTextureBounds);
EVROverlayError tr_ovw_GetOverlayTextureBounds(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, VRTextureBounds_t * pOverlayTextureBounds);
EVROverlayError tr_ovw_GetOverlayTransformType(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, VROverlayTransformType * peTransformType);
EVROverlayError tr_ovw_SetOverlayTransformAbsolute(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, ETrackingUniverseOrigin eTrackingOrigin, HmdMatrix34_t * pmatTrackingOriginToOverlayTransform);
EVROverlayError tr_ovw_GetOverlayTransformAbsolute(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, ETrackingUniverseOrigin * peTrackingOrigin, HmdMatrix34_t * pmatTrackingOriginToOverlayTransform);
EVROverlayError tr_ovw_SetOverlayTransformTrackedDeviceRelative(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, TrackedDeviceIndex_t unTrackedDevice, HmdMatrix34_t * pmatTrackedDeviceToOverlayTransform);
EVROverlayError tr_ovw_GetOverlayTransformTrackedDeviceRelative(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, TrackedDeviceIndex_t * punTrackedDevice, HmdMatrix34_t * pmatTrackedDeviceToOverlayTransform);
EVROverlayError tr_ovw_SetOverlayTransformTrackedDeviceComponent(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, TrackedDeviceIndex_t unDeviceIndex, char * pchComponentName);
EVROverlayError tr_ovw_GetOverlayTransformTrackedDeviceComponent(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, TrackedDeviceIndex_t * punDeviceIndex, char * pchComponentName, uint32_t unComponentNameSize);
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
bool tr_ovw_HandleControllerOverlayInteractionAsMouse(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, TrackedDeviceIndex_t unControllerDeviceIndex);
bool tr_ovw_IsHoverTargetOverlay(IVROverlay* self, VROverlayHandle_t ulOverlayHandle);
VROverlayHandle_t tr_ovw_GetGamepadFocusOverlay(IVROverlay* self);
EVROverlayError tr_ovw_SetGamepadFocusOverlay(IVROverlay* self, VROverlayHandle_t ulNewFocusOverlay);
EVROverlayError tr_ovw_SetOverlayNeighbor(IVROverlay* self, EOverlayDirection eDirection, VROverlayHandle_t ulFrom, VROverlayHandle_t ulTo);
EVROverlayError tr_ovw_MoveGamepadFocusToNeighbor(IVROverlay* self, EOverlayDirection eDirection, VROverlayHandle_t ulFrom);
EVROverlayError tr_ovw_SetOverlayTexture(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, Texture_t * pTexture);
EVROverlayError tr_ovw_ClearOverlayTexture(IVROverlay* self, VROverlayHandle_t ulOverlayHandle);
EVROverlayError tr_ovw_SetOverlayRaw(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, void * pvBuffer, uint32_t unWidth, uint32_t unHeight, uint32_t unDepth);
EVROverlayError tr_ovw_SetOverlayFromFile(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, char * pchFilePath);
EVROverlayError tr_ovw_GetOverlayTexture(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, void ** pNativeTextureHandle, void * pNativeTextureRef, uint32_t * pWidth, uint32_t * pHeight, uint32_t * pNativeFormat, EGraphicsAPIConvention * pAPI, EColorSpace * pColorSpace);
EVROverlayError tr_ovw_ReleaseNativeOverlayHandle(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, void * pNativeTextureHandle);
EVROverlayError tr_ovw_CreateDashboardOverlay(IVROverlay* self, char * pchOverlayKey, char * pchOverlayFriendlyName, VROverlayHandle_t * pMainHandle, VROverlayHandle_t * pThumbnailHandle);
bool tr_ovw_IsDashboardVisible(IVROverlay* self);
bool tr_ovw_IsActiveDashboardOverlay(IVROverlay* self, VROverlayHandle_t ulOverlayHandle);
EVROverlayError tr_ovw_SetDashboardOverlaySceneProcess(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, uint32_t unProcessId);
EVROverlayError tr_ovw_GetDashboardOverlaySceneProcess(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, uint32_t * punProcessId);
void tr_ovw_ShowDashboard(IVROverlay* self, char * pchOverlayToShow);
TrackedDeviceIndex_t tr_ovw_GetPrimaryDashboardDevice(IVROverlay* self);
EVROverlayError tr_ovw_ShowKeyboard(IVROverlay* self, EGamepadTextInputMode eInputMode, EGamepadTextInputLineMode eLineInputMode, char * pchDescription, uint32_t unCharMax, char * pchExistingText, bool bUseMinimalMode, uint64_t uUserValue);
EVROverlayError tr_ovw_ShowKeyboardForOverlay(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, EGamepadTextInputMode eInputMode, EGamepadTextInputLineMode eLineInputMode, char * pchDescription, uint32_t unCharMax, char * pchExistingText, bool bUseMinimalMode, uint64_t uUserValue);
uint32_t tr_ovw_GetKeyboardText(IVROverlay* self, char * pchText, uint32_t cchText);
void tr_ovw_HideKeyboard(IVROverlay* self);
void tr_ovw_SetKeyboardTransformAbsolute(IVROverlay* self, ETrackingUniverseOrigin eTrackingOrigin, HmdMatrix34_t * pmatTrackingOriginToKeyboardTransform);
void tr_ovw_SetKeyboardPositionForOverlay(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, HmdRect2_t avoidRect);
EVRRenderModelError tr_ovw_LoadRenderModel_Async(IVRRenderModels* self, char * pchRenderModelName, RenderModel_t ** ppRenderModel);
void tr_ovw_FreeRenderModel(IVRRenderModels* self, RenderModel_t * pRenderModel);
EVRRenderModelError tr_ovw_LoadTexture_Async(IVRRenderModels* self, TextureID_t textureId, RenderModel_TextureMap_t ** ppTexture);
void tr_ovw_FreeTexture(IVRRenderModels* self, RenderModel_TextureMap_t * pTexture);
EVRRenderModelError tr_ovw_LoadTextureD3D11_Async(IVRRenderModels* self, TextureID_t textureId, void * pD3D11Device, void ** ppD3D11Texture2D);
EVRRenderModelError tr_ovw_LoadIntoTextureD3D11_Async(IVRRenderModels* self, TextureID_t textureId, void * pDstTexture);
void tr_ovw_FreeTextureD3D11(IVRRenderModels* self, void * pD3D11Texture2D);
uint32_t tr_ovw_GetRenderModelName(IVRRenderModels* self, uint32_t unRenderModelIndex, char * pchRenderModelName, uint32_t unRenderModelNameLen);
uint32_t tr_ovw_GetRenderModelCount(IVRRenderModels* self);
uint32_t tr_ovw_GetComponentCount(IVRRenderModels* self, char * pchRenderModelName);
uint32_t tr_ovw_GetComponentName(IVRRenderModels* self, char * pchRenderModelName, uint32_t unComponentIndex, char * pchComponentName, uint32_t unComponentNameLen);
uint64_t tr_ovw_GetComponentButtonMask(IVRRenderModels* self, char * pchRenderModelName, char * pchComponentName);
uint32_t tr_ovw_GetComponentRenderModelName(IVRRenderModels* self, char * pchRenderModelName, char * pchComponentName, char * pchComponentRenderModelName, uint32_t unComponentRenderModelNameLen);
bool tr_ovw_GetComponentState(IVRRenderModels* self, char * pchRenderModelName, char * pchComponentName, VRControllerState_t * pControllerState, RenderModel_ControllerMode_State_t * pState, RenderModel_ComponentState_t * pComponentState);
bool tr_ovw_RenderModelHasComponent(IVRRenderModels* self, char * pchRenderModelName, char * pchComponentName);
EVRNotificationError tr_ovw_CreateNotification(IVRNotifications* self, VROverlayHandle_t ulOverlayHandle, uint64_t ulUserValue, EVRNotificationType type, char * pchText, EVRNotificationStyle style, NotificationBitmap_t * pImage, VRNotificationId * pNotificationId);
EVRNotificationError tr_ovw_RemoveNotification(IVRNotifications* self, VRNotificationId notificationId);
const char * tr_ovw_GetSettingsErrorNameFromEnum(IVRSettings* self, EVRSettingsError eError);
bool tr_ovw_Sync(IVRSettings* self, bool bForce, EVRSettingsError * peError);
bool tr_ovw_GetBool(IVRSettings* self, char * pchSection, char * pchSettingsKey, bool bDefaultValue, EVRSettingsError * peError);
void tr_ovw_SetBool(IVRSettings* self, char * pchSection, char * pchSettingsKey, bool bValue, EVRSettingsError * peError);
int32_t tr_ovw_GetInt32(IVRSettings* self, char * pchSection, char * pchSettingsKey, int32_t nDefaultValue, EVRSettingsError * peError);
void tr_ovw_SetInt32(IVRSettings* self, char * pchSection, char * pchSettingsKey, int32_t nValue, EVRSettingsError * peError);
float tr_ovw_GetFloat(IVRSettings* self, char * pchSection, char * pchSettingsKey, float flDefaultValue, EVRSettingsError * peError);
void tr_ovw_SetFloat(IVRSettings* self, char * pchSection, char * pchSettingsKey, float flValue, EVRSettingsError * peError);
void tr_ovw_GetString(IVRSettings* self, char * pchSection, char * pchSettingsKey, char * pchValue, uint32_t unValueLen, char * pchDefaultValue, EVRSettingsError * peError);
void tr_ovw_SetString(IVRSettings* self, char * pchSection, char * pchSettingsKey, char * pchValue, EVRSettingsError * peError);
void tr_ovw_RemoveSection(IVRSettings* self, char * pchSection, EVRSettingsError * peError);
void tr_ovw_RemoveKeyInSection(IVRSettings* self, char * pchSection, char * pchSettingsKey, EVRSettingsError * peError);
