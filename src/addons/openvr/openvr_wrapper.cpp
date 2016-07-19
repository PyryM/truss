#include "openvr_addon.h"

void tr_ovw_GetRecommendedRenderTargetSize(vr::IVRSystem* self, uint32_t * pnWidth, uint32_t * pnHeight){
    self->GetRecommendedRenderTargetSize(pnWidth, pnHeight);
}

vr::HmdMatrix44_t tr_ovw_GetProjectionMatrix(vr::IVRSystem* self, vr::EVREye eEye, float fNearZ, float fFarZ, vr::EGraphicsAPIConvention eProjType){
    return self->GetProjectionMatrix(eEye, fNearZ, fFarZ, eProjType);
}

void tr_ovw_GetProjectionRaw(vr::IVRSystem* self, vr::EVREye eEye, float * pfLeft, float * pfRight, float * pfTop, float * pfBottom){
    self->GetProjectionRaw(eEye, pfLeft, pfRight, pfTop, pfBottom);
}

vr::DistortionCoordinates_t tr_ovw_ComputeDistortion(vr::IVRSystem* self, vr::EVREye eEye, float fU, float fV){
    return self->ComputeDistortion(eEye, fU, fV);
}

vr::HmdMatrix34_t tr_ovw_GetEyeToHeadTransform(vr::IVRSystem* self, vr::EVREye eEye){
    return self->GetEyeToHeadTransform(eEye);
}

bool tr_ovw_GetTimeSinceLastVsync(vr::IVRSystem* self, float * pfSecondsSinceLastVsync, uint64_t * pulFrameCounter){
    return self->GetTimeSinceLastVsync(pfSecondsSinceLastVsync, pulFrameCounter);
}

int32_t tr_ovw_GetD3D9AdapterIndex(vr::IVRSystem* self){
    return self->GetD3D9AdapterIndex();
}

void tr_ovw_GetDXGIOutputInfo(vr::IVRSystem* self, int32_t * pnAdapterIndex){
    self->GetDXGIOutputInfo(pnAdapterIndex);
}

bool tr_ovw_IsDisplayOnDesktop(vr::IVRSystem* self){
    return self->IsDisplayOnDesktop();
}

bool tr_ovw_SetDisplayVisibility(vr::IVRSystem* self, bool bIsVisibleOnDesktop){
    return self->SetDisplayVisibility(bIsVisibleOnDesktop);
}

void tr_ovw_GetDeviceToAbsoluteTrackingPose(vr::IVRSystem* self, vr::ETrackingUniverseOrigin eOrigin, float fPredictedSecondsToPhotonsFromNow, vr::TrackedDevicePose_t * pTrackedDevicePoseArray, uint32_t unTrackedDevicePoseArrayCount){
    self->GetDeviceToAbsoluteTrackingPose(eOrigin, fPredictedSecondsToPhotonsFromNow, pTrackedDevicePoseArray, unTrackedDevicePoseArrayCount);
}

void tr_ovw_ResetSeatedZeroPose(vr::IVRSystem* self){
    self->ResetSeatedZeroPose();
}

vr::HmdMatrix34_t tr_ovw_GetSeatedZeroPoseToStandingAbsoluteTrackingPose(vr::IVRSystem* self){
    return self->GetSeatedZeroPoseToStandingAbsoluteTrackingPose();
}

vr::HmdMatrix34_t tr_ovw_GetRawZeroPoseToStandingAbsoluteTrackingPose(vr::IVRSystem* self){
    return self->GetRawZeroPoseToStandingAbsoluteTrackingPose();
}

uint32_t tr_ovw_GetSortedTrackedDeviceIndicesOfClass(vr::IVRSystem* self, vr::ETrackedDeviceClass eTrackedDeviceClass, vr::TrackedDeviceIndex_t * punTrackedDeviceIndexArray, uint32_t unTrackedDeviceIndexArrayCount, vr::TrackedDeviceIndex_t unRelativeToTrackedDeviceIndex){
    return self->GetSortedTrackedDeviceIndicesOfClass(eTrackedDeviceClass, punTrackedDeviceIndexArray, unTrackedDeviceIndexArrayCount, unRelativeToTrackedDeviceIndex);
}

vr::EDeviceActivityLevel tr_ovw_GetTrackedDeviceActivityLevel(vr::IVRSystem* self, vr::TrackedDeviceIndex_t unDeviceId){
    return self->GetTrackedDeviceActivityLevel(unDeviceId);
}

void tr_ovw_ApplyTransform(vr::IVRSystem* self, vr::TrackedDevicePose_t * pOutputPose, vr::TrackedDevicePose_t * pTrackedDevicePose, vr::HmdMatrix34_t * pTransform){
    self->ApplyTransform(pOutputPose, pTrackedDevicePose, pTransform);
}

vr::TrackedDeviceIndex_t tr_ovw_GetTrackedDeviceIndexForControllerRole(vr::IVRSystem* self, vr::ETrackedControllerRole unDeviceType){
    return self->GetTrackedDeviceIndexForControllerRole(unDeviceType);
}

vr::ETrackedControllerRole tr_ovw_GetControllerRoleForTrackedDeviceIndex(vr::IVRSystem* self, vr::TrackedDeviceIndex_t unDeviceIndex){
    return self->GetControllerRoleForTrackedDeviceIndex(unDeviceIndex);
}

vr::ETrackedDeviceClass tr_ovw_GetTrackedDeviceClass(vr::IVRSystem* self, vr::TrackedDeviceIndex_t unDeviceIndex){
    return self->GetTrackedDeviceClass(unDeviceIndex);
}

bool tr_ovw_IsTrackedDeviceConnected(vr::IVRSystem* self, vr::TrackedDeviceIndex_t unDeviceIndex){
    return self->IsTrackedDeviceConnected(unDeviceIndex);
}

bool tr_ovw_GetBoolTrackedDeviceProperty(vr::IVRSystem* self, vr::TrackedDeviceIndex_t unDeviceIndex, vr::ETrackedDeviceProperty prop, vr::ETrackedPropertyError * pError){
    return self->GetBoolTrackedDeviceProperty(unDeviceIndex, prop, pError);
}

float tr_ovw_GetFloatTrackedDeviceProperty(vr::IVRSystem* self, vr::TrackedDeviceIndex_t unDeviceIndex, vr::ETrackedDeviceProperty prop, vr::ETrackedPropertyError * pError){
    return self->GetFloatTrackedDeviceProperty(unDeviceIndex, prop, pError);
}

int32_t tr_ovw_GetInt32TrackedDeviceProperty(vr::IVRSystem* self, vr::TrackedDeviceIndex_t unDeviceIndex, vr::ETrackedDeviceProperty prop, vr::ETrackedPropertyError * pError){
    return self->GetInt32TrackedDeviceProperty(unDeviceIndex, prop, pError);
}

