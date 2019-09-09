#include "openvr_addon.h"

void tr_ovw_GetRecommendedRenderTargetSize(vr::IVRSystem* self, uint32_t * pnWidth, uint32_t * pnHeight) {
	self->GetRecommendedRenderTargetSize(pnWidth, pnHeight);
}

vr::HmdMatrix44_t tr_ovw_GetProjectionMatrix(vr::IVRSystem* self, vr::EVREye eEye, float fNearZ, float fFarZ) {
	return self->GetProjectionMatrix(eEye, fNearZ, fFarZ);
}

void tr_ovw_GetProjectionRaw(vr::IVRSystem* self, vr::EVREye eEye, float * pfLeft, float * pfRight, float * pfTop, float * pfBottom) {
	self->GetProjectionRaw(eEye, pfLeft, pfRight, pfTop, pfBottom);
}

bool tr_ovw_ComputeDistortion(vr::IVRSystem* self, vr::EVREye eEye, float fU, float fV, vr::DistortionCoordinates_t * pDistortionCoordinates) {
	return self->ComputeDistortion(eEye, fU, fV, pDistortionCoordinates);
}

vr::HmdMatrix34_t tr_ovw_GetEyeToHeadTransform(vr::IVRSystem* self, vr::EVREye eEye) {
	return self->GetEyeToHeadTransform(eEye);
}

bool tr_ovw_GetTimeSinceLastVsync(vr::IVRSystem* self, float * pfSecondsSinceLastVsync, uint64_t * pulFrameCounter) {
	return self->GetTimeSinceLastVsync(pfSecondsSinceLastVsync, pulFrameCounter);
}

int32_t tr_ovw_GetD3D9AdapterIndex(vr::IVRSystem* self) {
	return self->GetD3D9AdapterIndex();
}

void tr_ovw_GetDXGIOutputInfo(vr::IVRSystem* self, int32_t * pnAdapterIndex) {
	self->GetDXGIOutputInfo(pnAdapterIndex);
}

void tr_ovw_GetOutputDevice(vr::IVRSystem* self, uint64_t * pnDevice, vr::ETextureType textureType, VkInstance_T * pInstance) {
	self->GetOutputDevice(pnDevice, textureType, pInstance);
}

bool tr_ovw_IsDisplayOnDesktop(vr::IVRSystem* self) {
	return self->IsDisplayOnDesktop();
}

bool tr_ovw_SetDisplayVisibility(vr::IVRSystem* self, bool bIsVisibleOnDesktop) {
	return self->SetDisplayVisibility(bIsVisibleOnDesktop);
}

void tr_ovw_GetDeviceToAbsoluteTrackingPose(vr::IVRSystem* self, vr::ETrackingUniverseOrigin eOrigin, float fPredictedSecondsToPhotonsFromNow, vr::TrackedDevicePose_t * pTrackedDevicePoseArray, uint32_t unTrackedDevicePoseArrayCount) {
	self->GetDeviceToAbsoluteTrackingPose(eOrigin, fPredictedSecondsToPhotonsFromNow, pTrackedDevicePoseArray, unTrackedDevicePoseArrayCount);
}

void tr_ovw_ResetSeatedZeroPose(vr::IVRSystem* self) {
	self->ResetSeatedZeroPose();
}

vr::HmdMatrix34_t tr_ovw_GetSeatedZeroPoseToStandingAbsoluteTrackingPose(vr::IVRSystem* self) {
	return self->GetSeatedZeroPoseToStandingAbsoluteTrackingPose();
}

vr::HmdMatrix34_t tr_ovw_GetRawZeroPoseToStandingAbsoluteTrackingPose(vr::IVRSystem* self) {
	return self->GetRawZeroPoseToStandingAbsoluteTrackingPose();
}

uint32_t tr_ovw_GetSortedTrackedDeviceIndicesOfClass(vr::IVRSystem* self, vr::ETrackedDeviceClass eTrackedDeviceClass, vr::TrackedDeviceIndex_t * punTrackedDeviceIndexArray, uint32_t unTrackedDeviceIndexArrayCount, vr::TrackedDeviceIndex_t unRelativeToTrackedDeviceIndex) {
	return self->GetSortedTrackedDeviceIndicesOfClass(eTrackedDeviceClass, punTrackedDeviceIndexArray, unTrackedDeviceIndexArrayCount, unRelativeToTrackedDeviceIndex);
}

vr::EDeviceActivityLevel tr_ovw_GetTrackedDeviceActivityLevel(vr::IVRSystem* self, vr::TrackedDeviceIndex_t unDeviceId) {
	return self->GetTrackedDeviceActivityLevel(unDeviceId);
}

void tr_ovw_ApplyTransform(vr::IVRSystem* self, vr::TrackedDevicePose_t * pOutputPose, vr::TrackedDevicePose_t * pTrackedDevicePose, vr::HmdMatrix34_t * pTransform) {
	self->ApplyTransform(pOutputPose, pTrackedDevicePose, pTransform);
}

vr::TrackedDeviceIndex_t tr_ovw_GetTrackedDeviceIndexForControllerRole(vr::IVRSystem* self, vr::ETrackedControllerRole unDeviceType) {
	return self->GetTrackedDeviceIndexForControllerRole(unDeviceType);
}

vr::ETrackedControllerRole tr_ovw_GetControllerRoleForTrackedDeviceIndex(vr::IVRSystem* self, vr::TrackedDeviceIndex_t unDeviceIndex) {
	return self->GetControllerRoleForTrackedDeviceIndex(unDeviceIndex);
}

vr::ETrackedDeviceClass tr_ovw_GetTrackedDeviceClass(vr::IVRSystem* self, vr::TrackedDeviceIndex_t unDeviceIndex) {
	return self->GetTrackedDeviceClass(unDeviceIndex);
}

bool tr_ovw_IsTrackedDeviceConnected(vr::IVRSystem* self, vr::TrackedDeviceIndex_t unDeviceIndex) {
	return self->IsTrackedDeviceConnected(unDeviceIndex);
}

bool tr_ovw_GetBoolTrackedDeviceProperty(vr::IVRSystem* self, vr::TrackedDeviceIndex_t unDeviceIndex, vr::ETrackedDeviceProperty prop, vr::ETrackedPropertyError * pError) {
	return self->GetBoolTrackedDeviceProperty(unDeviceIndex, prop, pError);
}

float tr_ovw_GetFloatTrackedDeviceProperty(vr::IVRSystem* self, vr::TrackedDeviceIndex_t unDeviceIndex, vr::ETrackedDeviceProperty prop, vr::ETrackedPropertyError * pError) {
	return self->GetFloatTrackedDeviceProperty(unDeviceIndex, prop, pError);
}

int32_t tr_ovw_GetInt32TrackedDeviceProperty(vr::IVRSystem* self, vr::TrackedDeviceIndex_t unDeviceIndex, vr::ETrackedDeviceProperty prop, vr::ETrackedPropertyError * pError) {
	return self->GetInt32TrackedDeviceProperty(unDeviceIndex, prop, pError);
}

uint64_t tr_ovw_GetUint64TrackedDeviceProperty(vr::IVRSystem* self, vr::TrackedDeviceIndex_t unDeviceIndex, vr::ETrackedDeviceProperty prop, vr::ETrackedPropertyError * pError) {
	return self->GetUint64TrackedDeviceProperty(unDeviceIndex, prop, pError);
}

vr::HmdMatrix34_t tr_ovw_GetMatrix34TrackedDeviceProperty(vr::IVRSystem* self, vr::TrackedDeviceIndex_t unDeviceIndex, vr::ETrackedDeviceProperty prop, vr::ETrackedPropertyError * pError) {
	return self->GetMatrix34TrackedDeviceProperty(unDeviceIndex, prop, pError);
}

uint32_t tr_ovw_GetArrayTrackedDeviceProperty(vr::IVRSystem* self, vr::TrackedDeviceIndex_t unDeviceIndex, vr::ETrackedDeviceProperty prop, vr::PropertyTypeTag_t propType, void * pBuffer, uint32_t unBufferSize, vr::ETrackedPropertyError * pError) {
	return self->GetArrayTrackedDeviceProperty(unDeviceIndex, prop, propType, pBuffer, unBufferSize, pError);
}

uint32_t tr_ovw_GetStringTrackedDeviceProperty(vr::IVRSystem* self, vr::TrackedDeviceIndex_t unDeviceIndex, vr::ETrackedDeviceProperty prop, char * pchValue, uint32_t unBufferSize, vr::ETrackedPropertyError * pError) {
	return self->GetStringTrackedDeviceProperty(unDeviceIndex, prop, pchValue, unBufferSize, pError);
}

const char * tr_ovw_GetPropErrorNameFromEnum(vr::IVRSystem* self, vr::ETrackedPropertyError error) {
	return self->GetPropErrorNameFromEnum(error);
}

bool tr_ovw_PollNextEvent(vr::IVRSystem* self, vr::VREvent_t * pEvent, uint32_t uncbVREvent) {
	return self->PollNextEvent(pEvent, uncbVREvent);
}

bool tr_ovw_PollNextEventWithPose(vr::IVRSystem* self, vr::ETrackingUniverseOrigin eOrigin, vr::VREvent_t * pEvent, uint32_t uncbVREvent, vr::TrackedDevicePose_t * pTrackedDevicePose) {
	return self->PollNextEventWithPose(eOrigin, pEvent, uncbVREvent, pTrackedDevicePose);
}

const char * tr_ovw_GetEventTypeNameFromEnum(vr::IVRSystem* self, vr::EVREventType eType) {
	return self->GetEventTypeNameFromEnum(eType);
}

vr::HiddenAreaMesh_t tr_ovw_GetHiddenAreaMesh(vr::IVRSystem* self, vr::EVREye eEye, vr::EHiddenAreaMeshType type) {
	return self->GetHiddenAreaMesh(eEye, type);
}

bool tr_ovw_GetControllerState(vr::IVRSystem* self, vr::TrackedDeviceIndex_t unControllerDeviceIndex, vr::VRControllerState_t * pControllerState, uint32_t unControllerStateSize) {
	return self->GetControllerState(unControllerDeviceIndex, pControllerState, unControllerStateSize);
}

bool tr_ovw_GetControllerStateWithPose(vr::IVRSystem* self, vr::ETrackingUniverseOrigin eOrigin, vr::TrackedDeviceIndex_t unControllerDeviceIndex, vr::VRControllerState_t * pControllerState, uint32_t unControllerStateSize, vr::TrackedDevicePose_t * pTrackedDevicePose) {
	return self->GetControllerStateWithPose(eOrigin, unControllerDeviceIndex, pControllerState, unControllerStateSize, pTrackedDevicePose);
}

void tr_ovw_TriggerHapticPulse(vr::IVRSystem* self, vr::TrackedDeviceIndex_t unControllerDeviceIndex, uint32_t unAxisId, unsigned short usDurationMicroSec) {
	self->TriggerHapticPulse(unControllerDeviceIndex, unAxisId, usDurationMicroSec);
}

const char * tr_ovw_GetButtonIdNameFromEnum(vr::IVRSystem* self, vr::EVRButtonId eButtonId) {
	return self->GetButtonIdNameFromEnum(eButtonId);
}