uint64_t tr_ovw_GetUint64TrackedDeviceProperty(vr::IVRSystem* self, vr::TrackedDeviceIndex_t unDeviceIndex, vr::ETrackedDeviceProperty prop, vr::ETrackedPropertyError * pError){
    return self->GetUint64TrackedDeviceProperty(unDeviceIndex, prop, pError);
}

vr::HmdMatrix34_t tr_ovw_GetMatrix34TrackedDeviceProperty(vr::IVRSystem* self, vr::TrackedDeviceIndex_t unDeviceIndex, vr::ETrackedDeviceProperty prop, vr::ETrackedPropertyError * pError){
    return self->GetMatrix34TrackedDeviceProperty(unDeviceIndex, prop, pError);
}

uint32_t tr_ovw_GetStringTrackedDeviceProperty(vr::IVRSystem* self, vr::TrackedDeviceIndex_t unDeviceIndex, vr::ETrackedDeviceProperty prop, char * pchValue, uint32_t unBufferSize, vr::ETrackedPropertyError * pError){
    return self->GetStringTrackedDeviceProperty(unDeviceIndex, prop, pchValue, unBufferSize, pError);
}

const char * tr_ovw_GetPropErrorNameFromEnum(vr::IVRSystem* self, vr::ETrackedPropertyError error){
    return self->GetPropErrorNameFromEnum(error);
}

bool tr_ovw_PollNextEvent(vr::IVRSystem* self, vr::VREvent_t * pEvent, uint32_t uncbVREvent){
    return self->PollNextEvent(pEvent, uncbVREvent);
}

bool tr_ovw_PollNextEventWithPose(vr::IVRSystem* self, vr::ETrackingUniverseOrigin eOrigin, vr::VREvent_t * pEvent, uint32_t uncbVREvent, vr::TrackedDevicePose_t * pTrackedDevicePose){
    return self->PollNextEventWithPose(eOrigin, pEvent, uncbVREvent, pTrackedDevicePose);
}

const char * tr_ovw_GetEventTypeNameFromEnum(vr::IVRSystem* self, vr::EVREventType eType){
    return self->GetEventTypeNameFromEnum(eType);
}

vr::HiddenAreaMesh_t tr_ovw_GetHiddenAreaMesh(vr::IVRSystem* self, vr::EVREye eEye){
    return self->GetHiddenAreaMesh(eEye);
}

bool tr_ovw_GetControllerState(vr::IVRSystem* self, vr::TrackedDeviceIndex_t unControllerDeviceIndex, vr::VRControllerState_t * pControllerState){
    return self->GetControllerState(unControllerDeviceIndex, pControllerState);
}

bool tr_ovw_GetControllerStateWithPose(vr::IVRSystem* self, vr::ETrackingUniverseOrigin eOrigin, vr::TrackedDeviceIndex_t unControllerDeviceIndex, vr::VRControllerState_t * pControllerState, vr::TrackedDevicePose_t * pTrackedDevicePose){
    return self->GetControllerStateWithPose(eOrigin, unControllerDeviceIndex, pControllerState, pTrackedDevicePose);
}

void tr_ovw_TriggerHapticPulse(vr::IVRSystem* self, vr::TrackedDeviceIndex_t unControllerDeviceIndex, uint32_t unAxisId, unsigned short usDurationMicroSec){
    self->TriggerHapticPulse(unControllerDeviceIndex, unAxisId, usDurationMicroSec);
}

const char * tr_ovw_GetButtonIdNameFromEnum(vr::IVRSystem* self, vr::EVRButtonId eButtonId){
    return self->GetButtonIdNameFromEnum(eButtonId);
}

const char * tr_ovw_GetControllerAxisTypeNameFromEnum(vr::IVRSystem* self, vr::EVRControllerAxisType eAxisType){
    return self->GetControllerAxisTypeNameFromEnum(eAxisType);
}

bool tr_ovw_CaptureInputFocus(vr::IVRSystem* self){
    return self->CaptureInputFocus();
}

void tr_ovw_ReleaseInputFocus(vr::IVRSystem* self){
    self->ReleaseInputFocus();
}

bool tr_ovw_IsInputFocusCapturedByAnotherProcess(vr::IVRSystem* self){
    return self->IsInputFocusCapturedByAnotherProcess();
}

uint32_t tr_ovw_DriverDebugRequest(vr::IVRSystem* self, vr::TrackedDeviceIndex_t unDeviceIndex, char * pchRequest, char * pchResponseBuffer, uint32_t unResponseBufferSize){
    return self->DriverDebugRequest(unDeviceIndex, pchRequest, pchResponseBuffer, unResponseBufferSize);
}

vr::EVRFirmwareError tr_ovw_PerformFirmwareUpdate(vr::IVRSystem* self, vr::TrackedDeviceIndex_t unDeviceIndex){
    return self->PerformFirmwareUpdate(unDeviceIndex);
}

void tr_ovw_AcknowledgeQuit_Exiting(vr::IVRSystem* self){
    self->AcknowledgeQuit_Exiting();
}

void tr_ovw_AcknowledgeQuit_UserPrompt(vr::IVRSystem* self){
    self->AcknowledgeQuit_UserPrompt();
}

void tr_ovw_GetWindowBounds(vr::IVRExtendedDisplay* self, int32_t * pnX, int32_t * pnY, uint32_t * pnWidth, uint32_t * pnHeight){
    self->GetWindowBounds(pnX, pnY, pnWidth, pnHeight);
}

void tr_ovw_GetEyeOutputViewport(vr::IVRExtendedDisplay* self, vr::EVREye eEye, uint32_t * pnX, uint32_t * pnY, uint32_t * pnWidth, uint32_t * pnHeight){
    self->GetEyeOutputViewport(eEye, pnX, pnY, pnWidth, pnHeight);
}

//void tr_ovw_GetDXGIOutputInfo(vr::IVRExtendedDisplay* self, int32_t * pnAdapterIndex, int32_t * pnAdapterOutputIndex){
//    self->GetDXGIOutputInfo(pnAdapterIndex, pnAdapterOutputIndex);
//}

vr::EVRApplicationError tr_ovw_AddApplicationManifest(vr::IVRApplications* self, char * pchApplicationManifestFullPath, bool bTemporary){
    return self->AddApplicationManifest(pchApplicationManifestFullPath, bTemporary);
}

vr::EVRApplicationError tr_ovw_RemoveApplicationManifest(vr::IVRApplications* self, char * pchApplicationManifestFullPath){
    return self->RemoveApplicationManifest(pchApplicationManifestFullPath);
}

bool tr_ovw_IsApplicationInstalled(vr::IVRApplications* self, char * pchAppKey){
    return self->IsApplicationInstalled(pchAppKey);
}

uint32_t tr_ovw_GetApplicationCount(vr::IVRApplications* self){
    return self->GetApplicationCount();
}

vr::EVRApplicationError tr_ovw_GetApplicationKeyByIndex(vr::IVRApplications* self, uint32_t unApplicationIndex, char * pchAppKeyBuffer, uint32_t unAppKeyBufferLen){
    return self->GetApplicationKeyByIndex(unApplicationIndex, pchAppKeyBuffer, unAppKeyBufferLen);
}

vr::EVRApplicationError tr_ovw_GetApplicationKeyByProcessId(vr::IVRApplications* self, uint32_t unProcessId, char * pchAppKeyBuffer, uint32_t unAppKeyBufferLen){
    return self->GetApplicationKeyByProcessId(unProcessId, pchAppKeyBuffer, unAppKeyBufferLen);
}

vr::EVRApplicationError tr_ovw_LaunchApplication(vr::IVRApplications* self, char * pchAppKey){
    return self->LaunchApplication(pchAppKey);
}

vr::EVRApplicationError tr_ovw_LaunchTemplateApplication(vr::IVRApplications* self, char * pchTemplateAppKey, char * pchNewAppKey, vr::AppOverrideKeys_t * pKeys, uint32_t unKeys){
    return self->LaunchTemplateApplication(pchTemplateAppKey, pchNewAppKey, pKeys, unKeys);
}

vr::EVRApplicationError tr_ovw_LaunchDashboardOverlay(vr::IVRApplications* self, char * pchAppKey){
    return self->LaunchDashboardOverlay(pchAppKey);
}

bool tr_ovw_CancelApplicationLaunch(vr::IVRApplications* self, char * pchAppKey){
    return self->CancelApplicationLaunch(pchAppKey);
}

vr::EVRApplicationError tr_ovw_IdentifyApplication(vr::IVRApplications* self, uint32_t unProcessId, char * pchAppKey){
    return self->IdentifyApplication(unProcessId, pchAppKey);
}

uint32_t tr_ovw_GetApplicationProcessId(vr::IVRApplications* self, char * pchAppKey){
    return self->GetApplicationProcessId(pchAppKey);
}

const char * tr_ovw_GetApplicationsErrorNameFromEnum(vr::IVRApplications* self, vr::EVRApplicationError error){
    return self->GetApplicationsErrorNameFromEnum(error);
}

uint32_t tr_ovw_GetApplicationPropertyString(vr::IVRApplications* self, char * pchAppKey, vr::EVRApplicationProperty eProperty, char * pchPropertyValueBuffer, uint32_t unPropertyValueBufferLen, vr::EVRApplicationError * peError){
    return self->GetApplicationPropertyString(pchAppKey, eProperty, pchPropertyValueBuffer, unPropertyValueBufferLen, peError);
}

bool tr_ovw_GetApplicationPropertyBool(vr::IVRApplications* self, char * pchAppKey, vr::EVRApplicationProperty eProperty, vr::EVRApplicationError * peError){
    return self->GetApplicationPropertyBool(pchAppKey, eProperty, peError);
}

uint64_t tr_ovw_GetApplicationPropertyUint64(vr::IVRApplications* self, char * pchAppKey, vr::EVRApplicationProperty eProperty, vr::EVRApplicationError * peError){
    return self->GetApplicationPropertyUint64(pchAppKey, eProperty, peError);
}

vr::EVRApplicationError tr_ovw_SetApplicationAutoLaunch(vr::IVRApplications* self, char * pchAppKey, bool bAutoLaunch){
    return self->SetApplicationAutoLaunch(pchAppKey, bAutoLaunch);
}

bool tr_ovw_GetApplicationAutoLaunch(vr::IVRApplications* self, char * pchAppKey){
    return self->GetApplicationAutoLaunch(pchAppKey);
}

vr::EVRApplicationError tr_ovw_GetStartingApplication(vr::IVRApplications* self, char * pchAppKeyBuffer, uint32_t unAppKeyBufferLen){
    return self->GetStartingApplication(pchAppKeyBuffer, unAppKeyBufferLen);
}

vr::EVRApplicationTransitionState tr_ovw_GetTransitionState(vr::IVRApplications* self){
    return self->GetTransitionState();
}

vr::EVRApplicationError tr_ovw_PerformApplicationPrelaunchCheck(vr::IVRApplications* self, char * pchAppKey){
    return self->PerformApplicationPrelaunchCheck(pchAppKey);
}

const char * tr_ovw_GetApplicationsTransitionStateNameFromEnum(vr::IVRApplications* self, vr::EVRApplicationTransitionState state){
    return self->GetApplicationsTransitionStateNameFromEnum(state);
}

bool tr_ovw_IsQuitUserPromptRequested(vr::IVRApplications* self){
    return self->IsQuitUserPromptRequested();
}

vr::EVRApplicationError tr_ovw_LaunchInternalProcess(vr::IVRApplications* self, char * pchBinaryPath, char * pchArguments, char * pchWorkingDirectory){
    return self->LaunchInternalProcess(pchBinaryPath, pchArguments, pchWorkingDirectory);
}

vr::ChaperoneCalibrationState tr_ovw_GetCalibrationState(vr::IVRChaperone* self){
    return self->GetCalibrationState();
}

bool tr_ovw_GetPlayAreaSize(vr::IVRChaperone* self, float * pSizeX, float * pSizeZ){
    return self->GetPlayAreaSize(pSizeX, pSizeZ);
}

bool tr_ovw_GetPlayAreaRect(vr::IVRChaperone* self, vr::HmdQuad_t * rect){
    return self->GetPlayAreaRect(rect);
}

void tr_ovw_ReloadInfo(vr::IVRChaperone* self){
    self->ReloadInfo();
}

void tr_ovw_SetSceneColor(vr::IVRChaperone* self, vr::HmdColor_t color){
    self->SetSceneColor(color);
}

void tr_ovw_GetBoundsColor(vr::IVRChaperone* self, vr::HmdColor_t * pOutputColorArray, int nNumOutputColors, float flCollisionBoundsFadeDistance, vr::HmdColor_t * pOutputCameraColor){
    self->GetBoundsColor(pOutputColorArray, nNumOutputColors, flCollisionBoundsFadeDistance, pOutputCameraColor);
}

bool tr_ovw_AreBoundsVisible(vr::IVRChaperone* self){
    return self->AreBoundsVisible();
}

void tr_ovw_ForceBoundsVisible(vr::IVRChaperone* self, bool bForce){
    self->ForceBoundsVisible(bForce);
}

bool tr_ovw_CommitWorkingCopy(vr::IVRChaperoneSetup* self, vr::EChaperoneConfigFile configFile){
    return self->CommitWorkingCopy(configFile);
}

void tr_ovw_RevertWorkingCopy(vr::IVRChaperoneSetup* self){
    self->RevertWorkingCopy();
}

bool tr_ovw_GetWorkingPlayAreaSize(vr::IVRChaperoneSetup* self, float * pSizeX, float * pSizeZ){
    return self->GetWorkingPlayAreaSize(pSizeX, pSizeZ);
}