const char * tr_ovw_GetControllerAxisTypeNameFromEnum(vr::IVRSystem* self, vr::EVRControllerAxisType eAxisType) {
	return self->GetControllerAxisTypeNameFromEnum(eAxisType);
}

bool tr_ovw_IsInputAvailable(vr::IVRSystem* self) {
	return self->IsInputAvailable();
}

bool tr_ovw_IsSteamVRDrawingControllers(vr::IVRSystem* self) {
	return self->IsSteamVRDrawingControllers();
}

bool tr_ovw_ShouldApplicationPause(vr::IVRSystem* self) {
	return self->ShouldApplicationPause();
}

bool tr_ovw_ShouldApplicationReduceRenderingWork(vr::IVRSystem* self) {
	return self->ShouldApplicationReduceRenderingWork();
}

vr::EVRFirmwareError tr_ovw_PerformFirmwareUpdate(vr::IVRSystem* self, vr::TrackedDeviceIndex_t unDeviceIndex) {
	return self->PerformFirmwareUpdate(unDeviceIndex);
}

void tr_ovw_AcknowledgeQuit_Exiting(vr::IVRSystem* self) {
	self->AcknowledgeQuit_Exiting();
}

void tr_ovw_AcknowledgeQuit_UserPrompt(vr::IVRSystem* self) {
	self->AcknowledgeQuit_UserPrompt();
}

uint32_t tr_ovw_GetAppContainerFilePaths(vr::IVRSystem* self, char * pchBuffer, uint32_t unBufferSize) {
	return self->GetAppContainerFilePaths(pchBuffer, unBufferSize);
}

const char * tr_ovw_GetRuntimeVersion(vr::IVRSystem* self) {
	return self->GetRuntimeVersion();
}

void tr_ovw_GetWindowBounds(vr::IVRExtendedDisplay* self, int32_t * pnX, int32_t * pnY, uint32_t * pnWidth, uint32_t * pnHeight) {
	self->GetWindowBounds(pnX, pnY, pnWidth, pnHeight);
}

void tr_ovw_GetEyeOutputViewport(vr::IVRExtendedDisplay* self, vr::EVREye eEye, uint32_t * pnX, uint32_t * pnY, uint32_t * pnWidth, uint32_t * pnHeight) {
	self->GetEyeOutputViewport(eEye, pnX, pnY, pnWidth, pnHeight);
}

/* C-API can't have overloaded functions (same function name exists under vr::IVRSystem)
void tr_ovw_GetDXGIOutputInfo(vr::IVRExtendedDisplay* self, int32_t * pnAdapterIndex, int32_t * pnAdapterOutputIndex) {
	self->GetDXGIOutputInfo(pnAdapterIndex, pnAdapterOutputIndex);
}
*/

const char * tr_ovw_GetCameraErrorNameFromEnum(vr::IVRTrackedCamera* self, vr::EVRTrackedCameraError eCameraError) {
	return self->GetCameraErrorNameFromEnum(eCameraError);
}

vr::EVRTrackedCameraError tr_ovw_HasCamera(vr::IVRTrackedCamera* self, vr::TrackedDeviceIndex_t nDeviceIndex, bool * pHasCamera) {
	return self->HasCamera(nDeviceIndex, pHasCamera);
}

vr::EVRTrackedCameraError tr_ovw_GetCameraFrameSize(vr::IVRTrackedCamera* self, vr::TrackedDeviceIndex_t nDeviceIndex, vr::EVRTrackedCameraFrameType eFrameType, uint32_t * pnWidth, uint32_t * pnHeight, uint32_t * pnFrameBufferSize) {
	return self->GetCameraFrameSize(nDeviceIndex, eFrameType, pnWidth, pnHeight, pnFrameBufferSize);
}

vr::EVRTrackedCameraError tr_ovw_GetCameraIntrinsics(vr::IVRTrackedCamera* self, vr::TrackedDeviceIndex_t nDeviceIndex, uint32_t nCameraIndex, vr::EVRTrackedCameraFrameType eFrameType, vr::HmdVector2_t * pFocalLength, vr::HmdVector2_t * pCenter) {
	return self->GetCameraIntrinsics(nDeviceIndex, nCameraIndex, eFrameType, pFocalLength, pCenter);
}

vr::EVRTrackedCameraError tr_ovw_GetCameraProjection(vr::IVRTrackedCamera* self, vr::TrackedDeviceIndex_t nDeviceIndex, uint32_t nCameraIndex, vr::EVRTrackedCameraFrameType eFrameType, float flZNear, float flZFar, vr::HmdMatrix44_t * pProjection) {
	return self->GetCameraProjection(nDeviceIndex, nCameraIndex, eFrameType, flZNear, flZFar, pProjection);
}

vr::EVRTrackedCameraError tr_ovw_AcquireVideoStreamingService(vr::IVRTrackedCamera* self, vr::TrackedDeviceIndex_t nDeviceIndex, vr::TrackedCameraHandle_t * pHandle) {
	return self->AcquireVideoStreamingService(nDeviceIndex, pHandle);
}

vr::EVRTrackedCameraError tr_ovw_ReleaseVideoStreamingService(vr::IVRTrackedCamera* self, vr::TrackedCameraHandle_t hTrackedCamera) {
	return self->ReleaseVideoStreamingService(hTrackedCamera);
}

vr::EVRTrackedCameraError tr_ovw_GetVideoStreamFrameBuffer(vr::IVRTrackedCamera* self, vr::TrackedCameraHandle_t hTrackedCamera, vr::EVRTrackedCameraFrameType eFrameType, void * pFrameBuffer, uint32_t nFrameBufferSize, vr::CameraVideoStreamFrameHeader_t * pFrameHeader, uint32_t nFrameHeaderSize) {
	return self->GetVideoStreamFrameBuffer(hTrackedCamera, eFrameType, pFrameBuffer, nFrameBufferSize, pFrameHeader, nFrameHeaderSize);
}

vr::EVRTrackedCameraError tr_ovw_GetVideoStreamTextureSize(vr::IVRTrackedCamera* self, vr::TrackedDeviceIndex_t nDeviceIndex, vr::EVRTrackedCameraFrameType eFrameType, vr::VRTextureBounds_t * pTextureBounds, uint32_t * pnWidth, uint32_t * pnHeight) {
	return self->GetVideoStreamTextureSize(nDeviceIndex, eFrameType, pTextureBounds, pnWidth, pnHeight);
}

vr::EVRTrackedCameraError tr_ovw_GetVideoStreamTextureD3D11(vr::IVRTrackedCamera* self, vr::TrackedCameraHandle_t hTrackedCamera, vr::EVRTrackedCameraFrameType eFrameType, void * pD3D11DeviceOrResource, void ** ppD3D11ShaderResourceView, vr::CameraVideoStreamFrameHeader_t * pFrameHeader, uint32_t nFrameHeaderSize) {
	return self->GetVideoStreamTextureD3D11(hTrackedCamera, eFrameType, pD3D11DeviceOrResource, ppD3D11ShaderResourceView, pFrameHeader, nFrameHeaderSize);
}

vr::EVRTrackedCameraError tr_ovw_GetVideoStreamTextureGL(vr::IVRTrackedCamera* self, vr::TrackedCameraHandle_t hTrackedCamera, vr::EVRTrackedCameraFrameType eFrameType, vr::glUInt_t * pglTextureId, vr::CameraVideoStreamFrameHeader_t * pFrameHeader, uint32_t nFrameHeaderSize) {
	return self->GetVideoStreamTextureGL(hTrackedCamera, eFrameType, pglTextureId, pFrameHeader, nFrameHeaderSize);
}

vr::EVRTrackedCameraError tr_ovw_ReleaseVideoStreamTextureGL(vr::IVRTrackedCamera* self, vr::TrackedCameraHandle_t hTrackedCamera, vr::glUInt_t glTextureId) {
	return self->ReleaseVideoStreamTextureGL(hTrackedCamera, glTextureId);
}

vr::EVRApplicationError tr_ovw_AddApplicationManifest(vr::IVRApplications* self, const char * pchApplicationManifestFullPath, bool bTemporary) {
	return self->AddApplicationManifest(pchApplicationManifestFullPath, bTemporary);
}

vr::EVRApplicationError tr_ovw_RemoveApplicationManifest(vr::IVRApplications* self, const char * pchApplicationManifestFullPath) {
	return self->RemoveApplicationManifest(pchApplicationManifestFullPath);
}

bool tr_ovw_IsApplicationInstalled(vr::IVRApplications* self, const char * pchAppKey) {
	return self->IsApplicationInstalled(pchAppKey);
}

uint32_t tr_ovw_GetApplicationCount(vr::IVRApplications* self) {
	return self->GetApplicationCount();
}

vr::EVRApplicationError tr_ovw_GetApplicationKeyByIndex(vr::IVRApplications* self, uint32_t unApplicationIndex, char * pchAppKeyBuffer, uint32_t unAppKeyBufferLen) {
	return self->GetApplicationKeyByIndex(unApplicationIndex, pchAppKeyBuffer, unAppKeyBufferLen);
}

vr::EVRApplicationError tr_ovw_GetApplicationKeyByProcessId(vr::IVRApplications* self, uint32_t unProcessId, char * pchAppKeyBuffer, uint32_t unAppKeyBufferLen) {
	return self->GetApplicationKeyByProcessId(unProcessId, pchAppKeyBuffer, unAppKeyBufferLen);
}

vr::EVRApplicationError tr_ovw_LaunchApplication(vr::IVRApplications* self, const char * pchAppKey) {
	return self->LaunchApplication(pchAppKey);
}

vr::EVRApplicationError tr_ovw_LaunchTemplateApplication(vr::IVRApplications* self, const char * pchTemplateAppKey, const char * pchNewAppKey, vr::AppOverrideKeys_t * pKeys, uint32_t unKeys) {
	return self->LaunchTemplateApplication(pchTemplateAppKey, pchNewAppKey, pKeys, unKeys);
}

vr::EVRApplicationError tr_ovw_LaunchApplicationFromMimeType(vr::IVRApplications* self, const char * pchMimeType, const char * pchArgs) {
	return self->LaunchApplicationFromMimeType(pchMimeType, pchArgs);
}

vr::EVRApplicationError tr_ovw_LaunchDashboardOverlay(vr::IVRApplications* self, const char * pchAppKey) {
	return self->LaunchDashboardOverlay(pchAppKey);
}

bool tr_ovw_CancelApplicationLaunch(vr::IVRApplications* self, const char * pchAppKey) {
	return self->CancelApplicationLaunch(pchAppKey);
}

vr::EVRApplicationError tr_ovw_IdentifyApplication(vr::IVRApplications* self, uint32_t unProcessId, const char * pchAppKey) {
	return self->IdentifyApplication(unProcessId, pchAppKey);
}

uint32_t tr_ovw_GetApplicationProcessId(vr::IVRApplications* self, const char * pchAppKey) {
	return self->GetApplicationProcessId(pchAppKey);
}

const char * tr_ovw_GetApplicationsErrorNameFromEnum(vr::IVRApplications* self, vr::EVRApplicationError error) {
	return self->GetApplicationsErrorNameFromEnum(error);
}