bool tr_ovw_GetWorkingPlayAreaRect(vr::IVRChaperoneSetup* self, vr::HmdQuad_t * rect){
    return self->GetWorkingPlayAreaRect(rect);
}

bool tr_ovw_GetWorkingCollisionBoundsInfo(vr::IVRChaperoneSetup* self, vr::HmdQuad_t * pQuadsBuffer, uint32_t * punQuadsCount){
    return self->GetWorkingCollisionBoundsInfo(pQuadsBuffer, punQuadsCount);
}

bool tr_ovw_GetLiveCollisionBoundsInfo(vr::IVRChaperoneSetup* self, vr::HmdQuad_t * pQuadsBuffer, uint32_t * punQuadsCount){
    return self->GetLiveCollisionBoundsInfo(pQuadsBuffer, punQuadsCount);
}

bool tr_ovw_GetWorkingSeatedZeroPoseToRawTrackingPose(vr::IVRChaperoneSetup* self, vr::HmdMatrix34_t * pmatSeatedZeroPoseToRawTrackingPose){
    return self->GetWorkingSeatedZeroPoseToRawTrackingPose(pmatSeatedZeroPoseToRawTrackingPose);
}

bool tr_ovw_GetWorkingStandingZeroPoseToRawTrackingPose(vr::IVRChaperoneSetup* self, vr::HmdMatrix34_t * pmatStandingZeroPoseToRawTrackingPose){
    return self->GetWorkingStandingZeroPoseToRawTrackingPose(pmatStandingZeroPoseToRawTrackingPose);
}

void tr_ovw_SetWorkingPlayAreaSize(vr::IVRChaperoneSetup* self, float sizeX, float sizeZ){
    self->SetWorkingPlayAreaSize(sizeX, sizeZ);
}

void tr_ovw_SetWorkingCollisionBoundsInfo(vr::IVRChaperoneSetup* self, vr::HmdQuad_t * pQuadsBuffer, uint32_t unQuadsCount){
    self->SetWorkingCollisionBoundsInfo(pQuadsBuffer, unQuadsCount);
}

void tr_ovw_SetWorkingSeatedZeroPoseToRawTrackingPose(vr::IVRChaperoneSetup* self, vr::HmdMatrix34_t * pMatSeatedZeroPoseToRawTrackingPose){
    self->SetWorkingSeatedZeroPoseToRawTrackingPose(pMatSeatedZeroPoseToRawTrackingPose);
}

void tr_ovw_SetWorkingStandingZeroPoseToRawTrackingPose(vr::IVRChaperoneSetup* self, vr::HmdMatrix34_t * pMatStandingZeroPoseToRawTrackingPose){
    self->SetWorkingStandingZeroPoseToRawTrackingPose(pMatStandingZeroPoseToRawTrackingPose);
}

void tr_ovw_ReloadFromDisk(vr::IVRChaperoneSetup* self, vr::EChaperoneConfigFile configFile){
    self->ReloadFromDisk(configFile);
}

bool tr_ovw_GetLiveSeatedZeroPoseToRawTrackingPose(vr::IVRChaperoneSetup* self, vr::HmdMatrix34_t * pmatSeatedZeroPoseToRawTrackingPose){
    return self->GetLiveSeatedZeroPoseToRawTrackingPose(pmatSeatedZeroPoseToRawTrackingPose);
}

void tr_ovw_SetWorkingCollisionBoundsTagsInfo(vr::IVRChaperoneSetup* self, uint8_t * pTagsBuffer, uint32_t unTagCount){
    self->SetWorkingCollisionBoundsTagsInfo(pTagsBuffer, unTagCount);
}

bool tr_ovw_GetLiveCollisionBoundsTagsInfo(vr::IVRChaperoneSetup* self, uint8_t * pTagsBuffer, uint32_t * punTagCount){
    return self->GetLiveCollisionBoundsTagsInfo(pTagsBuffer, punTagCount);
}

bool tr_ovw_SetWorkingPhysicalBoundsInfo(vr::IVRChaperoneSetup* self, vr::HmdQuad_t * pQuadsBuffer, uint32_t unQuadsCount){
    return self->SetWorkingPhysicalBoundsInfo(pQuadsBuffer, unQuadsCount);
}

bool tr_ovw_GetLivePhysicalBoundsInfo(vr::IVRChaperoneSetup* self, vr::HmdQuad_t * pQuadsBuffer, uint32_t * punQuadsCount){
    return self->GetLivePhysicalBoundsInfo(pQuadsBuffer, punQuadsCount);
}

bool tr_ovw_ExportLiveToBuffer(vr::IVRChaperoneSetup* self, char * pBuffer, uint32_t * pnBufferLength){
    return self->ExportLiveToBuffer(pBuffer, pnBufferLength);
}

bool tr_ovw_ImportFromBufferToWorking(vr::IVRChaperoneSetup* self, char * pBuffer, uint32_t nImportFlags){
    return self->ImportFromBufferToWorking(pBuffer, nImportFlags);
}

void tr_ovw_SetTrackingSpace(vr::IVRCompositor* self, vr::ETrackingUniverseOrigin eOrigin){
    self->SetTrackingSpace(eOrigin);
}

vr::ETrackingUniverseOrigin tr_ovw_GetTrackingSpace(vr::IVRCompositor* self){
    return self->GetTrackingSpace();
}

vr::EVRCompositorError tr_ovw_WaitGetPoses(vr::IVRCompositor* self, vr::TrackedDevicePose_t * pRenderPoseArray, uint32_t unRenderPoseArrayCount, vr::TrackedDevicePose_t * pGamePoseArray, uint32_t unGamePoseArrayCount){
    return self->WaitGetPoses(pRenderPoseArray, unRenderPoseArrayCount, pGamePoseArray, unGamePoseArrayCount);
}

vr::EVRCompositorError tr_ovw_GetLastPoses(vr::IVRCompositor* self, vr::TrackedDevicePose_t * pRenderPoseArray, uint32_t unRenderPoseArrayCount, vr::TrackedDevicePose_t * pGamePoseArray, uint32_t unGamePoseArrayCount){
    return self->GetLastPoses(pRenderPoseArray, unRenderPoseArrayCount, pGamePoseArray, unGamePoseArrayCount);
}

vr::EVRCompositorError tr_ovw_GetLastPoseForTrackedDeviceIndex(vr::IVRCompositor* self, vr::TrackedDeviceIndex_t unDeviceIndex, vr::TrackedDevicePose_t * pOutputPose, vr::TrackedDevicePose_t * pOutputGamePose){
    return self->GetLastPoseForTrackedDeviceIndex(unDeviceIndex, pOutputPose, pOutputGamePose);
}

vr::EVRCompositorError tr_ovw_Submit(vr::IVRCompositor* self, vr::EVREye eEye, vr::Texture_t * pTexture, vr::VRTextureBounds_t * pBounds, vr::EVRSubmitFlags nSubmitFlags){
    return self->Submit(eEye, pTexture, pBounds, nSubmitFlags);
}