uint32_t tr_ovw_GetApplicationPropertyString(vr::IVRApplications* self, const char * pchAppKey, vr::EVRApplicationProperty eProperty, char * pchPropertyValueBuffer, uint32_t unPropertyValueBufferLen, vr::EVRApplicationError * peError) {
	return self->GetApplicationPropertyString(pchAppKey, eProperty, pchPropertyValueBuffer, unPropertyValueBufferLen, peError);
}

bool tr_ovw_GetApplicationPropertyBool(vr::IVRApplications* self, const char * pchAppKey, vr::EVRApplicationProperty eProperty, vr::EVRApplicationError * peError) {
	return self->GetApplicationPropertyBool(pchAppKey, eProperty, peError);
}

uint64_t tr_ovw_GetApplicationPropertyUint64(vr::IVRApplications* self, const char * pchAppKey, vr::EVRApplicationProperty eProperty, vr::EVRApplicationError * peError) {
	return self->GetApplicationPropertyUint64(pchAppKey, eProperty, peError);
}

vr::EVRApplicationError tr_ovw_SetApplicationAutoLaunch(vr::IVRApplications* self, const char * pchAppKey, bool bAutoLaunch) {
	return self->SetApplicationAutoLaunch(pchAppKey, bAutoLaunch);
}

bool tr_ovw_GetApplicationAutoLaunch(vr::IVRApplications* self, const char * pchAppKey) {
	return self->GetApplicationAutoLaunch(pchAppKey);
}

vr::EVRApplicationError tr_ovw_SetDefaultApplicationForMimeType(vr::IVRApplications* self, const char * pchAppKey, const char * pchMimeType) {
	return self->SetDefaultApplicationForMimeType(pchAppKey, pchMimeType);
}

bool tr_ovw_GetDefaultApplicationForMimeType(vr::IVRApplications* self, const char * pchMimeType, char * pchAppKeyBuffer, uint32_t unAppKeyBufferLen) {
	return self->GetDefaultApplicationForMimeType(pchMimeType, pchAppKeyBuffer, unAppKeyBufferLen);
}

bool tr_ovw_GetApplicationSupportedMimeTypes(vr::IVRApplications* self, const char * pchAppKey, char * pchMimeTypesBuffer, uint32_t unMimeTypesBuffer) {
	return self->GetApplicationSupportedMimeTypes(pchAppKey, pchMimeTypesBuffer, unMimeTypesBuffer);
}

uint32_t tr_ovw_GetApplicationsThatSupportMimeType(vr::IVRApplications* self, const char * pchMimeType, char * pchAppKeysThatSupportBuffer, uint32_t unAppKeysThatSupportBuffer) {
	return self->GetApplicationsThatSupportMimeType(pchMimeType, pchAppKeysThatSupportBuffer, unAppKeysThatSupportBuffer);
}

uint32_t tr_ovw_GetApplicationLaunchArguments(vr::IVRApplications* self, uint32_t unHandle, char * pchArgs, uint32_t unArgs) {
	return self->GetApplicationLaunchArguments(unHandle, pchArgs, unArgs);
}

vr::EVRApplicationError tr_ovw_GetStartingApplication(vr::IVRApplications* self, char * pchAppKeyBuffer, uint32_t unAppKeyBufferLen) {
	return self->GetStartingApplication(pchAppKeyBuffer, unAppKeyBufferLen);
}

vr::EVRApplicationTransitionState tr_ovw_GetTransitionState(vr::IVRApplications* self) {
	return self->GetTransitionState();
}

vr::EVRApplicationError tr_ovw_PerformApplicationPrelaunchCheck(vr::IVRApplications* self, const char * pchAppKey) {
	return self->PerformApplicationPrelaunchCheck(pchAppKey);
}

const char * tr_ovw_GetApplicationsTransitionStateNameFromEnum(vr::IVRApplications* self, vr::EVRApplicationTransitionState state) {
	return self->GetApplicationsTransitionStateNameFromEnum(state);
}

bool tr_ovw_IsQuitUserPromptRequested(vr::IVRApplications* self) {
	return self->IsQuitUserPromptRequested();
}

vr::EVRApplicationError tr_ovw_LaunchInternalProcess(vr::IVRApplications* self, const char * pchBinaryPath, const char * pchArguments, const char * pchWorkingDirectory) {
	return self->LaunchInternalProcess(pchBinaryPath, pchArguments, pchWorkingDirectory);
}

uint32_t tr_ovw_GetCurrentSceneProcessId(vr::IVRApplications* self) {
	return self->GetCurrentSceneProcessId();
}

vr::ChaperoneCalibrationState tr_ovw_GetCalibrationState(vr::IVRChaperone* self) {
	return self->GetCalibrationState();
}

bool tr_ovw_GetPlayAreaSize(vr::IVRChaperone* self, float * pSizeX, float * pSizeZ) {
	return self->GetPlayAreaSize(pSizeX, pSizeZ);
}

bool tr_ovw_GetPlayAreaRect(vr::IVRChaperone* self, vr::HmdQuad_t * rect) {
	return self->GetPlayAreaRect(rect);
}

void tr_ovw_ReloadInfo(vr::IVRChaperone* self) {
	self->ReloadInfo();
}

void tr_ovw_SetSceneColor(vr::IVRChaperone* self, vr::HmdColor_t color) {
	self->SetSceneColor(color);
}

void tr_ovw_GetBoundsColor(vr::IVRChaperone* self, vr::HmdColor_t * pOutputColorArray, int nNumOutputColors, float flCollisionBoundsFadeDistance, vr::HmdColor_t * pOutputCameraColor) {
	self->GetBoundsColor(pOutputColorArray, nNumOutputColors, flCollisionBoundsFadeDistance, pOutputCameraColor);
}

bool tr_ovw_AreBoundsVisible(vr::IVRChaperone* self) {
	return self->AreBoundsVisible();
}

void tr_ovw_ForceBoundsVisible(vr::IVRChaperone* self, bool bForce) {
	self->ForceBoundsVisible(bForce);
}

bool tr_ovw_CommitWorkingCopy(vr::IVRChaperoneSetup* self, vr::EChaperoneConfigFile configFile) {
	return self->CommitWorkingCopy(configFile);
}

void tr_ovw_RevertWorkingCopy(vr::IVRChaperoneSetup* self) {
	self->RevertWorkingCopy();
}

bool tr_ovw_GetWorkingPlayAreaSize(vr::IVRChaperoneSetup* self, float * pSizeX, float * pSizeZ) {
	return self->GetWorkingPlayAreaSize(pSizeX, pSizeZ);
}

bool tr_ovw_GetWorkingPlayAreaRect(vr::IVRChaperoneSetup* self, vr::HmdQuad_t * rect) {
	return self->GetWorkingPlayAreaRect(rect);
}

bool tr_ovw_GetWorkingCollisionBoundsInfo(vr::IVRChaperoneSetup* self, vr::HmdQuad_t * pQuadsBuffer, uint32_t * punQuadsCount) {
	return self->GetWorkingCollisionBoundsInfo(pQuadsBuffer, punQuadsCount);
}

bool tr_ovw_GetLiveCollisionBoundsInfo(vr::IVRChaperoneSetup* self, vr::HmdQuad_t * pQuadsBuffer, uint32_t * punQuadsCount) {
	return self->GetLiveCollisionBoundsInfo(pQuadsBuffer, punQuadsCount);
}

bool tr_ovw_GetWorkingSeatedZeroPoseToRawTrackingPose(vr::IVRChaperoneSetup* self, vr::HmdMatrix34_t * pmatSeatedZeroPoseToRawTrackingPose) {
	return self->GetWorkingSeatedZeroPoseToRawTrackingPose(pmatSeatedZeroPoseToRawTrackingPose);
}

bool tr_ovw_GetWorkingStandingZeroPoseToRawTrackingPose(vr::IVRChaperoneSetup* self, vr::HmdMatrix34_t * pmatStandingZeroPoseToRawTrackingPose) {
	return self->GetWorkingStandingZeroPoseToRawTrackingPose(pmatStandingZeroPoseToRawTrackingPose);
}

void tr_ovw_SetWorkingPlayAreaSize(vr::IVRChaperoneSetup* self, float sizeX, float sizeZ) {
	self->SetWorkingPlayAreaSize(sizeX, sizeZ);
}

void tr_ovw_SetWorkingCollisionBoundsInfo(vr::IVRChaperoneSetup* self, vr::HmdQuad_t * pQuadsBuffer, uint32_t unQuadsCount) {
	self->SetWorkingCollisionBoundsInfo(pQuadsBuffer, unQuadsCount);
}

void tr_ovw_SetWorkingPerimeter(vr::IVRChaperoneSetup* self, vr::HmdVector2_t * pPointBuffer, uint32_t unPointCount) {
	self->SetWorkingPerimeter(pPointBuffer, unPointCount);
}

void tr_ovw_SetWorkingSeatedZeroPoseToRawTrackingPose(vr::IVRChaperoneSetup* self, vr::HmdMatrix34_t * pMatSeatedZeroPoseToRawTrackingPose) {
	self->SetWorkingSeatedZeroPoseToRawTrackingPose(pMatSeatedZeroPoseToRawTrackingPose);
}

void tr_ovw_SetWorkingStandingZeroPoseToRawTrackingPose(vr::IVRChaperoneSetup* self, vr::HmdMatrix34_t * pMatStandingZeroPoseToRawTrackingPose) {
	self->SetWorkingStandingZeroPoseToRawTrackingPose(pMatStandingZeroPoseToRawTrackingPose);
}

void tr_ovw_ReloadFromDisk(vr::IVRChaperoneSetup* self, vr::EChaperoneConfigFile configFile) {
	self->ReloadFromDisk(configFile);
}

bool tr_ovw_GetLiveSeatedZeroPoseToRawTrackingPose(vr::IVRChaperoneSetup* self, vr::HmdMatrix34_t * pmatSeatedZeroPoseToRawTrackingPose) {
	return self->GetLiveSeatedZeroPoseToRawTrackingPose(pmatSeatedZeroPoseToRawTrackingPose);
}

bool tr_ovw_ExportLiveToBuffer(vr::IVRChaperoneSetup* self, char * pBuffer, uint32_t * pnBufferLength) {
	return self->ExportLiveToBuffer(pBuffer, pnBufferLength);
}

bool tr_ovw_ImportFromBufferToWorking(vr::IVRChaperoneSetup* self, const char * pBuffer, uint32_t nImportFlags) {
	return self->ImportFromBufferToWorking(pBuffer, nImportFlags);
}

void tr_ovw_ShowWorkingSetPreview(vr::IVRChaperoneSetup* self) {
	self->ShowWorkingSetPreview();
}

void tr_ovw_HideWorkingSetPreview(vr::IVRChaperoneSetup* self) {
	self->HideWorkingSetPreview();
}

void tr_ovw_RoomSetupStarting(vr::IVRChaperoneSetup* self) {
	self->RoomSetupStarting();
}

void tr_ovw_SetTrackingSpace(vr::IVRCompositor* self, vr::ETrackingUniverseOrigin eOrigin) {
	self->SetTrackingSpace(eOrigin);
}

vr::ETrackingUniverseOrigin tr_ovw_GetTrackingSpace(vr::IVRCompositor* self) {
	return self->GetTrackingSpace();
}