void tr_ovw_ClearLastSubmittedFrame(vr::IVRCompositor* self){
    self->ClearLastSubmittedFrame();
}

void tr_ovw_PostPresentHandoff(vr::IVRCompositor* self){
    self->PostPresentHandoff();
}

bool tr_ovw_GetFrameTiming(vr::IVRCompositor* self, vr::Compositor_FrameTiming * pTiming, uint32_t unFramesAgo){
    return self->GetFrameTiming(pTiming, unFramesAgo);
}

float tr_ovw_GetFrameTimeRemaining(vr::IVRCompositor* self){
    return self->GetFrameTimeRemaining();
}

void tr_ovw_FadeToColor(vr::IVRCompositor* self, float fSeconds, float fRed, float fGreen, float fBlue, float fAlpha, bool bBackground){
    self->FadeToColor(fSeconds, fRed, fGreen, fBlue, fAlpha, bBackground);
}

void tr_ovw_FadeGrid(vr::IVRCompositor* self, float fSeconds, bool bFadeIn){
    self->FadeGrid(fSeconds, bFadeIn);
}

vr::EVRCompositorError tr_ovw_SetSkyboxOverride(vr::IVRCompositor* self, vr::Texture_t * pTextures, uint32_t unTextureCount){
    return self->SetSkyboxOverride(pTextures, unTextureCount);
}

void tr_ovw_ClearSkyboxOverride(vr::IVRCompositor* self){
    self->ClearSkyboxOverride();
}

void tr_ovw_CompositorBringToFront(vr::IVRCompositor* self){
    self->CompositorBringToFront();
}

void tr_ovw_CompositorGoToBack(vr::IVRCompositor* self){
    self->CompositorGoToBack();
}

void tr_ovw_CompositorQuit(vr::IVRCompositor* self){
    self->CompositorQuit();
}

bool tr_ovw_IsFullscreen(vr::IVRCompositor* self){
    return self->IsFullscreen();
}

uint32_t tr_ovw_GetCurrentSceneFocusProcess(vr::IVRCompositor* self){
    return self->GetCurrentSceneFocusProcess();
}

uint32_t tr_ovw_GetLastFrameRenderer(vr::IVRCompositor* self){
    return self->GetLastFrameRenderer();
}

bool tr_ovw_CanRenderScene(vr::IVRCompositor* self){
    return self->CanRenderScene();
}

void tr_ovw_ShowMirrorWindow(vr::IVRCompositor* self){
    self->ShowMirrorWindow();
}

void tr_ovw_HideMirrorWindow(vr::IVRCompositor* self){
    self->HideMirrorWindow();
}

bool tr_ovw_IsMirrorWindowVisible(vr::IVRCompositor* self){
    return self->IsMirrorWindowVisible();
}

void tr_ovw_CompositorDumpImages(vr::IVRCompositor* self){
    self->CompositorDumpImages();
}

bool tr_ovw_ShouldAppRenderWithLowResources(vr::IVRCompositor* self){
    return self->ShouldAppRenderWithLowResources();
}

void tr_ovw_ForceInterleavedReprojectionOn(vr::IVRCompositor* self, bool bOverride){
    self->ForceInterleavedReprojectionOn(bOverride);
}

void tr_ovw_ForceReconnectProcess(vr::IVRCompositor* self){
    self->ForceReconnectProcess();
}

void tr_ovw_SuspendRendering(vr::IVRCompositor* self, bool bSuspend){
    self->SuspendRendering(bSuspend);
}

vr::EVROverlayError tr_ovw_FindOverlay(vr::IVROverlay* self, char * pchOverlayKey, vr::VROverlayHandle_t * pOverlayHandle){
    return self->FindOverlay(pchOverlayKey, pOverlayHandle);
}

vr::EVROverlayError tr_ovw_CreateOverlay(vr::IVROverlay* self, char * pchOverlayKey, char * pchOverlayFriendlyName, vr::VROverlayHandle_t * pOverlayHandle){
    return self->CreateOverlay(pchOverlayKey, pchOverlayFriendlyName, pOverlayHandle);
}

vr::EVROverlayError tr_ovw_DestroyOverlay(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle){
    return self->DestroyOverlay(ulOverlayHandle);
}

vr::EVROverlayError tr_ovw_SetHighQualityOverlay(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle){
    return self->SetHighQualityOverlay(ulOverlayHandle);
}

vr::VROverlayHandle_t tr_ovw_GetHighQualityOverlay(vr::IVROverlay* self){
    return self->GetHighQualityOverlay();
}

uint32_t tr_ovw_GetOverlayKey(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, char * pchValue, uint32_t unBufferSize, vr::EVROverlayError * pError){
    return self->GetOverlayKey(ulOverlayHandle, pchValue, unBufferSize, pError);
}

uint32_t tr_ovw_GetOverlayName(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, char * pchValue, uint32_t unBufferSize, vr::EVROverlayError * pError){
    return self->GetOverlayName(ulOverlayHandle, pchValue, unBufferSize, pError);
}

vr::EVROverlayError tr_ovw_GetOverlayImageData(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, void * pvBuffer, uint32_t unBufferSize, uint32_t * punWidth, uint32_t * punHeight){
    return self->GetOverlayImageData(ulOverlayHandle, pvBuffer, unBufferSize, punWidth, punHeight);
}

const char * tr_ovw_GetOverlayErrorNameFromEnum(vr::IVROverlay* self, vr::EVROverlayError error){
    return self->GetOverlayErrorNameFromEnum(error);
}

vr::EVROverlayError tr_ovw_SetOverlayRenderingPid(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, uint32_t unPID){
    return self->SetOverlayRenderingPid(ulOverlayHandle, unPID);
}

uint32_t tr_ovw_GetOverlayRenderingPid(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle){
    return self->GetOverlayRenderingPid(ulOverlayHandle);
}

vr::EVROverlayError tr_ovw_SetOverlayFlag(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::VROverlayFlags eOverlayFlag, bool bEnabled){
    return self->SetOverlayFlag(ulOverlayHandle, eOverlayFlag, bEnabled);
}

vr::EVROverlayError tr_ovw_GetOverlayFlag(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::VROverlayFlags eOverlayFlag, bool * pbEnabled){
    return self->GetOverlayFlag(ulOverlayHandle, eOverlayFlag, pbEnabled);
}

vr::EVROverlayError tr_ovw_SetOverlayColor(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, float fRed, float fGreen, float fBlue){
    return self->SetOverlayColor(ulOverlayHandle, fRed, fGreen, fBlue);
}

vr::EVROverlayError tr_ovw_GetOverlayColor(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, float * pfRed, float * pfGreen, float * pfBlue){
    return self->GetOverlayColor(ulOverlayHandle, pfRed, pfGreen, pfBlue);
}

vr::EVROverlayError tr_ovw_SetOverlayAlpha(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, float fAlpha){
    return self->SetOverlayAlpha(ulOverlayHandle, fAlpha);
}