vr::EVRCompositorError tr_ovw_WaitGetPoses(vr::IVRCompositor* self, vr::TrackedDevicePose_t * pRenderPoseArray, uint32_t unRenderPoseArrayCount, vr::TrackedDevicePose_t * pGamePoseArray, uint32_t unGamePoseArrayCount) {
	return self->WaitGetPoses(pRenderPoseArray, unRenderPoseArrayCount, pGamePoseArray, unGamePoseArrayCount);
}

vr::EVRCompositorError tr_ovw_GetLastPoses(vr::IVRCompositor* self, vr::TrackedDevicePose_t * pRenderPoseArray, uint32_t unRenderPoseArrayCount, vr::TrackedDevicePose_t * pGamePoseArray, uint32_t unGamePoseArrayCount) {
	return self->GetLastPoses(pRenderPoseArray, unRenderPoseArrayCount, pGamePoseArray, unGamePoseArrayCount);
}

vr::EVRCompositorError tr_ovw_GetLastPoseForTrackedDeviceIndex(vr::IVRCompositor* self, vr::TrackedDeviceIndex_t unDeviceIndex, vr::TrackedDevicePose_t * pOutputPose, vr::TrackedDevicePose_t * pOutputGamePose) {
	return self->GetLastPoseForTrackedDeviceIndex(unDeviceIndex, pOutputPose, pOutputGamePose);
}

vr::EVRCompositorError tr_ovw_Submit(vr::IVRCompositor* self, vr::EVREye eEye, vr::Texture_t * pTexture, vr::VRTextureBounds_t * pBounds, vr::EVRSubmitFlags nSubmitFlags) {
	return self->Submit(eEye, pTexture, pBounds, nSubmitFlags);
}

void tr_ovw_ClearLastSubmittedFrame(vr::IVRCompositor* self) {
	self->ClearLastSubmittedFrame();
}

void tr_ovw_PostPresentHandoff(vr::IVRCompositor* self) {
	self->PostPresentHandoff();
}

bool tr_ovw_GetFrameTiming(vr::IVRCompositor* self, vr::Compositor_FrameTiming * pTiming, uint32_t unFramesAgo) {
	return self->GetFrameTiming(pTiming, unFramesAgo);
}

uint32_t tr_ovw_GetFrameTimings(vr::IVRCompositor* self, vr::Compositor_FrameTiming * pTiming, uint32_t nFrames) {
	return self->GetFrameTimings(pTiming, nFrames);
}

float tr_ovw_GetFrameTimeRemaining(vr::IVRCompositor* self) {
	return self->GetFrameTimeRemaining();
}

void tr_ovw_GetCumulativeStats(vr::IVRCompositor* self, vr::Compositor_CumulativeStats * pStats, uint32_t nStatsSizeInBytes) {
	self->GetCumulativeStats(pStats, nStatsSizeInBytes);
}

void tr_ovw_FadeToColor(vr::IVRCompositor* self, float fSeconds, float fRed, float fGreen, float fBlue, float fAlpha, bool bBackground) {
	self->FadeToColor(fSeconds, fRed, fGreen, fBlue, fAlpha, bBackground);
}

vr::HmdColor_t tr_ovw_GetCurrentFadeColor(vr::IVRCompositor* self, bool bBackground) {
	return self->GetCurrentFadeColor(bBackground);
}

void tr_ovw_FadeGrid(vr::IVRCompositor* self, float fSeconds, bool bFadeIn) {
	self->FadeGrid(fSeconds, bFadeIn);
}

float tr_ovw_GetCurrentGridAlpha(vr::IVRCompositor* self) {
	return self->GetCurrentGridAlpha();
}

vr::EVRCompositorError tr_ovw_SetSkyboxOverride(vr::IVRCompositor* self, vr::Texture_t * pTextures, uint32_t unTextureCount) {
	return self->SetSkyboxOverride(pTextures, unTextureCount);
}

void tr_ovw_ClearSkyboxOverride(vr::IVRCompositor* self) {
	self->ClearSkyboxOverride();
}

void tr_ovw_CompositorBringToFront(vr::IVRCompositor* self) {
	self->CompositorBringToFront();
}

void tr_ovw_CompositorGoToBack(vr::IVRCompositor* self) {
	self->CompositorGoToBack();
}

void tr_ovw_CompositorQuit(vr::IVRCompositor* self) {
	self->CompositorQuit();
}

bool tr_ovw_IsFullscreen(vr::IVRCompositor* self) {
	return self->IsFullscreen();
}

uint32_t tr_ovw_GetCurrentSceneFocusProcess(vr::IVRCompositor* self) {
	return self->GetCurrentSceneFocusProcess();
}

uint32_t tr_ovw_GetLastFrameRenderer(vr::IVRCompositor* self) {
	return self->GetLastFrameRenderer();
}

bool tr_ovw_CanRenderScene(vr::IVRCompositor* self) {
	return self->CanRenderScene();
}

void tr_ovw_ShowMirrorWindow(vr::IVRCompositor* self) {
	self->ShowMirrorWindow();
}

void tr_ovw_HideMirrorWindow(vr::IVRCompositor* self) {
	self->HideMirrorWindow();
}

bool tr_ovw_IsMirrorWindowVisible(vr::IVRCompositor* self) {
	return self->IsMirrorWindowVisible();
}

void tr_ovw_CompositorDumpImages(vr::IVRCompositor* self) {
	self->CompositorDumpImages();
}

bool tr_ovw_ShouldAppRenderWithLowResources(vr::IVRCompositor* self) {
	return self->ShouldAppRenderWithLowResources();
}

void tr_ovw_ForceInterleavedReprojectionOn(vr::IVRCompositor* self, bool bOverride) {
	self->ForceInterleavedReprojectionOn(bOverride);
}

void tr_ovw_ForceReconnectProcess(vr::IVRCompositor* self) {
	self->ForceReconnectProcess();
}

void tr_ovw_SuspendRendering(vr::IVRCompositor* self, bool bSuspend) {
	self->SuspendRendering(bSuspend);
}

vr::EVRCompositorError tr_ovw_GetMirrorTextureD3D11(vr::IVRCompositor* self, vr::EVREye eEye, void * pD3D11DeviceOrResource, void ** ppD3D11ShaderResourceView) {
	return self->GetMirrorTextureD3D11(eEye, pD3D11DeviceOrResource, ppD3D11ShaderResourceView);
}

void tr_ovw_ReleaseMirrorTextureD3D11(vr::IVRCompositor* self, void * pD3D11ShaderResourceView) {
	self->ReleaseMirrorTextureD3D11(pD3D11ShaderResourceView);
}

vr::EVRCompositorError tr_ovw_GetMirrorTextureGL(vr::IVRCompositor* self, vr::EVREye eEye, vr::glUInt_t * pglTextureId, vr::glSharedTextureHandle_t * pglSharedTextureHandle) {
	return self->GetMirrorTextureGL(eEye, pglTextureId, pglSharedTextureHandle);
}

bool tr_ovw_ReleaseSharedGLTexture(vr::IVRCompositor* self, vr::glUInt_t glTextureId, vr::glSharedTextureHandle_t glSharedTextureHandle) {
	return self->ReleaseSharedGLTexture(glTextureId, glSharedTextureHandle);
}

void tr_ovw_LockGLSharedTextureForAccess(vr::IVRCompositor* self, vr::glSharedTextureHandle_t glSharedTextureHandle) {
	self->LockGLSharedTextureForAccess(glSharedTextureHandle);
}

void tr_ovw_UnlockGLSharedTextureForAccess(vr::IVRCompositor* self, vr::glSharedTextureHandle_t glSharedTextureHandle) {
	self->UnlockGLSharedTextureForAccess(glSharedTextureHandle);
}

uint32_t tr_ovw_GetVulkanInstanceExtensionsRequired(vr::IVRCompositor* self, char * pchValue, uint32_t unBufferSize) {
	return self->GetVulkanInstanceExtensionsRequired(pchValue, unBufferSize);
}

uint32_t tr_ovw_GetVulkanDeviceExtensionsRequired(vr::IVRCompositor* self, VkPhysicalDevice_T * pPhysicalDevice, char * pchValue, uint32_t unBufferSize) {
	return self->GetVulkanDeviceExtensionsRequired(pPhysicalDevice, pchValue, unBufferSize);
}

void tr_ovw_SetExplicitTimingMode(vr::IVRCompositor* self, vr::EVRCompositorTimingMode eTimingMode) {
	self->SetExplicitTimingMode(eTimingMode);
}

vr::EVRCompositorError tr_ovw_SubmitExplicitTimingData(vr::IVRCompositor* self) {
	return self->SubmitExplicitTimingData();
}

bool tr_ovw_IsMotionSmoothingEnabled(vr::IVRCompositor* self) {
	return self->IsMotionSmoothingEnabled();
}

bool tr_ovw_IsMotionSmoothingSupported(vr::IVRCompositor* self) {
	return self->IsMotionSmoothingSupported();
}

bool tr_ovw_IsCurrentSceneFocusAppLoading(vr::IVRCompositor* self) {
	return self->IsCurrentSceneFocusAppLoading();
}

vr::EVROverlayError tr_ovw_FindOverlay(vr::IVROverlay* self, const char * pchOverlayKey, vr::VROverlayHandle_t * pOverlayHandle) {
	return self->FindOverlay(pchOverlayKey, pOverlayHandle);
}

vr::EVROverlayError tr_ovw_CreateOverlay(vr::IVROverlay* self, const char * pchOverlayKey, const char * pchOverlayName, vr::VROverlayHandle_t * pOverlayHandle) {
	return self->CreateOverlay(pchOverlayKey, pchOverlayName, pOverlayHandle);
}

vr::EVROverlayError tr_ovw_DestroyOverlay(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle) {
	return self->DestroyOverlay(ulOverlayHandle);
}

vr::EVROverlayError tr_ovw_SetHighQualityOverlay(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle) {
	return self->SetHighQualityOverlay(ulOverlayHandle);
}

vr::VROverlayHandle_t tr_ovw_GetHighQualityOverlay(vr::IVROverlay* self) {
	return self->GetHighQualityOverlay();
}

uint32_t tr_ovw_GetOverlayKey(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, char * pchValue, uint32_t unBufferSize, vr::EVROverlayError * pError) {
	return self->GetOverlayKey(ulOverlayHandle, pchValue, unBufferSize, pError);
}

uint32_t tr_ovw_GetOverlayName(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, char * pchValue, uint32_t unBufferSize, vr::EVROverlayError * pError) {
	return self->GetOverlayName(ulOverlayHandle, pchValue, unBufferSize, pError);
}

vr::EVROverlayError tr_ovw_SetOverlayName(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, const char * pchName) {
	return self->SetOverlayName(ulOverlayHandle, pchName);
}

vr::EVROverlayError tr_ovw_GetOverlayImageData(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, void * pvBuffer, uint32_t unBufferSize, uint32_t * punWidth, uint32_t * punHeight) {
	return self->GetOverlayImageData(ulOverlayHandle, pvBuffer, unBufferSize, punWidth, punHeight);
}

const char * tr_ovw_GetOverlayErrorNameFromEnum(vr::IVROverlay* self, vr::EVROverlayError error) {
	return self->GetOverlayErrorNameFromEnum(error);
}

vr::EVROverlayError tr_ovw_SetOverlayRenderingPid(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, uint32_t unPID) {
	return self->SetOverlayRenderingPid(ulOverlayHandle, unPID);
}

uint32_t tr_ovw_GetOverlayRenderingPid(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle) {
	return self->GetOverlayRenderingPid(ulOverlayHandle);
}

vr::EVROverlayError tr_ovw_SetOverlayFlag(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::VROverlayFlags eOverlayFlag, bool bEnabled) {
	return self->SetOverlayFlag(ulOverlayHandle, eOverlayFlag, bEnabled);
}

vr::EVROverlayError tr_ovw_GetOverlayFlag(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::VROverlayFlags eOverlayFlag, bool * pbEnabled) {
	return self->GetOverlayFlag(ulOverlayHandle, eOverlayFlag, pbEnabled);
}

vr::EVROverlayError tr_ovw_SetOverlayColor(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, float fRed, float fGreen, float fBlue) {
	return self->SetOverlayColor(ulOverlayHandle, fRed, fGreen, fBlue);
}

vr::EVROverlayError tr_ovw_GetOverlayColor(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, float * pfRed, float * pfGreen, float * pfBlue) {
	return self->GetOverlayColor(ulOverlayHandle, pfRed, pfGreen, pfBlue);
}

vr::EVROverlayError tr_ovw_SetOverlayAlpha(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, float fAlpha) {
	return self->SetOverlayAlpha(ulOverlayHandle, fAlpha);
}

vr::EVROverlayError tr_ovw_GetOverlayAlpha(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, float * pfAlpha) {
	return self->GetOverlayAlpha(ulOverlayHandle, pfAlpha);
}

vr::EVROverlayError tr_ovw_SetOverlayTexelAspect(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, float fTexelAspect) {
	return self->SetOverlayTexelAspect(ulOverlayHandle, fTexelAspect);
}

vr::EVROverlayError tr_ovw_GetOverlayTexelAspect(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, float * pfTexelAspect) {
	return self->GetOverlayTexelAspect(ulOverlayHandle, pfTexelAspect);
}

vr::EVROverlayError tr_ovw_SetOverlaySortOrder(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, uint32_t unSortOrder) {
	return self->SetOverlaySortOrder(ulOverlayHandle, unSortOrder);
}

vr::EVROverlayError tr_ovw_GetOverlaySortOrder(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, uint32_t * punSortOrder) {
	return self->GetOverlaySortOrder(ulOverlayHandle, punSortOrder);
}

vr::EVROverlayError tr_ovw_SetOverlayWidthInMeters(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, float fWidthInMeters) {
	return self->SetOverlayWidthInMeters(ulOverlayHandle, fWidthInMeters);
}

vr::EVROverlayError tr_ovw_GetOverlayWidthInMeters(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, float * pfWidthInMeters) {
	return self->GetOverlayWidthInMeters(ulOverlayHandle, pfWidthInMeters);
}

vr::EVROverlayError tr_ovw_SetOverlayAutoCurveDistanceRangeInMeters(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, float fMinDistanceInMeters, float fMaxDistanceInMeters) {
	return self->SetOverlayAutoCurveDistanceRangeInMeters(ulOverlayHandle, fMinDistanceInMeters, fMaxDistanceInMeters);
}

vr::EVROverlayError tr_ovw_GetOverlayAutoCurveDistanceRangeInMeters(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, float * pfMinDistanceInMeters, float * pfMaxDistanceInMeters) {
	return self->GetOverlayAutoCurveDistanceRangeInMeters(ulOverlayHandle, pfMinDistanceInMeters, pfMaxDistanceInMeters);
}

vr::EVROverlayError tr_ovw_SetOverlayTextureColorSpace(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::EColorSpace eTextureColorSpace) {
	return self->SetOverlayTextureColorSpace(ulOverlayHandle, eTextureColorSpace);
}

vr::EVROverlayError tr_ovw_GetOverlayTextureColorSpace(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::EColorSpace * peTextureColorSpace) {
	return self->GetOverlayTextureColorSpace(ulOverlayHandle, peTextureColorSpace);
}

vr::EVROverlayError tr_ovw_SetOverlayTextureBounds(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::VRTextureBounds_t * pOverlayTextureBounds) {
	return self->SetOverlayTextureBounds(ulOverlayHandle, pOverlayTextureBounds);
}

vr::EVROverlayError tr_ovw_GetOverlayTextureBounds(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::VRTextureBounds_t * pOverlayTextureBounds) {
	return self->GetOverlayTextureBounds(ulOverlayHandle, pOverlayTextureBounds);
}

uint32_t tr_ovw_GetOverlayRenderModel(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, char * pchValue, uint32_t unBufferSize, vr::HmdColor_t * pColor, vr::EVROverlayError * pError) {
	return self->GetOverlayRenderModel(ulOverlayHandle, pchValue, unBufferSize, pColor, pError);
}

vr::EVROverlayError tr_ovw_SetOverlayRenderModel(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, const char * pchRenderModel, vr::HmdColor_t * pColor) {
	return self->SetOverlayRenderModel(ulOverlayHandle, pchRenderModel, pColor);
}

vr::EVROverlayError tr_ovw_GetOverlayTransformType(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::VROverlayTransformType * peTransformType) {
	return self->GetOverlayTransformType(ulOverlayHandle, peTransformType);
}

vr::EVROverlayError tr_ovw_SetOverlayTransformAbsolute(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::ETrackingUniverseOrigin eTrackingOrigin, vr::HmdMatrix34_t * pmatTrackingOriginToOverlayTransform) {
	return self->SetOverlayTransformAbsolute(ulOverlayHandle, eTrackingOrigin, pmatTrackingOriginToOverlayTransform);
}

vr::EVROverlayError tr_ovw_GetOverlayTransformAbsolute(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::ETrackingUniverseOrigin * peTrackingOrigin, vr::HmdMatrix34_t * pmatTrackingOriginToOverlayTransform) {
	return self->GetOverlayTransformAbsolute(ulOverlayHandle, peTrackingOrigin, pmatTrackingOriginToOverlayTransform);
}

vr::EVROverlayError tr_ovw_SetOverlayTransformTrackedDeviceRelative(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::TrackedDeviceIndex_t unTrackedDevice, vr::HmdMatrix34_t * pmatTrackedDeviceToOverlayTransform) {
	return self->SetOverlayTransformTrackedDeviceRelative(ulOverlayHandle, unTrackedDevice, pmatTrackedDeviceToOverlayTransform);
}

vr::EVROverlayError tr_ovw_GetOverlayTransformTrackedDeviceRelative(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::TrackedDeviceIndex_t * punTrackedDevice, vr::HmdMatrix34_t * pmatTrackedDeviceToOverlayTransform) {
	return self->GetOverlayTransformTrackedDeviceRelative(ulOverlayHandle, punTrackedDevice, pmatTrackedDeviceToOverlayTransform);
}

vr::EVROverlayError tr_ovw_SetOverlayTransformTrackedDeviceComponent(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::TrackedDeviceIndex_t unDeviceIndex, const char * pchComponentName) {
	return self->SetOverlayTransformTrackedDeviceComponent(ulOverlayHandle, unDeviceIndex, pchComponentName);
}

vr::EVROverlayError tr_ovw_GetOverlayTransformTrackedDeviceComponent(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::TrackedDeviceIndex_t * punDeviceIndex, char * pchComponentName, uint32_t unComponentNameSize) {
	return self->GetOverlayTransformTrackedDeviceComponent(ulOverlayHandle, punDeviceIndex, pchComponentName, unComponentNameSize);
}

vr::EVROverlayError tr_ovw_GetOverlayTransformOverlayRelative(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::VROverlayHandle_t * ulOverlayHandleParent, vr::HmdMatrix34_t * pmatParentOverlayToOverlayTransform) {
	return self->GetOverlayTransformOverlayRelative(ulOverlayHandle, ulOverlayHandleParent, pmatParentOverlayToOverlayTransform);
}

vr::EVROverlayError tr_ovw_SetOverlayTransformOverlayRelative(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::VROverlayHandle_t ulOverlayHandleParent, vr::HmdMatrix34_t * pmatParentOverlayToOverlayTransform) {
	return self->SetOverlayTransformOverlayRelative(ulOverlayHandle, ulOverlayHandleParent, pmatParentOverlayToOverlayTransform);
}

vr::EVROverlayError tr_ovw_ShowOverlay(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle) {
	return self->ShowOverlay(ulOverlayHandle);
}

vr::EVROverlayError tr_ovw_HideOverlay(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle) {
	return self->HideOverlay(ulOverlayHandle);
}

bool tr_ovw_IsOverlayVisible(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle) {
	return self->IsOverlayVisible(ulOverlayHandle);
}

vr::EVROverlayError tr_ovw_GetTransformForOverlayCoordinates(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::ETrackingUniverseOrigin eTrackingOrigin, vr::HmdVector2_t coordinatesInOverlay, vr::HmdMatrix34_t * pmatTransform) {
	return self->GetTransformForOverlayCoordinates(ulOverlayHandle, eTrackingOrigin, coordinatesInOverlay, pmatTransform);
}

bool tr_ovw_PollNextOverlayEvent(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::VREvent_t * pEvent, uint32_t uncbVREvent) {
	return self->PollNextOverlayEvent(ulOverlayHandle, pEvent, uncbVREvent);
}

vr::EVROverlayError tr_ovw_GetOverlayInputMethod(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::VROverlayInputMethod * peInputMethod) {
	return self->GetOverlayInputMethod(ulOverlayHandle, peInputMethod);
}

vr::EVROverlayError tr_ovw_SetOverlayInputMethod(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::VROverlayInputMethod eInputMethod) {
	return self->SetOverlayInputMethod(ulOverlayHandle, eInputMethod);
}

vr::EVROverlayError tr_ovw_GetOverlayMouseScale(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::HmdVector2_t * pvecMouseScale) {
	return self->GetOverlayMouseScale(ulOverlayHandle, pvecMouseScale);
}

vr::EVROverlayError tr_ovw_SetOverlayMouseScale(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::HmdVector2_t * pvecMouseScale) {
	return self->SetOverlayMouseScale(ulOverlayHandle, pvecMouseScale);
}

bool tr_ovw_ComputeOverlayIntersection(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::VROverlayIntersectionParams_t * pParams, vr::VROverlayIntersectionResults_t * pResults) {
	return self->ComputeOverlayIntersection(ulOverlayHandle, pParams, pResults);
}

bool tr_ovw_IsHoverTargetOverlay(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle) {
	return self->IsHoverTargetOverlay(ulOverlayHandle);
}

vr::VROverlayHandle_t tr_ovw_GetGamepadFocusOverlay(vr::IVROverlay* self) {
	return self->GetGamepadFocusOverlay();
}

vr::EVROverlayError tr_ovw_SetGamepadFocusOverlay(vr::IVROverlay* self, vr::VROverlayHandle_t ulNewFocusOverlay) {
	return self->SetGamepadFocusOverlay(ulNewFocusOverlay);
}

vr::EVROverlayError tr_ovw_SetOverlayNeighbor(vr::IVROverlay* self, vr::EOverlayDirection eDirection, vr::VROverlayHandle_t ulFrom, vr::VROverlayHandle_t ulTo) {
	return self->SetOverlayNeighbor(eDirection, ulFrom, ulTo);
}