vr::EVROverlayError tr_ovw_GetOverlayAlpha(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, float * pfAlpha){
    return self->GetOverlayAlpha(ulOverlayHandle, pfAlpha);
}

vr::EVROverlayError tr_ovw_SetOverlayWidthInMeters(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, float fWidthInMeters){
    return self->SetOverlayWidthInMeters(ulOverlayHandle, fWidthInMeters);
}

vr::EVROverlayError tr_ovw_GetOverlayWidthInMeters(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, float * pfWidthInMeters){
    return self->GetOverlayWidthInMeters(ulOverlayHandle, pfWidthInMeters);
}

vr::EVROverlayError tr_ovw_SetOverlayAutoCurveDistanceRangeInMeters(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, float fMinDistanceInMeters, float fMaxDistanceInMeters){
    return self->SetOverlayAutoCurveDistanceRangeInMeters(ulOverlayHandle, fMinDistanceInMeters, fMaxDistanceInMeters);
}

vr::EVROverlayError tr_ovw_GetOverlayAutoCurveDistanceRangeInMeters(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, float * pfMinDistanceInMeters, float * pfMaxDistanceInMeters){
    return self->GetOverlayAutoCurveDistanceRangeInMeters(ulOverlayHandle, pfMinDistanceInMeters, pfMaxDistanceInMeters);
}

vr::EVROverlayError tr_ovw_SetOverlayTextureColorSpace(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::EColorSpace eTextureColorSpace){
    return self->SetOverlayTextureColorSpace(ulOverlayHandle, eTextureColorSpace);
}

vr::EVROverlayError tr_ovw_GetOverlayTextureColorSpace(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::EColorSpace * peTextureColorSpace){
    return self->GetOverlayTextureColorSpace(ulOverlayHandle, peTextureColorSpace);
}

vr::EVROverlayError tr_ovw_SetOverlayTextureBounds(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::VRTextureBounds_t * pOverlayTextureBounds){
    return self->SetOverlayTextureBounds(ulOverlayHandle, pOverlayTextureBounds);
}

vr::EVROverlayError tr_ovw_GetOverlayTextureBounds(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::VRTextureBounds_t * pOverlayTextureBounds){
    return self->GetOverlayTextureBounds(ulOverlayHandle, pOverlayTextureBounds);
}

vr::EVROverlayError tr_ovw_GetOverlayTransformType(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::VROverlayTransformType * peTransformType){
    return self->GetOverlayTransformType(ulOverlayHandle, peTransformType);
}

vr::EVROverlayError tr_ovw_SetOverlayTransformAbsolute(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::ETrackingUniverseOrigin eTrackingOrigin, vr::HmdMatrix34_t * pmatTrackingOriginToOverlayTransform){
    return self->SetOverlayTransformAbsolute(ulOverlayHandle, eTrackingOrigin, pmatTrackingOriginToOverlayTransform);
}

vr::EVROverlayError tr_ovw_GetOverlayTransformAbsolute(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::ETrackingUniverseOrigin * peTrackingOrigin, vr::HmdMatrix34_t * pmatTrackingOriginToOverlayTransform){
    return self->GetOverlayTransformAbsolute(ulOverlayHandle, peTrackingOrigin, pmatTrackingOriginToOverlayTransform);
}

vr::EVROverlayError tr_ovw_SetOverlayTransformTrackedDeviceRelative(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::TrackedDeviceIndex_t unTrackedDevice, vr::HmdMatrix34_t * pmatTrackedDeviceToOverlayTransform){
    return self->SetOverlayTransformTrackedDeviceRelative(ulOverlayHandle, unTrackedDevice, pmatTrackedDeviceToOverlayTransform);
}

vr::EVROverlayError tr_ovw_GetOverlayTransformTrackedDeviceRelative(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::TrackedDeviceIndex_t * punTrackedDevice, vr::HmdMatrix34_t * pmatTrackedDeviceToOverlayTransform){
    return self->GetOverlayTransformTrackedDeviceRelative(ulOverlayHandle, punTrackedDevice, pmatTrackedDeviceToOverlayTransform);
}

vr::EVROverlayError tr_ovw_SetOverlayTransformTrackedDeviceComponent(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::TrackedDeviceIndex_t unDeviceIndex, char * pchComponentName){
    return self->SetOverlayTransformTrackedDeviceComponent(ulOverlayHandle, unDeviceIndex, pchComponentName);
}

vr::EVROverlayError tr_ovw_GetOverlayTransformTrackedDeviceComponent(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::TrackedDeviceIndex_t * punDeviceIndex, char * pchComponentName, uint32_t unComponentNameSize){
    return self->GetOverlayTransformTrackedDeviceComponent(ulOverlayHandle, punDeviceIndex, pchComponentName, unComponentNameSize);
}

vr::EVROverlayError tr_ovw_ShowOverlay(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle){
    return self->ShowOverlay(ulOverlayHandle);
}

vr::EVROverlayError tr_ovw_HideOverlay(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle){
    return self->HideOverlay(ulOverlayHandle);
}

bool tr_ovw_IsOverlayVisible(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle){
    return self->IsOverlayVisible(ulOverlayHandle);
}

vr::EVROverlayError tr_ovw_GetTransformForOverlayCoordinates(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::ETrackingUniverseOrigin eTrackingOrigin, vr::HmdVector2_t coordinatesInOverlay, vr::HmdMatrix34_t * pmatTransform){
    return self->GetTransformForOverlayCoordinates(ulOverlayHandle, eTrackingOrigin, coordinatesInOverlay, pmatTransform);
}

bool tr_ovw_PollNextOverlayEvent(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::VREvent_t * pEvent, uint32_t uncbVREvent){
    return self->PollNextOverlayEvent(ulOverlayHandle, pEvent, uncbVREvent);
}

vr::EVROverlayError tr_ovw_GetOverlayInputMethod(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::VROverlayInputMethod * peInputMethod){
    return self->GetOverlayInputMethod(ulOverlayHandle, peInputMethod);
}

vr::EVROverlayError tr_ovw_SetOverlayInputMethod(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::VROverlayInputMethod eInputMethod){
    return self->SetOverlayInputMethod(ulOverlayHandle, eInputMethod);
}

vr::EVROverlayError tr_ovw_GetOverlayMouseScale(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::HmdVector2_t * pvecMouseScale){
    return self->GetOverlayMouseScale(ulOverlayHandle, pvecMouseScale);
}

vr::EVROverlayError tr_ovw_SetOverlayMouseScale(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::HmdVector2_t * pvecMouseScale){
    return self->SetOverlayMouseScale(ulOverlayHandle, pvecMouseScale);
}

bool tr_ovw_ComputeOverlayIntersection(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::VROverlayIntersectionParams_t * pParams, vr::VROverlayIntersectionResults_t * pResults){
    return self->ComputeOverlayIntersection(ulOverlayHandle, pParams, pResults);
}