vr::EVROverlayError tr_ovw_MoveGamepadFocusToNeighbor(vr::IVROverlay* self, vr::EOverlayDirection eDirection, vr::VROverlayHandle_t ulFrom) {
	return self->MoveGamepadFocusToNeighbor(eDirection, ulFrom);
}

vr::EVROverlayError tr_ovw_SetOverlayDualAnalogTransform(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlay, vr::EDualAnalogWhich eWhich, vr::HmdVector2_t * pvCenter, float fRadius) {
	return self->SetOverlayDualAnalogTransform(ulOverlay, eWhich, pvCenter, fRadius);
}

vr::EVROverlayError tr_ovw_GetOverlayDualAnalogTransform(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlay, vr::EDualAnalogWhich eWhich, vr::HmdVector2_t * pvCenter, float * pfRadius) {
	return self->GetOverlayDualAnalogTransform(ulOverlay, eWhich, pvCenter, pfRadius);
}

vr::EVROverlayError tr_ovw_SetOverlayTexture(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::Texture_t * pTexture) {
	return self->SetOverlayTexture(ulOverlayHandle, pTexture);
}

vr::EVROverlayError tr_ovw_ClearOverlayTexture(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle) {
	return self->ClearOverlayTexture(ulOverlayHandle);
}

vr::EVROverlayError tr_ovw_SetOverlayRaw(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, void * pvBuffer, uint32_t unWidth, uint32_t unHeight, uint32_t unDepth) {
	return self->SetOverlayRaw(ulOverlayHandle, pvBuffer, unWidth, unHeight, unDepth);
}

vr::EVROverlayError tr_ovw_SetOverlayFromFile(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, const char * pchFilePath) {
	return self->SetOverlayFromFile(ulOverlayHandle, pchFilePath);
}

vr::EVROverlayError tr_ovw_GetOverlayTexture(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, void ** pNativeTextureHandle, void * pNativeTextureRef, uint32_t * pWidth, uint32_t * pHeight, uint32_t * pNativeFormat, vr::ETextureType * pAPIType, vr::EColorSpace * pColorSpace, vr::VRTextureBounds_t * pTextureBounds) {
	return self->GetOverlayTexture(ulOverlayHandle, pNativeTextureHandle, pNativeTextureRef, pWidth, pHeight, pNativeFormat, pAPIType, pColorSpace, pTextureBounds);
}

vr::EVROverlayError tr_ovw_ReleaseNativeOverlayHandle(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, void * pNativeTextureHandle) {
	return self->ReleaseNativeOverlayHandle(ulOverlayHandle, pNativeTextureHandle);
}

vr::EVROverlayError tr_ovw_GetOverlayTextureSize(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, uint32_t * pWidth, uint32_t * pHeight) {
	return self->GetOverlayTextureSize(ulOverlayHandle, pWidth, pHeight);
}

vr::EVROverlayError tr_ovw_CreateDashboardOverlay(vr::IVROverlay* self, const char * pchOverlayKey, const char * pchOverlayFriendlyName, vr::VROverlayHandle_t * pMainHandle, vr::VROverlayHandle_t * pThumbnailHandle) {
	return self->CreateDashboardOverlay(pchOverlayKey, pchOverlayFriendlyName, pMainHandle, pThumbnailHandle);
}

bool tr_ovw_IsDashboardVisible(vr::IVROverlay* self) {
	return self->IsDashboardVisible();
}

bool tr_ovw_IsActiveDashboardOverlay(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle) {
	return self->IsActiveDashboardOverlay(ulOverlayHandle);
}

vr::EVROverlayError tr_ovw_SetDashboardOverlaySceneProcess(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, uint32_t unProcessId) {
	return self->SetDashboardOverlaySceneProcess(ulOverlayHandle, unProcessId);
}

vr::EVROverlayError tr_ovw_GetDashboardOverlaySceneProcess(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, uint32_t * punProcessId) {
	return self->GetDashboardOverlaySceneProcess(ulOverlayHandle, punProcessId);
}

void tr_ovw_ShowDashboard(vr::IVROverlay* self, const char * pchOverlayToShow) {
	self->ShowDashboard(pchOverlayToShow);
}

vr::TrackedDeviceIndex_t tr_ovw_GetPrimaryDashboardDevice(vr::IVROverlay* self) {
	return self->GetPrimaryDashboardDevice();
}

vr::EVROverlayError tr_ovw_ShowKeyboard(vr::IVROverlay* self, vr::EGamepadTextInputMode eInputMode, vr::EGamepadTextInputLineMode eLineInputMode, const char * pchDescription, uint32_t unCharMax, const char * pchExistingText, bool bUseMinimalMode, uint64_t uUserValue) {
	return self->ShowKeyboard(eInputMode, eLineInputMode, pchDescription, unCharMax, pchExistingText, bUseMinimalMode, uUserValue);
}

vr::EVROverlayError tr_ovw_ShowKeyboardForOverlay(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::EGamepadTextInputMode eInputMode, vr::EGamepadTextInputLineMode eLineInputMode, const char * pchDescription, uint32_t unCharMax, const char * pchExistingText, bool bUseMinimalMode, uint64_t uUserValue) {
	return self->ShowKeyboardForOverlay(ulOverlayHandle, eInputMode, eLineInputMode, pchDescription, unCharMax, pchExistingText, bUseMinimalMode, uUserValue);
}

uint32_t tr_ovw_GetKeyboardText(vr::IVROverlay* self, char * pchText, uint32_t cchText) {
	return self->GetKeyboardText(pchText, cchText);
}

void tr_ovw_HideKeyboard(vr::IVROverlay* self) {
	self->HideKeyboard();
}

void tr_ovw_SetKeyboardTransformAbsolute(vr::IVROverlay* self, vr::ETrackingUniverseOrigin eTrackingOrigin, vr::HmdMatrix34_t * pmatTrackingOriginToKeyboardTransform) {
	self->SetKeyboardTransformAbsolute(eTrackingOrigin, pmatTrackingOriginToKeyboardTransform);
}

void tr_ovw_SetKeyboardPositionForOverlay(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::HmdRect2_t avoidRect) {
	self->SetKeyboardPositionForOverlay(ulOverlayHandle, avoidRect);
}

vr::EVROverlayError tr_ovw_SetOverlayIntersectionMask(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, vr::VROverlayIntersectionMaskPrimitive_t * pMaskPrimitives, uint32_t unNumMaskPrimitives, uint32_t unPrimitiveSize) {
	return self->SetOverlayIntersectionMask(ulOverlayHandle, pMaskPrimitives, unNumMaskPrimitives, unPrimitiveSize);
}

vr::EVROverlayError tr_ovw_GetOverlayFlags(vr::IVROverlay* self, vr::VROverlayHandle_t ulOverlayHandle, uint32_t * pFlags) {
	return self->GetOverlayFlags(ulOverlayHandle, pFlags);
}

vr::VRMessageOverlayResponse tr_ovw_ShowMessageOverlay(vr::IVROverlay* self, const char * pchText, const char * pchCaption, const char * pchButton0Text, const char * pchButton1Text, const char * pchButton2Text, const char * pchButton3Text) {
	return self->ShowMessageOverlay(pchText, pchCaption, pchButton0Text, pchButton1Text, pchButton2Text, pchButton3Text);
}

void tr_ovw_CloseMessageOverlay(vr::IVROverlay* self) {
	self->CloseMessageOverlay();
}

vr::EVRRenderModelError tr_ovw_LoadRenderModel_Async(vr::IVRRenderModels* self, const char * pchRenderModelName, vr::RenderModel_t ** ppRenderModel) {
	return self->LoadRenderModel_Async(pchRenderModelName, ppRenderModel);
}

void tr_ovw_FreeRenderModel(vr::IVRRenderModels* self, vr::RenderModel_t * pRenderModel) {
	self->FreeRenderModel(pRenderModel);
}

vr::EVRRenderModelError tr_ovw_LoadTexture_Async(vr::IVRRenderModels* self, vr::TextureID_t textureId, vr::RenderModel_TextureMap_t ** ppTexture) {
	return self->LoadTexture_Async(textureId, ppTexture);
}

void tr_ovw_FreeTexture(vr::IVRRenderModels* self, vr::RenderModel_TextureMap_t * pTexture) {
	self->FreeTexture(pTexture);
}

vr::EVRRenderModelError tr_ovw_LoadTextureD3D11_Async(vr::IVRRenderModels* self, vr::TextureID_t textureId, void * pD3D11Device, void ** ppD3D11Texture2D) {
	return self->LoadTextureD3D11_Async(textureId, pD3D11Device, ppD3D11Texture2D);
}

vr::EVRRenderModelError tr_ovw_LoadIntoTextureD3D11_Async(vr::IVRRenderModels* self, vr::TextureID_t textureId, void * pDstTexture) {
	return self->LoadIntoTextureD3D11_Async(textureId, pDstTexture);
}

void tr_ovw_FreeTextureD3D11(vr::IVRRenderModels* self, void * pD3D11Texture2D) {
	self->FreeTextureD3D11(pD3D11Texture2D);
}

uint32_t tr_ovw_GetRenderModelName(vr::IVRRenderModels* self, uint32_t unRenderModelIndex, char * pchRenderModelName, uint32_t unRenderModelNameLen) {
	return self->GetRenderModelName(unRenderModelIndex, pchRenderModelName, unRenderModelNameLen);
}

uint32_t tr_ovw_GetRenderModelCount(vr::IVRRenderModels* self) {
	return self->GetRenderModelCount();
}

uint32_t tr_ovw_GetComponentCount(vr::IVRRenderModels* self, const char * pchRenderModelName) {
	return self->GetComponentCount(pchRenderModelName);
}

uint32_t tr_ovw_GetComponentName(vr::IVRRenderModels* self, const char * pchRenderModelName, uint32_t unComponentIndex, char * pchComponentName, uint32_t unComponentNameLen) {
	return self->GetComponentName(pchRenderModelName, unComponentIndex, pchComponentName, unComponentNameLen);
}

uint64_t tr_ovw_GetComponentButtonMask(vr::IVRRenderModels* self, const char * pchRenderModelName, const char * pchComponentName) {
	return self->GetComponentButtonMask(pchRenderModelName, pchComponentName);
}

uint32_t tr_ovw_GetComponentRenderModelName(vr::IVRRenderModels* self, const char * pchRenderModelName, const char * pchComponentName, char * pchComponentRenderModelName, uint32_t unComponentRenderModelNameLen) {
	return self->GetComponentRenderModelName(pchRenderModelName, pchComponentName, pchComponentRenderModelName, unComponentRenderModelNameLen);
}

bool tr_ovw_GetComponentStateForDevicePath(vr::IVRRenderModels* self, const char * pchRenderModelName, const char * pchComponentName, vr::VRInputValueHandle_t devicePath, vr::RenderModel_ControllerMode_State_t * pState, vr::RenderModel_ComponentState_t * pComponentState) {
	return self->GetComponentStateForDevicePath(pchRenderModelName, pchComponentName, devicePath, pState, pComponentState);
}

bool tr_ovw_GetComponentState(vr::IVRRenderModels* self, const char * pchRenderModelName, const char * pchComponentName, vr::VRControllerState_t * pControllerState, vr::RenderModel_ControllerMode_State_t * pState, vr::RenderModel_ComponentState_t * pComponentState) {
	return self->GetComponentState(pchRenderModelName, pchComponentName, pControllerState, pState, pComponentState);
}

bool tr_ovw_RenderModelHasComponent(vr::IVRRenderModels* self, const char * pchRenderModelName, const char * pchComponentName) {
	return self->RenderModelHasComponent(pchRenderModelName, pchComponentName);
}

uint32_t tr_ovw_GetRenderModelThumbnailURL(vr::IVRRenderModels* self, const char * pchRenderModelName, char * pchThumbnailURL, uint32_t unThumbnailURLLen, vr::EVRRenderModelError * peError) {
	return self->GetRenderModelThumbnailURL(pchRenderModelName, pchThumbnailURL, unThumbnailURLLen, peError);
}

uint32_t tr_ovw_GetRenderModelOriginalPath(vr::IVRRenderModels* self, const char * pchRenderModelName, char * pchOriginalPath, uint32_t unOriginalPathLen, vr::EVRRenderModelError * peError) {
	return self->GetRenderModelOriginalPath(pchRenderModelName, pchOriginalPath, unOriginalPathLen, peError);
}

const char * tr_ovw_GetRenderModelErrorNameFromEnum(vr::IVRRenderModels* self, vr::EVRRenderModelError error) {
	return self->GetRenderModelErrorNameFromEnum(error);
}

vr::EVRNotificationError tr_ovw_CreateNotification(vr::IVRNotifications* self, vr::VROverlayHandle_t ulOverlayHandle, uint64_t ulUserValue, vr::EVRNotificationType type, const char * pchText, vr::EVRNotificationStyle style, vr::NotificationBitmap_t * pImage, vr::VRNotificationId * pNotificationId) {
	return self->CreateNotification(ulOverlayHandle, ulUserValue, type, pchText, style, pImage, pNotificationId);
}

vr::EVRNotificationError tr_ovw_RemoveNotification(vr::IVRNotifications* self, vr::VRNotificationId notificationId) {
	return self->RemoveNotification(notificationId);
}

const char * tr_ovw_GetSettingsErrorNameFromEnum(vr::IVRSettings* self, vr::EVRSettingsError eError) {
	return self->GetSettingsErrorNameFromEnum(eError);
}

bool tr_ovw_Sync(vr::IVRSettings* self, bool bForce, vr::EVRSettingsError * peError) {
	return self->Sync(bForce, peError);
}

void tr_ovw_SetBool(vr::IVRSettings* self, const char * pchSection, const char * pchSettingsKey, bool bValue, vr::EVRSettingsError * peError) {
	self->SetBool(pchSection, pchSettingsKey, bValue, peError);
}

void tr_ovw_SetInt32(vr::IVRSettings* self, const char * pchSection, const char * pchSettingsKey, int32_t nValue, vr::EVRSettingsError * peError) {
	self->SetInt32(pchSection, pchSettingsKey, nValue, peError);
}

void tr_ovw_SetFloat(vr::IVRSettings* self, const char * pchSection, const char * pchSettingsKey, float flValue, vr::EVRSettingsError * peError) {
	self->SetFloat(pchSection, pchSettingsKey, flValue, peError);
}

void tr_ovw_SetString(vr::IVRSettings* self, const char * pchSection, const char * pchSettingsKey, const char * pchValue, vr::EVRSettingsError * peError) {
	self->SetString(pchSection, pchSettingsKey, pchValue, peError);
}

bool tr_ovw_GetBool(vr::IVRSettings* self, const char * pchSection, const char * pchSettingsKey, vr::EVRSettingsError * peError) {
	return self->GetBool(pchSection, pchSettingsKey, peError);
}

int32_t tr_ovw_GetInt32(vr::IVRSettings* self, const char * pchSection, const char * pchSettingsKey, vr::EVRSettingsError * peError) {
	return self->GetInt32(pchSection, pchSettingsKey, peError);
}

float tr_ovw_GetFloat(vr::IVRSettings* self, const char * pchSection, const char * pchSettingsKey, vr::EVRSettingsError * peError) {
	return self->GetFloat(pchSection, pchSettingsKey, peError);
}

void tr_ovw_GetString(vr::IVRSettings* self, const char * pchSection, const char * pchSettingsKey, char * pchValue, uint32_t unValueLen, vr::EVRSettingsError * peError) {
	self->GetString(pchSection, pchSettingsKey, pchValue, unValueLen, peError);
}

void tr_ovw_RemoveSection(vr::IVRSettings* self, const char * pchSection, vr::EVRSettingsError * peError) {
	self->RemoveSection(pchSection, peError);
}

void tr_ovw_RemoveKeyInSection(vr::IVRSettings* self, const char * pchSection, const char * pchSettingsKey, vr::EVRSettingsError * peError) {
	self->RemoveKeyInSection(pchSection, pchSettingsKey, peError);
}

vr::EVRScreenshotError tr_ovw_RequestScreenshot(vr::IVRScreenshots* self, vr::ScreenshotHandle_t * pOutScreenshotHandle, vr::EVRScreenshotType type, const char * pchPreviewFilename, const char * pchVRFilename) {
	return self->RequestScreenshot(pOutScreenshotHandle, type, pchPreviewFilename, pchVRFilename);
}

vr::EVRScreenshotError tr_ovw_HookScreenshot(vr::IVRScreenshots* self, vr::EVRScreenshotType * pSupportedTypes, int numTypes) {
	return self->HookScreenshot(pSupportedTypes, numTypes);
}

vr::EVRScreenshotType tr_ovw_GetScreenshotPropertyType(vr::IVRScreenshots* self, vr::ScreenshotHandle_t screenshotHandle, vr::EVRScreenshotError * pError) {
	return self->GetScreenshotPropertyType(screenshotHandle, pError);
}

uint32_t tr_ovw_GetScreenshotPropertyFilename(vr::IVRScreenshots* self, vr::ScreenshotHandle_t screenshotHandle, vr::EVRScreenshotPropertyFilenames filenameType, char * pchFilename, uint32_t cchFilename, vr::EVRScreenshotError * pError) {
	return self->GetScreenshotPropertyFilename(screenshotHandle, filenameType, pchFilename, cchFilename, pError);
}

vr::EVRScreenshotError tr_ovw_UpdateScreenshotProgress(vr::IVRScreenshots* self, vr::ScreenshotHandle_t screenshotHandle, float flProgress) {
	return self->UpdateScreenshotProgress(screenshotHandle, flProgress);
}

vr::EVRScreenshotError tr_ovw_TakeStereoScreenshot(vr::IVRScreenshots* self, vr::ScreenshotHandle_t * pOutScreenshotHandle, const char * pchPreviewFilename, const char * pchVRFilename) {
	return self->TakeStereoScreenshot(pOutScreenshotHandle, pchPreviewFilename, pchVRFilename);
}

vr::EVRScreenshotError tr_ovw_SubmitScreenshot(vr::IVRScreenshots* self, vr::ScreenshotHandle_t screenshotHandle, vr::EVRScreenshotType type, const char * pchSourcePreviewFilename, const char * pchSourceVRFilename) {
	return self->SubmitScreenshot(screenshotHandle, type, pchSourcePreviewFilename, pchSourceVRFilename);
}

uint32_t tr_ovw_LoadSharedResource(vr::IVRResources* self, const char * pchResourceName, char * pchBuffer, uint32_t unBufferLen) {
	return self->LoadSharedResource(pchResourceName, pchBuffer, unBufferLen);
}

uint32_t tr_ovw_GetResourceFullPath(vr::IVRResources* self, const char * pchResourceName, const char * pchResourceTypeDirectory, char * pchPathBuffer, uint32_t unBufferLen) {
	return self->GetResourceFullPath(pchResourceName, pchResourceTypeDirectory, pchPathBuffer, unBufferLen);
}

uint32_t tr_ovw_GetDriverCount(vr::IVRDriverManager* self) {
	return self->GetDriverCount();
}

uint32_t tr_ovw_GetDriverName(vr::IVRDriverManager* self, vr::DriverId_t nDriver, char * pchValue, uint32_t unBufferSize) {
	return self->GetDriverName(nDriver, pchValue, unBufferSize);
}

DriverHandle_t tr_ovw_GetDriverHandle(vr::IVRDriverManager* self, const char * pchDriverName) {
	return self->GetDriverHandle(pchDriverName);
}

bool tr_ovw_IsEnabled(vr::IVRDriverManager* self, vr::DriverId_t nDriver) {
	return self->IsEnabled(nDriver);
}

vr::EVRInputError tr_ovw_SetActionManifestPath(vr::IVRInput* self, const char * pchActionManifestPath) {
	return self->SetActionManifestPath(pchActionManifestPath);
}

vr::EVRInputError tr_ovw_GetActionSetHandle(vr::IVRInput* self, const char * pchActionSetName, vr::VRActionSetHandle_t * pHandle) {
	return self->GetActionSetHandle(pchActionSetName, pHandle);
}

vr::EVRInputError tr_ovw_GetActionHandle(vr::IVRInput* self, const char * pchActionName, vr::VRActionHandle_t * pHandle) {
	return self->GetActionHandle(pchActionName, pHandle);
}

vr::EVRInputError tr_ovw_GetInputSourceHandle(vr::IVRInput* self, const char * pchInputSourcePath, vr::VRInputValueHandle_t * pHandle) {
	return self->GetInputSourceHandle(pchInputSourcePath, pHandle);
}

vr::EVRInputError tr_ovw_UpdateActionState(vr::IVRInput* self, vr::VRActiveActionSet_t * pSets, uint32_t unSizeOfVRSelectedActionSet_t, uint32_t unSetCount) {
	return self->UpdateActionState(pSets, unSizeOfVRSelectedActionSet_t, unSetCount);
}

vr::EVRInputError tr_ovw_GetDigitalActionData(vr::IVRInput* self, vr::VRActionHandle_t action, vr::InputDigitalActionData_t * pActionData, uint32_t unActionDataSize, vr::VRInputValueHandle_t ulRestrictToDevice) {
	return self->GetDigitalActionData(action, pActionData, unActionDataSize, ulRestrictToDevice);
}

vr::EVRInputError tr_ovw_GetAnalogActionData(vr::IVRInput* self, vr::VRActionHandle_t action, vr::InputAnalogActionData_t * pActionData, uint32_t unActionDataSize, vr::VRInputValueHandle_t ulRestrictToDevice) {
	return self->GetAnalogActionData(action, pActionData, unActionDataSize, ulRestrictToDevice);
}

vr::EVRInputError tr_ovw_GetPoseActionDataRelativeToNow(vr::IVRInput* self, vr::VRActionHandle_t action, vr::ETrackingUniverseOrigin eOrigin, float fPredictedSecondsFromNow, vr::InputPoseActionData_t * pActionData, uint32_t unActionDataSize, vr::VRInputValueHandle_t ulRestrictToDevice) {
	return self->GetPoseActionDataRelativeToNow(action, eOrigin, fPredictedSecondsFromNow, pActionData, unActionDataSize, ulRestrictToDevice);
}