bool tr_ovw_HandleControllerOverlayInteractionAsMouse(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::TrackedDeviceIndex_t unControllerDeviceIndex){
    return self->HandleControllerOverlayInteractionAsMouse(ulOverlayHandle, unControllerDeviceIndex);
}

bool tr_ovw_IsHoverTargetOverlay(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle){
    return self->IsHoverTargetOverlay(ulOverlayHandle);
}

vr::VROverlayHandle_t tr_ovw_GetGamepadFocusOverlay(vr::IVROverlay* self){
    return self->GetGamepadFocusOverlay();
}

vr::EVROverlayError tr_ovw_SetGamepadFocusOverlay(vr::IVROverlay* self, vr::VROverlayHandle_t ulNewFocusOverlay){
    return self->SetGamepadFocusOverlay(ulNewFocusOverlay);
}

vr::EVROverlayError tr_ovw_SetOverlayNeighbor(vr::IVROverlay* self, vr::EOverlayDirection eDirection, vr::VROverlayHandle_t ulFrom, vr::VROverlayHandle_t ulTo){
    return self->SetOverlayNeighbor(eDirection, ulFrom, ulTo);
}

vr::EVROverlayError tr_ovw_MoveGamepadFocusToNeighbor(vr::IVROverlay* self, vr::EOverlayDirection eDirection, vr::VROverlayHandle_t ulFrom){
    return self->MoveGamepadFocusToNeighbor(eDirection, ulFrom);
}

vr::EVROverlayError tr_ovw_SetOverlayTexture(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::Texture_t * pTexture){
    return self->SetOverlayTexture(ulOverlayHandle, pTexture);
}

vr::EVROverlayError tr_ovw_ClearOverlayTexture(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle){
    return self->ClearOverlayTexture(ulOverlayHandle);
}

vr::EVROverlayError tr_ovw_SetOverlayRaw(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, void * pvBuffer, uint32_t unWidth, uint32_t unHeight, uint32_t unDepth){
    return self->SetOverlayRaw(ulOverlayHandle, pvBuffer, unWidth, unHeight, unDepth);
}

vr::EVROverlayError tr_ovw_SetOverlayFromFile(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, char * pchFilePath){
    return self->SetOverlayFromFile(ulOverlayHandle, pchFilePath);
}

vr::EVROverlayError tr_ovw_GetOverlayTexture(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, void ** pNativeTextureHandle, void * pNativeTextureRef, uint32_t * pWidth, uint32_t * pHeight, uint32_t * pNativeFormat, vr::EGraphicsAPIConvention * pAPI, vr::EColorSpace * pColorSpace){
    return self->GetOverlayTexture(ulOverlayHandle, pNativeTextureHandle, pNativeTextureRef, pWidth, pHeight, pNativeFormat, pAPI, pColorSpace);
}

vr::EVROverlayError tr_ovw_ReleaseNativeOverlayHandle(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, void * pNativeTextureHandle){
    return self->ReleaseNativeOverlayHandle(ulOverlayHandle, pNativeTextureHandle);
}

vr::EVROverlayError tr_ovw_CreateDashboardOverlay(vr::IVROverlay* self, char * pchOverlayKey, char * pchOverlayFriendlyName, vr::VROverlayHandle_t * pMainHandle, vr::VROverlayHandle_t * pThumbnailHandle){
    return self->CreateDashboardOverlay(pchOverlayKey, pchOverlayFriendlyName, pMainHandle, pThumbnailHandle);
}

bool tr_ovw_IsDashboardVisible(vr::IVROverlay* self){
    return self->IsDashboardVisible();
}

bool tr_ovw_IsActiveDashboardOverlay(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle){
    return self->IsActiveDashboardOverlay(ulOverlayHandle);
}

vr::EVROverlayError tr_ovw_SetDashboardOverlaySceneProcess(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, uint32_t unProcessId){
    return self->SetDashboardOverlaySceneProcess(ulOverlayHandle, unProcessId);
}

vr::EVROverlayError tr_ovw_GetDashboardOverlaySceneProcess(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, uint32_t * punProcessId){
    return self->GetDashboardOverlaySceneProcess(ulOverlayHandle, punProcessId);
}

void tr_ovw_ShowDashboard(vr::IVROverlay* self, char * pchOverlayToShow){
    self->ShowDashboard(pchOverlayToShow);
}

vr::TrackedDeviceIndex_t tr_ovw_GetPrimaryDashboardDevice(vr::IVROverlay* self){
    return self->GetPrimaryDashboardDevice();
}

vr::EVROverlayError tr_ovw_ShowKeyboard(vr::IVROverlay* self, vr::EGamepadTextInputMode eInputMode, vr::EGamepadTextInputLineMode eLineInputMode, char * pchDescription, uint32_t unCharMax, char * pchExistingText, bool bUseMinimalMode, uint64_t uUserValue){
    return self->ShowKeyboard(eInputMode, eLineInputMode, pchDescription, unCharMax, pchExistingText, bUseMinimalMode, uUserValue);
}

vr::EVROverlayError tr_ovw_ShowKeyboardForOverlay(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::EGamepadTextInputMode eInputMode, vr::EGamepadTextInputLineMode eLineInputMode, char * pchDescription, uint32_t unCharMax, char * pchExistingText, bool bUseMinimalMode, uint64_t uUserValue){
    return self->ShowKeyboardForOverlay(ulOverlayHandle, eInputMode, eLineInputMode, pchDescription, unCharMax, pchExistingText, bUseMinimalMode, uUserValue);
}

uint32_t tr_ovw_GetKeyboardText(vr::IVROverlay* self, char * pchText, uint32_t cchText){
    return self->GetKeyboardText(pchText, cchText);
}

void tr_ovw_HideKeyboard(vr::IVROverlay* self){
    self->HideKeyboard();
}

void tr_ovw_SetKeyboardTransformAbsolute(vr::IVROverlay* self, vr::ETrackingUniverseOrigin eTrackingOrigin, vr::HmdMatrix34_t * pmatTrackingOriginToKeyboardTransform){
    self->SetKeyboardTransformAbsolute(eTrackingOrigin, pmatTrackingOriginToKeyboardTransform);
}

void tr_ovw_SetKeyboardPositionForOverlay(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::HmdRect2_t avoidRect){
    self->SetKeyboardPositionForOverlay(ulOverlayHandle, avoidRect);
}

vr::EVRRenderModelError tr_ovw_LoadRenderModel_Async(vr::IVRRenderModels* self, char * pchRenderModelName, vr::RenderModel_t ** ppRenderModel){
    return self->LoadRenderModel_Async(pchRenderModelName, ppRenderModel);
}

void tr_ovw_FreeRenderModel(vr::IVRRenderModels* self, vr::RenderModel_t * pRenderModel){
    self->FreeRenderModel(pRenderModel);
}