vr::EVRInputError tr_ovw_GetPoseActionDataForNextFrame(vr::IVRInput* self, vr::VRActionHandle_t action, vr::ETrackingUniverseOrigin eOrigin, vr::InputPoseActionData_t * pActionData, uint32_t unActionDataSize, vr::VRInputValueHandle_t ulRestrictToDevice) {
	return self->GetPoseActionDataForNextFrame(action, eOrigin, pActionData, unActionDataSize, ulRestrictToDevice);
}

vr::EVRInputError tr_ovw_GetSkeletalActionData(vr::IVRInput* self, vr::VRActionHandle_t action, vr::InputSkeletalActionData_t * pActionData, uint32_t unActionDataSize) {
	return self->GetSkeletalActionData(action, pActionData, unActionDataSize);
}

vr::EVRInputError tr_ovw_GetBoneCount(vr::IVRInput* self, vr::VRActionHandle_t action, uint32_t * pBoneCount) {
	return self->GetBoneCount(action, pBoneCount);
}

vr::EVRInputError tr_ovw_GetBoneHierarchy(vr::IVRInput* self, vr::VRActionHandle_t action, vr::BoneIndex_t * pParentIndices, uint32_t unIndexArayCount) {
	return self->GetBoneHierarchy(action, pParentIndices, unIndexArayCount);
}

vr::EVRInputError tr_ovw_GetBoneName(vr::IVRInput* self, vr::VRActionHandle_t action, vr::BoneIndex_t nBoneIndex, char * pchBoneName, uint32_t unNameBufferSize) {
	return self->GetBoneName(action, nBoneIndex, pchBoneName, unNameBufferSize);
}

vr::EVRInputError tr_ovw_GetSkeletalReferenceTransforms(vr::IVRInput* self, vr::VRActionHandle_t action, vr::EVRSkeletalTransformSpace eTransformSpace, vr::EVRSkeletalReferencePose eReferencePose, vr::VRBoneTransform_t * pTransformArray, uint32_t unTransformArrayCount) {
	return self->GetSkeletalReferenceTransforms(action, eTransformSpace, eReferencePose, pTransformArray, unTransformArrayCount);
}

vr::EVRInputError tr_ovw_GetSkeletalTrackingLevel(vr::IVRInput* self, vr::VRActionHandle_t action, vr::EVRSkeletalTrackingLevel * pSkeletalTrackingLevel) {
	return self->GetSkeletalTrackingLevel(action, pSkeletalTrackingLevel);
}

vr::EVRInputError tr_ovw_GetSkeletalBoneData(vr::IVRInput* self, vr::VRActionHandle_t action, vr::EVRSkeletalTransformSpace eTransformSpace, vr::EVRSkeletalMotionRange eMotionRange, vr::VRBoneTransform_t * pTransformArray, uint32_t unTransformArrayCount) {
	return self->GetSkeletalBoneData(action, eTransformSpace, eMotionRange, pTransformArray, unTransformArrayCount);
}

vr::EVRInputError tr_ovw_GetSkeletalSummaryData(vr::IVRInput* self, vr::VRActionHandle_t action, vr::EVRSummaryType eSummaryType, vr::VRSkeletalSummaryData_t * pSkeletalSummaryData) {
	return self->GetSkeletalSummaryData(action, eSummaryType, pSkeletalSummaryData);
}

vr::EVRInputError tr_ovw_GetSkeletalBoneDataCompressed(vr::IVRInput* self, vr::VRActionHandle_t action, vr::EVRSkeletalMotionRange eMotionRange, void * pvCompressedData, uint32_t unCompressedSize, uint32_t * punRequiredCompressedSize) {
	return self->GetSkeletalBoneDataCompressed(action, eMotionRange, pvCompressedData, unCompressedSize, punRequiredCompressedSize);
}

vr::EVRInputError tr_ovw_DecompressSkeletalBoneData(vr::IVRInput* self, void * pvCompressedBuffer, uint32_t unCompressedBufferSize, vr::EVRSkeletalTransformSpace eTransformSpace, vr::VRBoneTransform_t * pTransformArray, uint32_t unTransformArrayCount) {
	return self->DecompressSkeletalBoneData(pvCompressedBuffer, unCompressedBufferSize, eTransformSpace, pTransformArray, unTransformArrayCount);
}

vr::EVRInputError tr_ovw_TriggerHapticVibrationAction(vr::IVRInput* self, vr::VRActionHandle_t action, float fStartSecondsFromNow, float fDurationSeconds, float fFrequency, float fAmplitude, vr::VRInputValueHandle_t ulRestrictToDevice) {
	return self->TriggerHapticVibrationAction(action, fStartSecondsFromNow, fDurationSeconds, fFrequency, fAmplitude, ulRestrictToDevice);
}

vr::EVRInputError tr_ovw_GetActionOrigins(vr::IVRInput* self, vr::VRActionSetHandle_t actionSetHandle, vr::VRActionHandle_t digitalActionHandle, vr::VRInputValueHandle_t * originsOut, uint32_t originOutCount) {
	return self->GetActionOrigins(actionSetHandle, digitalActionHandle, originsOut, originOutCount);
}

vr::EVRInputError tr_ovw_GetOriginLocalizedName(vr::IVRInput* self, vr::VRInputValueHandle_t origin, char * pchNameArray, uint32_t unNameArraySize, int32_t unStringSectionsToInclude) {
	return self->GetOriginLocalizedName(origin, pchNameArray, unNameArraySize, unStringSectionsToInclude);
}

vr::EVRInputError tr_ovw_GetOriginTrackedDeviceInfo(vr::IVRInput* self, vr::VRInputValueHandle_t origin, vr::InputOriginInfo_t * pOriginInfo, uint32_t unOriginInfoSize) {
	return self->GetOriginTrackedDeviceInfo(origin, pOriginInfo, unOriginInfoSize);
}

vr::EVRInputError tr_ovw_GetActionBindingInfo(vr::IVRInput* self, vr::VRActionHandle_t action, vr::InputBindingInfo_t * pOriginInfo, uint32_t unBindingInfoSize, uint32_t unBindingInfoCount, uint32_t * punReturnedBindingInfoCount) {
	return self->GetActionBindingInfo(action, pOriginInfo, unBindingInfoSize, unBindingInfoCount, punReturnedBindingInfoCount);
}

vr::EVRInputError tr_ovw_ShowActionOrigins(vr::IVRInput* self, vr::VRActionSetHandle_t actionSetHandle, vr::VRActionHandle_t ulActionHandle) {
	return self->ShowActionOrigins(actionSetHandle, ulActionHandle);
}

vr::EVRInputError tr_ovw_ShowBindingsForActionSet(vr::IVRInput* self, vr::VRActiveActionSet_t * pSets, uint32_t unSizeOfVRSelectedActionSet_t, uint32_t unSetCount, vr::VRInputValueHandle_t originToHighlight) {
	return self->ShowBindingsForActionSet(pSets, unSizeOfVRSelectedActionSet_t, unSetCount, originToHighlight);
}

bool tr_ovw_IsUsingLegacyInput(vr::IVRInput* self) {
	return self->IsUsingLegacyInput();
}

vr::EIOBufferError tr_ovw_Open(vr::IVRIOBuffer* self, const char * pchPath, vr::EIOBufferMode mode, uint32_t unElementSize, uint32_t unElements, vr::IOBufferHandle_t * pulBuffer) {
	return self->Open(pchPath, mode, unElementSize, unElements, pulBuffer);
}

vr::EIOBufferError tr_ovw_Close(vr::IVRIOBuffer* self, vr::IOBufferHandle_t ulBuffer) {
	return self->Close(ulBuffer);
}

vr::EIOBufferError tr_ovw_Read(vr::IVRIOBuffer* self, vr::IOBufferHandle_t ulBuffer, void * pDst, uint32_t unBytes, uint32_t * punRead) {
	return self->Read(ulBuffer, pDst, unBytes, punRead);
}

vr::EIOBufferError tr_ovw_Write(vr::IVRIOBuffer* self, vr::IOBufferHandle_t ulBuffer, void * pSrc, uint32_t unBytes) {
	return self->Write(ulBuffer, pSrc, unBytes);
}

vr::PropertyContainerHandle_t tr_ovw_PropertyContainer(vr::IVRIOBuffer* self, vr::IOBufferHandle_t ulBuffer) {
	return self->PropertyContainer(ulBuffer);
}

bool tr_ovw_HasReaders(vr::IVRIOBuffer* self, vr::IOBufferHandle_t ulBuffer) {
	return self->HasReaders(ulBuffer);
}

vr::EVRSpatialAnchorError tr_ovw_CreateSpatialAnchorFromDescriptor(vr::IVRSpatialAnchors* self, const char * pchDescriptor, vr::SpatialAnchorHandle_t * pHandleOut) {
	return self->CreateSpatialAnchorFromDescriptor(pchDescriptor, pHandleOut);
}

vr::EVRSpatialAnchorError tr_ovw_CreateSpatialAnchorFromPose(vr::IVRSpatialAnchors* self, vr::TrackedDeviceIndex_t unDeviceIndex, vr::ETrackingUniverseOrigin eOrigin, vr::SpatialAnchorPose_t * pPose, vr::SpatialAnchorHandle_t * pHandleOut) {
	return self->CreateSpatialAnchorFromPose(unDeviceIndex, eOrigin, pPose, pHandleOut);
}

vr::EVRSpatialAnchorError tr_ovw_GetSpatialAnchorPose(vr::IVRSpatialAnchors* self, vr::SpatialAnchorHandle_t unHandle, vr::ETrackingUniverseOrigin eOrigin, vr::SpatialAnchorPose_t * pPoseOut) {
	return self->GetSpatialAnchorPose(unHandle, eOrigin, pPoseOut);
}

vr::EVRSpatialAnchorError tr_ovw_GetSpatialAnchorDescriptor(vr::IVRSpatialAnchors* self, vr::SpatialAnchorHandle_t unHandle, char * pchDescriptorOut, uint32_t * punDescriptorBufferLenInOut) {
	return self->GetSpatialAnchorDescriptor(unHandle, pchDescriptorOut, punDescriptorBufferLenInOut);
}

vr::EVRDebugError tr_ovw_EmitVrProfilerEvent(vr::IVRDebug* self, const char * pchMessage) {
	return self->EmitVrProfilerEvent(pchMessage);
}

vr::EVRDebugError tr_ovw_BeginVrProfilerEvent(vr::IVRDebug* self, vr::VrProfilerEventHandle_t * pHandleOut) {
	return self->BeginVrProfilerEvent(pHandleOut);
}

vr::EVRDebugError tr_ovw_FinishVrProfilerEvent(vr::IVRDebug* self, vr::VrProfilerEventHandle_t hHandle, const char * pchMessage) {
	return self->FinishVrProfilerEvent(hHandle, pchMessage);
}

uint32_t tr_ovw_DriverDebugRequest(vr::IVRDebug* self, vr::TrackedDeviceIndex_t unDeviceIndex, const char * pchRequest, char * pchResponseBuffer, uint32_t unResponseBufferSize) {
	return self->DriverDebugRequest(unDeviceIndex, pchRequest, pchResponseBuffer, unResponseBufferSize);
}