vr::EVRRenderModelError tr_ovw_LoadTexture_Async(vr::IVRRenderModels* self, vr::TextureID_t textureId, vr::RenderModel_TextureMap_t ** ppTexture){
    return self->LoadTexture_Async(textureId, ppTexture);
}

void tr_ovw_FreeTexture(vr::IVRRenderModels* self, vr::RenderModel_TextureMap_t * pTexture){
    self->FreeTexture(pTexture);
}

vr::EVRRenderModelError tr_ovw_LoadTextureD3D11_Async(vr::IVRRenderModels* self, vr::TextureID_t textureId, void * pD3D11Device, void ** ppD3D11Texture2D){
    return self->LoadTextureD3D11_Async(textureId, pD3D11Device, ppD3D11Texture2D);
}

vr::EVRRenderModelError tr_ovw_LoadIntoTextureD3D11_Async(vr::IVRRenderModels* self, vr::TextureID_t textureId, void * pDstTexture){
    return self->LoadIntoTextureD3D11_Async(textureId, pDstTexture);
}

void tr_ovw_FreeTextureD3D11(vr::IVRRenderModels* self, void * pD3D11Texture2D){
    self->FreeTextureD3D11(pD3D11Texture2D);
}

uint32_t tr_ovw_GetRenderModelName(vr::IVRRenderModels* self, uint32_t unRenderModelIndex, char * pchRenderModelName, uint32_t unRenderModelNameLen){
    return self->GetRenderModelName(unRenderModelIndex, pchRenderModelName, unRenderModelNameLen);
}

uint32_t tr_ovw_GetRenderModelCount(vr::IVRRenderModels* self){
    return self->GetRenderModelCount();
}

uint32_t tr_ovw_GetComponentCount(vr::IVRRenderModels* self, char * pchRenderModelName){
    return self->GetComponentCount(pchRenderModelName);
}

uint32_t tr_ovw_GetComponentName(vr::IVRRenderModels* self, char * pchRenderModelName, uint32_t unComponentIndex, char * pchComponentName, uint32_t unComponentNameLen){
    return self->GetComponentName(pchRenderModelName, unComponentIndex, pchComponentName, unComponentNameLen);
}

uint64_t tr_ovw_GetComponentButtonMask(vr::IVRRenderModels* self, char * pchRenderModelName, char * pchComponentName){
    return self->GetComponentButtonMask(pchRenderModelName, pchComponentName);
}

uint32_t tr_ovw_GetComponentRenderModelName(vr::IVRRenderModels* self, char * pchRenderModelName, char * pchComponentName, char * pchComponentRenderModelName, uint32_t unComponentRenderModelNameLen){
    return self->GetComponentRenderModelName(pchRenderModelName, pchComponentName, pchComponentRenderModelName, unComponentRenderModelNameLen);
}

bool tr_ovw_GetComponentState(vr::IVRRenderModels* self, char * pchRenderModelName, char * pchComponentName, vr::VRControllerState_t * pControllerState, vr::RenderModel_ControllerMode_State_t * pState, vr::RenderModel_ComponentState_t * pComponentState){
    return self->GetComponentState(pchRenderModelName, pchComponentName, pControllerState, pState, pComponentState);
}

bool tr_ovw_RenderModelHasComponent(vr::IVRRenderModels* self, char * pchRenderModelName, char * pchComponentName){
    return self->RenderModelHasComponent(pchRenderModelName, pchComponentName);
}

vr::EVRNotificationError tr_ovw_CreateNotification(vr::IVRNotifications* self, vr::VROverlayHandle_t ulOverlayHandle, uint64_t ulUserValue, vr::EVRNotificationType type, char * pchText, vr::EVRNotificationStyle style, vr::NotificationBitmap_t * pImage, vr::VRNotificationId * pNotificationId){
    return self->CreateNotification(ulOverlayHandle, ulUserValue, type, pchText, style, pImage, pNotificationId);
}

vr::EVRNotificationError tr_ovw_RemoveNotification(vr::IVRNotifications* self, vr::VRNotificationId notificationId){
    return self->RemoveNotification(notificationId);
}

const char * tr_ovw_GetSettingsErrorNameFromEnum(vr::IVRSettings* self, vr::EVRSettingsError eError){
    return self->GetSettingsErrorNameFromEnum(eError);
}

bool tr_ovw_Sync(vr::IVRSettings* self, bool bForce, vr::EVRSettingsError * peError){
    return self->Sync(bForce, peError);
}

bool tr_ovw_GetBool(vr::IVRSettings* self, char * pchSection, char * pchSettingsKey, bool bDefaultValue, vr::EVRSettingsError * peError){
    return self->GetBool(pchSection, pchSettingsKey, bDefaultValue, peError);
}

void tr_ovw_SetBool(vr::IVRSettings* self, char * pchSection, char * pchSettingsKey, bool bValue, vr::EVRSettingsError * peError){
    self->SetBool(pchSection, pchSettingsKey, bValue, peError);
}

int32_t tr_ovw_GetInt32(vr::IVRSettings* self, char * pchSection, char * pchSettingsKey, int32_t nDefaultValue, vr::EVRSettingsError * peError){
    return self->GetInt32(pchSection, pchSettingsKey, nDefaultValue, peError);
}

void tr_ovw_SetInt32(vr::IVRSettings* self, char * pchSection, char * pchSettingsKey, int32_t nValue, vr::EVRSettingsError * peError){
    self->SetInt32(pchSection, pchSettingsKey, nValue, peError);
}

float tr_ovw_GetFloat(vr::IVRSettings* self, char * pchSection, char * pchSettingsKey, float flDefaultValue, vr::EVRSettingsError * peError){
    return self->GetFloat(pchSection, pchSettingsKey, flDefaultValue, peError);
}

void tr_ovw_SetFloat(vr::IVRSettings* self, char * pchSection, char * pchSettingsKey, float flValue, vr::EVRSettingsError * peError){
    self->SetFloat(pchSection, pchSettingsKey, flValue, peError);
}

void tr_ovw_GetString(vr::IVRSettings* self, char * pchSection, char * pchSettingsKey, char * pchValue, uint32_t unValueLen, char * pchDefaultValue, vr::EVRSettingsError * peError){
    self->GetString(pchSection, pchSettingsKey, pchValue, unValueLen, pchDefaultValue, peError);
}

void tr_ovw_SetString(vr::IVRSettings* self, char * pchSection, char * pchSettingsKey, char * pchValue, vr::EVRSettingsError * peError){
    self->SetString(pchSection, pchSettingsKey, pchValue, peError);
}

void tr_ovw_RemoveSection(vr::IVRSettings* self, char * pchSection, vr::EVRSettingsError * peError){
    self->RemoveSection(pchSection, peError);
}

void tr_ovw_RemoveKeyInSection(vr::IVRSettings* self, char * pchSection, char * pchSettingsKey, vr::EVRSettingsError * peError){
    self->RemoveKeyInSection(pchSection, pchSettingsKey, peError);
}
