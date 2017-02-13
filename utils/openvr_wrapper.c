void tr_ovw_GetRecommendedRenderTargetSize(IVRSystem* self, uint32_t * pnWidth, uint32_t * pnHeight){
    self->GetRecommendedRenderTargetSize(pnWidth, pnHeight);
}

HmdMatrix44_t tr_ovw_GetProjectionMatrix(IVRSystem* self, EVREye eEye, float fNearZ, float fFarZ){
    return self->GetProjectionMatrix(eEye, fNearZ, fFarZ);
}

void tr_ovw_GetProjectionRaw(IVRSystem* self, EVREye eEye, float * pfLeft, float * pfRight, float * pfTop, float * pfBottom){
    self->GetProjectionRaw(eEye, pfLeft, pfRight, pfTop, pfBottom);
}

bool tr_ovw_ComputeDistortion(IVRSystem* self, EVREye eEye, float fU, float fV, DistortionCoordinates_t * pDistortionCoordinates){
    return self->ComputeDistortion(eEye, fU, fV, pDistortionCoordinates);
}

HmdMatrix34_t tr_ovw_GetEyeToHeadTransform(IVRSystem* self, EVREye eEye){
    return self->GetEyeToHeadTransform(eEye);
}

bool tr_ovw_GetTimeSinceLastVsync(IVRSystem* self, float * pfSecondsSinceLastVsync, uint64_t * pulFrameCounter){
    return self->GetTimeSinceLastVsync(pfSecondsSinceLastVsync, pulFrameCounter);
}

int32_t tr_ovw_GetD3D9AdapterIndex(IVRSystem* self){
    return self->GetD3D9AdapterIndex();
}

void tr_ovw_GetDXGIOutputInfo(IVRSystem* self, int32_t * pnAdapterIndex){
    self->GetDXGIOutputInfo(pnAdapterIndex);
}

bool tr_ovw_IsDisplayOnDesktop(IVRSystem* self){
    return self->IsDisplayOnDesktop();
}

bool tr_ovw_SetDisplayVisibility(IVRSystem* self, bool bIsVisibleOnDesktop){
    return self->SetDisplayVisibility(bIsVisibleOnDesktop);
}

void tr_ovw_GetDeviceToAbsoluteTrackingPose(IVRSystem* self, ETrackingUniverseOrigin eOrigin, float fPredictedSecondsToPhotonsFromNow, TrackedDevicePose_t * pTrackedDevicePoseArray, uint32_t unTrackedDevicePoseArrayCount){
    self->GetDeviceToAbsoluteTrackingPose(eOrigin, fPredictedSecondsToPhotonsFromNow, pTrackedDevicePoseArray, unTrackedDevicePoseArrayCount);
}

void tr_ovw_ResetSeatedZeroPose(IVRSystem* self){
    self->ResetSeatedZeroPose();
}

HmdMatrix34_t tr_ovw_GetSeatedZeroPoseToStandingAbsoluteTrackingPose(IVRSystem* self){
    return self->GetSeatedZeroPoseToStandingAbsoluteTrackingPose();
}

HmdMatrix34_t tr_ovw_GetRawZeroPoseToStandingAbsoluteTrackingPose(IVRSystem* self){
    return self->GetRawZeroPoseToStandingAbsoluteTrackingPose();
}

uint32_t tr_ovw_GetSortedTrackedDeviceIndicesOfClass(IVRSystem* self, ETrackedDeviceClass eTrackedDeviceClass, TrackedDeviceIndex_t * punTrackedDeviceIndexArray, uint32_t unTrackedDeviceIndexArrayCount, TrackedDeviceIndex_t unRelativeToTrackedDeviceIndex){
    return self->GetSortedTrackedDeviceIndicesOfClass(eTrackedDeviceClass, punTrackedDeviceIndexArray, unTrackedDeviceIndexArrayCount, unRelativeToTrackedDeviceIndex);
}

EDeviceActivityLevel tr_ovw_GetTrackedDeviceActivityLevel(IVRSystem* self, TrackedDeviceIndex_t unDeviceId){
    return self->GetTrackedDeviceActivityLevel(unDeviceId);
}

void tr_ovw_ApplyTransform(IVRSystem* self, TrackedDevicePose_t * pOutputPose, TrackedDevicePose_t * pTrackedDevicePose, HmdMatrix34_t * pTransform){
    self->ApplyTransform(pOutputPose, pTrackedDevicePose, pTransform);
}

TrackedDeviceIndex_t tr_ovw_GetTrackedDeviceIndexForControllerRole(IVRSystem* self, ETrackedControllerRole unDeviceType){
    return self->GetTrackedDeviceIndexForControllerRole(unDeviceType);
}

ETrackedControllerRole tr_ovw_GetControllerRoleForTrackedDeviceIndex(IVRSystem* self, TrackedDeviceIndex_t unDeviceIndex){
    return self->GetControllerRoleForTrackedDeviceIndex(unDeviceIndex);
}

ETrackedDeviceClass tr_ovw_GetTrackedDeviceClass(IVRSystem* self, TrackedDeviceIndex_t unDeviceIndex){
    return self->GetTrackedDeviceClass(unDeviceIndex);
}

bool tr_ovw_IsTrackedDeviceConnected(IVRSystem* self, TrackedDeviceIndex_t unDeviceIndex){
    return self->IsTrackedDeviceConnected(unDeviceIndex);
}

bool tr_ovw_GetBoolTrackedDeviceProperty(IVRSystem* self, TrackedDeviceIndex_t unDeviceIndex, ETrackedDeviceProperty prop, ETrackedPropertyError * pError){
    return self->GetBoolTrackedDeviceProperty(unDeviceIndex, prop, pError);
}

float tr_ovw_GetFloatTrackedDeviceProperty(IVRSystem* self, TrackedDeviceIndex_t unDeviceIndex, ETrackedDeviceProperty prop, ETrackedPropertyError * pError){
    return self->GetFloatTrackedDeviceProperty(unDeviceIndex, prop, pError);
}

int32_t tr_ovw_GetInt32TrackedDeviceProperty(IVRSystem* self, TrackedDeviceIndex_t unDeviceIndex, ETrackedDeviceProperty prop, ETrackedPropertyError * pError){
    return self->GetInt32TrackedDeviceProperty(unDeviceIndex, prop, pError);
}

uint64_t tr_ovw_GetUint64TrackedDeviceProperty(IVRSystem* self, TrackedDeviceIndex_t unDeviceIndex, ETrackedDeviceProperty prop, ETrackedPropertyError * pError){
    return self->GetUint64TrackedDeviceProperty(unDeviceIndex, prop, pError);
}

HmdMatrix34_t tr_ovw_GetMatrix34TrackedDeviceProperty(IVRSystem* self, TrackedDeviceIndex_t unDeviceIndex, ETrackedDeviceProperty prop, ETrackedPropertyError * pError){
    return self->GetMatrix34TrackedDeviceProperty(unDeviceIndex, prop, pError);
}

uint32_t tr_ovw_GetStringTrackedDeviceProperty(IVRSystem* self, TrackedDeviceIndex_t unDeviceIndex, ETrackedDeviceProperty prop, char * pchValue, uint32_t unBufferSize, ETrackedPropertyError * pError){
    return self->GetStringTrackedDeviceProperty(unDeviceIndex, prop, pchValue, unBufferSize, pError);
}

char * tr_ovw_GetPropErrorNameFromEnum(IVRSystem* self, ETrackedPropertyError error){
    return self->GetPropErrorNameFromEnum(error);
}

bool tr_ovw_PollNextEvent(IVRSystem* self, VREvent_t * pEvent, uint32_t uncbVREvent){
    return self->PollNextEvent(pEvent, uncbVREvent);
}

bool tr_ovw_PollNextEventWithPose(IVRSystem* self, ETrackingUniverseOrigin eOrigin, VREvent_t * pEvent, uint32_t uncbVREvent, TrackedDevicePose_t * pTrackedDevicePose){
    return self->PollNextEventWithPose(eOrigin, pEvent, uncbVREvent, pTrackedDevicePose);
}

char * tr_ovw_GetEventTypeNameFromEnum(IVRSystem* self, EVREventType eType){
    return self->GetEventTypeNameFromEnum(eType);
}

HiddenAreaMesh_t tr_ovw_GetHiddenAreaMesh(IVRSystem* self, EVREye eEye, EHiddenAreaMeshType type){
    return self->GetHiddenAreaMesh(eEye, type);
}

bool tr_ovw_GetControllerState(IVRSystem* self, TrackedDeviceIndex_t unControllerDeviceIndex, VRControllerState_t * pControllerState, uint32_t unControllerStateSize){
    return self->GetControllerState(unControllerDeviceIndex, pControllerState, unControllerStateSize);
}

bool tr_ovw_GetControllerStateWithPose(IVRSystem* self, ETrackingUniverseOrigin eOrigin, TrackedDeviceIndex_t unControllerDeviceIndex, VRControllerState_t * pControllerState, uint32_t unControllerStateSize, TrackedDevicePose_t * pTrackedDevicePose){
    return self->GetControllerStateWithPose(eOrigin, unControllerDeviceIndex, pControllerState, unControllerStateSize, pTrackedDevicePose);
}

void tr_ovw_TriggerHapticPulse(IVRSystem* self, TrackedDeviceIndex_t unControllerDeviceIndex, uint32_t unAxisId, unsigned short usDurationMicroSec){
    self->TriggerHapticPulse(unControllerDeviceIndex, unAxisId, usDurationMicroSec);
}

char * tr_ovw_GetButtonIdNameFromEnum(IVRSystem* self, EVRButtonId eButtonId){
    return self->GetButtonIdNameFromEnum(eButtonId);
}

char * tr_ovw_GetControllerAxisTypeNameFromEnum(IVRSystem* self, EVRControllerAxisType eAxisType){
    return self->GetControllerAxisTypeNameFromEnum(eAxisType);
}

bool tr_ovw_CaptureInputFocus(IVRSystem* self){
    return self->CaptureInputFocus();
}

void tr_ovw_ReleaseInputFocus(IVRSystem* self){
    self->ReleaseInputFocus();
}

bool tr_ovw_IsInputFocusCapturedByAnotherProcess(IVRSystem* self){
    return self->IsInputFocusCapturedByAnotherProcess();
}

uint32_t tr_ovw_DriverDebugRequest(IVRSystem* self, TrackedDeviceIndex_t unDeviceIndex, char * pchRequest, char * pchResponseBuffer, uint32_t unResponseBufferSize){
    return self->DriverDebugRequest(unDeviceIndex, pchRequest, pchResponseBuffer, unResponseBufferSize);
}

EVRFirmwareError tr_ovw_PerformFirmwareUpdate(IVRSystem* self, TrackedDeviceIndex_t unDeviceIndex){
    return self->PerformFirmwareUpdate(unDeviceIndex);
}

void tr_ovw_AcknowledgeQuit_Exiting(IVRSystem* self){
    self->AcknowledgeQuit_Exiting();
}

void tr_ovw_AcknowledgeQuit_UserPrompt(IVRSystem* self){
    self->AcknowledgeQuit_UserPrompt();
}

void tr_ovw_GetWindowBounds(IVRExtendedDisplay* self, int32_t * pnX, int32_t * pnY, uint32_t * pnWidth, uint32_t * pnHeight){
    self->GetWindowBounds(pnX, pnY, pnWidth, pnHeight);
}

void tr_ovw_GetEyeOutputViewport(IVRExtendedDisplay* self, EVREye eEye, uint32_t * pnX, uint32_t * pnY, uint32_t * pnWidth, uint32_t * pnHeight){
    self->GetEyeOutputViewport(eEye, pnX, pnY, pnWidth, pnHeight);
}

void tr_ovw_GetDXGIOutputInfo(IVRExtendedDisplay* self, int32_t * pnAdapterIndex, int32_t * pnAdapterOutputIndex){
    self->GetDXGIOutputInfo(pnAdapterIndex, pnAdapterOutputIndex);
}

char * tr_ovw_GetCameraErrorNameFromEnum(IVRTrackedCamera* self, EVRTrackedCameraError eCameraError){
    return self->GetCameraErrorNameFromEnum(eCameraError);
}

EVRTrackedCameraError tr_ovw_HasCamera(IVRTrackedCamera* self, TrackedDeviceIndex_t nDeviceIndex, bool * pHasCamera){
    return self->HasCamera(nDeviceIndex, pHasCamera);
}

EVRTrackedCameraError tr_ovw_GetCameraFrameSize(IVRTrackedCamera* self, TrackedDeviceIndex_t nDeviceIndex, EVRTrackedCameraFrameType eFrameType, uint32_t * pnWidth, uint32_t * pnHeight, uint32_t * pnFrameBufferSize){
    return self->GetCameraFrameSize(nDeviceIndex, eFrameType, pnWidth, pnHeight, pnFrameBufferSize);
}

EVRTrackedCameraError tr_ovw_GetCameraIntrinsics(IVRTrackedCamera* self, TrackedDeviceIndex_t nDeviceIndex, EVRTrackedCameraFrameType eFrameType, HmdVector2_t * pFocalLength, HmdVector2_t * pCenter){
    return self->GetCameraIntrinsics(nDeviceIndex, eFrameType, pFocalLength, pCenter);
}

EVRTrackedCameraError tr_ovw_GetCameraProjection(IVRTrackedCamera* self, TrackedDeviceIndex_t nDeviceIndex, EVRTrackedCameraFrameType eFrameType, float flZNear, float flZFar, HmdMatrix44_t * pProjection){
    return self->GetCameraProjection(nDeviceIndex, eFrameType, flZNear, flZFar, pProjection);
}

EVRTrackedCameraError tr_ovw_AcquireVideoStreamingService(IVRTrackedCamera* self, TrackedDeviceIndex_t nDeviceIndex, TrackedCameraHandle_t * pHandle){
    return self->AcquireVideoStreamingService(nDeviceIndex, pHandle);
}

EVRTrackedCameraError tr_ovw_ReleaseVideoStreamingService(IVRTrackedCamera* self, TrackedCameraHandle_t hTrackedCamera){
    return self->ReleaseVideoStreamingService(hTrackedCamera);
}

EVRTrackedCameraError tr_ovw_GetVideoStreamFrameBuffer(IVRTrackedCamera* self, TrackedCameraHandle_t hTrackedCamera, EVRTrackedCameraFrameType eFrameType, void * pFrameBuffer, uint32_t nFrameBufferSize, CameraVideoStreamFrameHeader_t * pFrameHeader, uint32_t nFrameHeaderSize){
    return self->GetVideoStreamFrameBuffer(hTrackedCamera, eFrameType, pFrameBuffer, nFrameBufferSize, pFrameHeader, nFrameHeaderSize);
}

EVRTrackedCameraError tr_ovw_GetVideoStreamTextureSize(IVRTrackedCamera* self, TrackedDeviceIndex_t nDeviceIndex, EVRTrackedCameraFrameType eFrameType, VRTextureBounds_t * pTextureBounds, uint32_t * pnWidth, uint32_t * pnHeight){
    return self->GetVideoStreamTextureSize(nDeviceIndex, eFrameType, pTextureBounds, pnWidth, pnHeight);
}

EVRTrackedCameraError tr_ovw_GetVideoStreamTextureD3D11(IVRTrackedCamera* self, TrackedCameraHandle_t hTrackedCamera, EVRTrackedCameraFrameType eFrameType, void * pD3D11DeviceOrResource, void ** ppD3D11ShaderResourceView, CameraVideoStreamFrameHeader_t * pFrameHeader, uint32_t nFrameHeaderSize){
    return self->GetVideoStreamTextureD3D11(hTrackedCamera, eFrameType, pD3D11DeviceOrResource, ppD3D11ShaderResourceView, pFrameHeader, nFrameHeaderSize);
}

EVRTrackedCameraError tr_ovw_GetVideoStreamTextureGL(IVRTrackedCamera* self, TrackedCameraHandle_t hTrackedCamera, EVRTrackedCameraFrameType eFrameType, glUInt_t * pglTextureId, CameraVideoStreamFrameHeader_t * pFrameHeader, uint32_t nFrameHeaderSize){
    return self->GetVideoStreamTextureGL(hTrackedCamera, eFrameType, pglTextureId, pFrameHeader, nFrameHeaderSize);
}

EVRTrackedCameraError tr_ovw_ReleaseVideoStreamTextureGL(IVRTrackedCamera* self, TrackedCameraHandle_t hTrackedCamera, glUInt_t glTextureId){
    return self->ReleaseVideoStreamTextureGL(hTrackedCamera, glTextureId);
}

EVRApplicationError tr_ovw_AddApplicationManifest(IVRApplications* self, char * pchApplicationManifestFullPath, bool bTemporary){
    return self->AddApplicationManifest(pchApplicationManifestFullPath, bTemporary);
}

EVRApplicationError tr_ovw_RemoveApplicationManifest(IVRApplications* self, char * pchApplicationManifestFullPath){
    return self->RemoveApplicationManifest(pchApplicationManifestFullPath);
}

bool tr_ovw_IsApplicationInstalled(IVRApplications* self, char * pchAppKey){
    return self->IsApplicationInstalled(pchAppKey);
}

uint32_t tr_ovw_GetApplicationCount(IVRApplications* self){
    return self->GetApplicationCount();
}

EVRApplicationError tr_ovw_GetApplicationKeyByIndex(IVRApplications* self, uint32_t unApplicationIndex, char * pchAppKeyBuffer, uint32_t unAppKeyBufferLen){
    return self->GetApplicationKeyByIndex(unApplicationIndex, pchAppKeyBuffer, unAppKeyBufferLen);
}

EVRApplicationError tr_ovw_GetApplicationKeyByProcessId(IVRApplications* self, uint32_t unProcessId, char * pchAppKeyBuffer, uint32_t unAppKeyBufferLen){
    return self->GetApplicationKeyByProcessId(unProcessId, pchAppKeyBuffer, unAppKeyBufferLen);
}

EVRApplicationError tr_ovw_LaunchApplication(IVRApplications* self, char * pchAppKey){
    return self->LaunchApplication(pchAppKey);
}

EVRApplicationError tr_ovw_LaunchTemplateApplication(IVRApplications* self, char * pchTemplateAppKey, char * pchNewAppKey, AppOverrideKeys_t * pKeys, uint32_t unKeys){
    return self->LaunchTemplateApplication(pchTemplateAppKey, pchNewAppKey, pKeys, unKeys);
}

EVRApplicationError tr_ovw_LaunchApplicationFromMimeType(IVRApplications* self, char * pchMimeType, char * pchArgs){
    return self->LaunchApplicationFromMimeType(pchMimeType, pchArgs);
}

EVRApplicationError tr_ovw_LaunchDashboardOverlay(IVRApplications* self, char * pchAppKey){
    return self->LaunchDashboardOverlay(pchAppKey);
}

bool tr_ovw_CancelApplicationLaunch(IVRApplications* self, char * pchAppKey){
    return self->CancelApplicationLaunch(pchAppKey);
}

EVRApplicationError tr_ovw_IdentifyApplication(IVRApplications* self, uint32_t unProcessId, char * pchAppKey){
    return self->IdentifyApplication(unProcessId, pchAppKey);
}

uint32_t tr_ovw_GetApplicationProcessId(IVRApplications* self, char * pchAppKey){
    return self->GetApplicationProcessId(pchAppKey);
}

char * tr_ovw_GetApplicationsErrorNameFromEnum(IVRApplications* self, EVRApplicationError error){
    return self->GetApplicationsErrorNameFromEnum(error);
}

uint32_t tr_ovw_GetApplicationPropertyString(IVRApplications* self, char * pchAppKey, EVRApplicationProperty eProperty, char * pchPropertyValueBuffer, uint32_t unPropertyValueBufferLen, EVRApplicationError * peError){
    return self->GetApplicationPropertyString(pchAppKey, eProperty, pchPropertyValueBuffer, unPropertyValueBufferLen, peError);
}

bool tr_ovw_GetApplicationPropertyBool(IVRApplications* self, char * pchAppKey, EVRApplicationProperty eProperty, EVRApplicationError * peError){
    return self->GetApplicationPropertyBool(pchAppKey, eProperty, peError);
}

uint64_t tr_ovw_GetApplicationPropertyUint64(IVRApplications* self, char * pchAppKey, EVRApplicationProperty eProperty, EVRApplicationError * peError){
    return self->GetApplicationPropertyUint64(pchAppKey, eProperty, peError);
}

EVRApplicationError tr_ovw_SetApplicationAutoLaunch(IVRApplications* self, char * pchAppKey, bool bAutoLaunch){
    return self->SetApplicationAutoLaunch(pchAppKey, bAutoLaunch);
}

bool tr_ovw_GetApplicationAutoLaunch(IVRApplications* self, char * pchAppKey){
    return self->GetApplicationAutoLaunch(pchAppKey);
}

EVRApplicationError tr_ovw_SetDefaultApplicationForMimeType(IVRApplications* self, char * pchAppKey, char * pchMimeType){
    return self->SetDefaultApplicationForMimeType(pchAppKey, pchMimeType);
}

bool tr_ovw_GetDefaultApplicationForMimeType(IVRApplications* self, char * pchMimeType, char * pchAppKeyBuffer, uint32_t unAppKeyBufferLen){
    return self->GetDefaultApplicationForMimeType(pchMimeType, pchAppKeyBuffer, unAppKeyBufferLen);
}

bool tr_ovw_GetApplicationSupportedMimeTypes(IVRApplications* self, char * pchAppKey, char * pchMimeTypesBuffer, uint32_t unMimeTypesBuffer){
    return self->GetApplicationSupportedMimeTypes(pchAppKey, pchMimeTypesBuffer, unMimeTypesBuffer);
}

uint32_t tr_ovw_GetApplicationsThatSupportMimeType(IVRApplications* self, char * pchMimeType, char * pchAppKeysThatSupportBuffer, uint32_t unAppKeysThatSupportBuffer){
    return self->GetApplicationsThatSupportMimeType(pchMimeType, pchAppKeysThatSupportBuffer, unAppKeysThatSupportBuffer);
}

uint32_t tr_ovw_GetApplicationLaunchArguments(IVRApplications* self, uint32_t unHandle, char * pchArgs, uint32_t unArgs){
    return self->GetApplicationLaunchArguments(unHandle, pchArgs, unArgs);
}

EVRApplicationError tr_ovw_GetStartingApplication(IVRApplications* self, char * pchAppKeyBuffer, uint32_t unAppKeyBufferLen){
    return self->GetStartingApplication(pchAppKeyBuffer, unAppKeyBufferLen);
}

EVRApplicationTransitionState tr_ovw_GetTransitionState(IVRApplications* self){
    return self->GetTransitionState();
}

EVRApplicationError tr_ovw_PerformApplicationPrelaunchCheck(IVRApplications* self, char * pchAppKey){
    return self->PerformApplicationPrelaunchCheck(pchAppKey);
}

char * tr_ovw_GetApplicationsTransitionStateNameFromEnum(IVRApplications* self, EVRApplicationTransitionState state){
    return self->GetApplicationsTransitionStateNameFromEnum(state);
}

bool tr_ovw_IsQuitUserPromptRequested(IVRApplications* self){
    return self->IsQuitUserPromptRequested();
}

EVRApplicationError tr_ovw_LaunchInternalProcess(IVRApplications* self, char * pchBinaryPath, char * pchArguments, char * pchWorkingDirectory){
    return self->LaunchInternalProcess(pchBinaryPath, pchArguments, pchWorkingDirectory);
}

uint32_t tr_ovw_GetCurrentSceneProcessId(IVRApplications* self){
    return self->GetCurrentSceneProcessId();
}

ChaperoneCalibrationState tr_ovw_GetCalibrationState(IVRChaperone* self){
    return self->GetCalibrationState();
}

bool tr_ovw_GetPlayAreaSize(IVRChaperone* self, float * pSizeX, float * pSizeZ){
    return self->GetPlayAreaSize(pSizeX, pSizeZ);
}

bool tr_ovw_GetPlayAreaRect(IVRChaperone* self, HmdQuad_t * rect){
    return self->GetPlayAreaRect(rect);
}

void tr_ovw_ReloadInfo(IVRChaperone* self){
    self->ReloadInfo();
}

void tr_ovw_SetSceneColor(IVRChaperone* self, HmdColor_t color){
    self->SetSceneColor(color);
}

void tr_ovw_GetBoundsColor(IVRChaperone* self, HmdColor_t * pOutputColorArray, int nNumOutputColors, float flCollisionBoundsFadeDistance, HmdColor_t * pOutputCameraColor){
    self->GetBoundsColor(pOutputColorArray, nNumOutputColors, flCollisionBoundsFadeDistance, pOutputCameraColor);
}

bool tr_ovw_AreBoundsVisible(IVRChaperone* self){
    return self->AreBoundsVisible();
}

void tr_ovw_ForceBoundsVisible(IVRChaperone* self, bool bForce){
    self->ForceBoundsVisible(bForce);
}

bool tr_ovw_CommitWorkingCopy(IVRChaperoneSetup* self, EChaperoneConfigFile configFile){
    return self->CommitWorkingCopy(configFile);
}

void tr_ovw_RevertWorkingCopy(IVRChaperoneSetup* self){
    self->RevertWorkingCopy();
}

bool tr_ovw_GetWorkingPlayAreaSize(IVRChaperoneSetup* self, float * pSizeX, float * pSizeZ){
    return self->GetWorkingPlayAreaSize(pSizeX, pSizeZ);
}

bool tr_ovw_GetWorkingPlayAreaRect(IVRChaperoneSetup* self, HmdQuad_t * rect){
    return self->GetWorkingPlayAreaRect(rect);
}

bool tr_ovw_GetWorkingCollisionBoundsInfo(IVRChaperoneSetup* self, HmdQuad_t * pQuadsBuffer, uint32_t * punQuadsCount){
    return self->GetWorkingCollisionBoundsInfo(pQuadsBuffer, punQuadsCount);
}

bool tr_ovw_GetLiveCollisionBoundsInfo(IVRChaperoneSetup* self, HmdQuad_t * pQuadsBuffer, uint32_t * punQuadsCount){
    return self->GetLiveCollisionBoundsInfo(pQuadsBuffer, punQuadsCount);
}

bool tr_ovw_GetWorkingSeatedZeroPoseToRawTrackingPose(IVRChaperoneSetup* self, HmdMatrix34_t * pmatSeatedZeroPoseToRawTrackingPose){
    return self->GetWorkingSeatedZeroPoseToRawTrackingPose(pmatSeatedZeroPoseToRawTrackingPose);
}

bool tr_ovw_GetWorkingStandingZeroPoseToRawTrackingPose(IVRChaperoneSetup* self, HmdMatrix34_t * pmatStandingZeroPoseToRawTrackingPose){
    return self->GetWorkingStandingZeroPoseToRawTrackingPose(pmatStandingZeroPoseToRawTrackingPose);
}

void tr_ovw_SetWorkingPlayAreaSize(IVRChaperoneSetup* self, float sizeX, float sizeZ){
    self->SetWorkingPlayAreaSize(sizeX, sizeZ);
}

void tr_ovw_SetWorkingCollisionBoundsInfo(IVRChaperoneSetup* self, HmdQuad_t * pQuadsBuffer, uint32_t unQuadsCount){
    self->SetWorkingCollisionBoundsInfo(pQuadsBuffer, unQuadsCount);
}

void tr_ovw_SetWorkingSeatedZeroPoseToRawTrackingPose(IVRChaperoneSetup* self, HmdMatrix34_t * pMatSeatedZeroPoseToRawTrackingPose){
    self->SetWorkingSeatedZeroPoseToRawTrackingPose(pMatSeatedZeroPoseToRawTrackingPose);
}

void tr_ovw_SetWorkingStandingZeroPoseToRawTrackingPose(IVRChaperoneSetup* self, HmdMatrix34_t * pMatStandingZeroPoseToRawTrackingPose){
    self->SetWorkingStandingZeroPoseToRawTrackingPose(pMatStandingZeroPoseToRawTrackingPose);
}

void tr_ovw_ReloadFromDisk(IVRChaperoneSetup* self, EChaperoneConfigFile configFile){
    self->ReloadFromDisk(configFile);
}

bool tr_ovw_GetLiveSeatedZeroPoseToRawTrackingPose(IVRChaperoneSetup* self, HmdMatrix34_t * pmatSeatedZeroPoseToRawTrackingPose){
    return self->GetLiveSeatedZeroPoseToRawTrackingPose(pmatSeatedZeroPoseToRawTrackingPose);
}

void tr_ovw_SetWorkingCollisionBoundsTagsInfo(IVRChaperoneSetup* self, uint8_t * pTagsBuffer, uint32_t unTagCount){
    self->SetWorkingCollisionBoundsTagsInfo(pTagsBuffer, unTagCount);
}

bool tr_ovw_GetLiveCollisionBoundsTagsInfo(IVRChaperoneSetup* self, uint8_t * pTagsBuffer, uint32_t * punTagCount){
    return self->GetLiveCollisionBoundsTagsInfo(pTagsBuffer, punTagCount);
}

bool tr_ovw_SetWorkingPhysicalBoundsInfo(IVRChaperoneSetup* self, HmdQuad_t * pQuadsBuffer, uint32_t unQuadsCount){
    return self->SetWorkingPhysicalBoundsInfo(pQuadsBuffer, unQuadsCount);
}

bool tr_ovw_GetLivePhysicalBoundsInfo(IVRChaperoneSetup* self, HmdQuad_t * pQuadsBuffer, uint32_t * punQuadsCount){
    return self->GetLivePhysicalBoundsInfo(pQuadsBuffer, punQuadsCount);
}

bool tr_ovw_ExportLiveToBuffer(IVRChaperoneSetup* self, char * pBuffer, uint32_t * pnBufferLength){
    return self->ExportLiveToBuffer(pBuffer, pnBufferLength);
}

bool tr_ovw_ImportFromBufferToWorking(IVRChaperoneSetup* self, char * pBuffer, uint32_t nImportFlags){
    return self->ImportFromBufferToWorking(pBuffer, nImportFlags);
}

void tr_ovw_SetTrackingSpace(IVRCompositor* self, ETrackingUniverseOrigin eOrigin){
    self->SetTrackingSpace(eOrigin);
}

ETrackingUniverseOrigin tr_ovw_GetTrackingSpace(IVRCompositor* self){
    return self->GetTrackingSpace();
}

EVRCompositorError tr_ovw_WaitGetPoses(IVRCompositor* self, TrackedDevicePose_t * pRenderPoseArray, uint32_t unRenderPoseArrayCount, TrackedDevicePose_t * pGamePoseArray, uint32_t unGamePoseArrayCount){
    return self->WaitGetPoses(pRenderPoseArray, unRenderPoseArrayCount, pGamePoseArray, unGamePoseArrayCount);
}

EVRCompositorError tr_ovw_GetLastPoses(IVRCompositor* self, TrackedDevicePose_t * pRenderPoseArray, uint32_t unRenderPoseArrayCount, TrackedDevicePose_t * pGamePoseArray, uint32_t unGamePoseArrayCount){
    return self->GetLastPoses(pRenderPoseArray, unRenderPoseArrayCount, pGamePoseArray, unGamePoseArrayCount);
}

EVRCompositorError tr_ovw_GetLastPoseForTrackedDeviceIndex(IVRCompositor* self, TrackedDeviceIndex_t unDeviceIndex, TrackedDevicePose_t * pOutputPose, TrackedDevicePose_t * pOutputGamePose){
    return self->GetLastPoseForTrackedDeviceIndex(unDeviceIndex, pOutputPose, pOutputGamePose);
}

EVRCompositorError tr_ovw_Submit(IVRCompositor* self, EVREye eEye, Texture_t * pTexture, VRTextureBounds_t * pBounds, EVRSubmitFlags nSubmitFlags){
    return self->Submit(eEye, pTexture, pBounds, nSubmitFlags);
}

void tr_ovw_ClearLastSubmittedFrame(IVRCompositor* self){
    self->ClearLastSubmittedFrame();
}

void tr_ovw_PostPresentHandoff(IVRCompositor* self){
    self->PostPresentHandoff();
}

bool tr_ovw_GetFrameTiming(IVRCompositor* self, Compositor_FrameTiming * pTiming, uint32_t unFramesAgo){
    return self->GetFrameTiming(pTiming, unFramesAgo);
}

uint32_t tr_ovw_GetFrameTimings(IVRCompositor* self, Compositor_FrameTiming * pTiming, uint32_t nFrames){
    return self->GetFrameTimings(pTiming, nFrames);
}

float tr_ovw_GetFrameTimeRemaining(IVRCompositor* self){
    return self->GetFrameTimeRemaining();
}

void tr_ovw_GetCumulativeStats(IVRCompositor* self, Compositor_CumulativeStats * pStats, uint32_t nStatsSizeInBytes){
    self->GetCumulativeStats(pStats, nStatsSizeInBytes);
}

void tr_ovw_FadeToColor(IVRCompositor* self, float fSeconds, float fRed, float fGreen, float fBlue, float fAlpha, bool bBackground){
    self->FadeToColor(fSeconds, fRed, fGreen, fBlue, fAlpha, bBackground);
}

HmdColor_t tr_ovw_GetCurrentFadeColor(IVRCompositor* self, bool bBackground){
    return self->GetCurrentFadeColor(bBackground);
}

void tr_ovw_FadeGrid(IVRCompositor* self, float fSeconds, bool bFadeIn){
    self->FadeGrid(fSeconds, bFadeIn);
}

float tr_ovw_GetCurrentGridAlpha(IVRCompositor* self){
    return self->GetCurrentGridAlpha();
}

EVRCompositorError tr_ovw_SetSkyboxOverride(IVRCompositor* self, Texture_t * pTextures, uint32_t unTextureCount){
    return self->SetSkyboxOverride(pTextures, unTextureCount);
}

void tr_ovw_ClearSkyboxOverride(IVRCompositor* self){
    self->ClearSkyboxOverride();
}

void tr_ovw_CompositorBringToFront(IVRCompositor* self){
    self->CompositorBringToFront();
}

void tr_ovw_CompositorGoToBack(IVRCompositor* self){
    self->CompositorGoToBack();
}

void tr_ovw_CompositorQuit(IVRCompositor* self){
    self->CompositorQuit();
}

bool tr_ovw_IsFullscreen(IVRCompositor* self){
    return self->IsFullscreen();
}

uint32_t tr_ovw_GetCurrentSceneFocusProcess(IVRCompositor* self){
    return self->GetCurrentSceneFocusProcess();
}

uint32_t tr_ovw_GetLastFrameRenderer(IVRCompositor* self){
    return self->GetLastFrameRenderer();
}

bool tr_ovw_CanRenderScene(IVRCompositor* self){
    return self->CanRenderScene();
}

void tr_ovw_ShowMirrorWindow(IVRCompositor* self){
    self->ShowMirrorWindow();
}

void tr_ovw_HideMirrorWindow(IVRCompositor* self){
    self->HideMirrorWindow();
}

bool tr_ovw_IsMirrorWindowVisible(IVRCompositor* self){
    return self->IsMirrorWindowVisible();
}

void tr_ovw_CompositorDumpImages(IVRCompositor* self){
    self->CompositorDumpImages();
}

bool tr_ovw_ShouldAppRenderWithLowResources(IVRCompositor* self){
    return self->ShouldAppRenderWithLowResources();
}

void tr_ovw_ForceInterleavedReprojectionOn(IVRCompositor* self, bool bOverride){
    self->ForceInterleavedReprojectionOn(bOverride);
}

void tr_ovw_ForceReconnectProcess(IVRCompositor* self){
    self->ForceReconnectProcess();
}

void tr_ovw_SuspendRendering(IVRCompositor* self, bool bSuspend){
    self->SuspendRendering(bSuspend);
}

EVRCompositorError tr_ovw_GetMirrorTextureD3D11(IVRCompositor* self, EVREye eEye, void * pD3D11DeviceOrResource, void ** ppD3D11ShaderResourceView){
    return self->GetMirrorTextureD3D11(eEye, pD3D11DeviceOrResource, ppD3D11ShaderResourceView);
}

void tr_ovw_ReleaseMirrorTextureD3D11(IVRCompositor* self, void * pD3D11ShaderResourceView){
    self->ReleaseMirrorTextureD3D11(pD3D11ShaderResourceView);
}

EVRCompositorError tr_ovw_GetMirrorTextureGL(IVRCompositor* self, EVREye eEye, glUInt_t * pglTextureId, glSharedTextureHandle_t * pglSharedTextureHandle){
    return self->GetMirrorTextureGL(eEye, pglTextureId, pglSharedTextureHandle);
}

bool tr_ovw_ReleaseSharedGLTexture(IVRCompositor* self, glUInt_t glTextureId, glSharedTextureHandle_t glSharedTextureHandle){
    return self->ReleaseSharedGLTexture(glTextureId, glSharedTextureHandle);
}

void tr_ovw_LockGLSharedTextureForAccess(IVRCompositor* self, glSharedTextureHandle_t glSharedTextureHandle){
    self->LockGLSharedTextureForAccess(glSharedTextureHandle);
}

void tr_ovw_UnlockGLSharedTextureForAccess(IVRCompositor* self, glSharedTextureHandle_t glSharedTextureHandle){
    self->UnlockGLSharedTextureForAccess(glSharedTextureHandle);
}

uint32_t tr_ovw_GetVulkanInstanceExtensionsRequired(IVRCompositor* self, char * pchValue, uint32_t unBufferSize){
    return self->GetVulkanInstanceExtensionsRequired(pchValue, unBufferSize);
}

uint32_t tr_ovw_GetVulkanDeviceExtensionsRequired(IVRCompositor* self, VkPhysicalDevice_T * pPhysicalDevice, char * pchValue, uint32_t unBufferSize){
    return self->GetVulkanDeviceExtensionsRequired(pPhysicalDevice, pchValue, unBufferSize);
}

EVROverlayError tr_ovw_FindOverlay(IVROverlay* self, char * pchOverlayKey, VROverlayHandle_t * pOverlayHandle){
    return self->FindOverlay(pchOverlayKey, pOverlayHandle);
}

EVROverlayError tr_ovw_CreateOverlay(IVROverlay* self, char * pchOverlayKey, char * pchOverlayFriendlyName, VROverlayHandle_t * pOverlayHandle){
    return self->CreateOverlay(pchOverlayKey, pchOverlayFriendlyName, pOverlayHandle);
}

EVROverlayError tr_ovw_DestroyOverlay(IVROverlay* self, VROverlayHandle_t ulOverlayHandle){
    return self->DestroyOverlay(ulOverlayHandle);
}

EVROverlayError tr_ovw_SetHighQualityOverlay(IVROverlay* self, VROverlayHandle_t ulOverlayHandle){
    return self->SetHighQualityOverlay(ulOverlayHandle);
}

VROverlayHandle_t tr_ovw_GetHighQualityOverlay(IVROverlay* self){
    return self->GetHighQualityOverlay();
}

uint32_t tr_ovw_GetOverlayKey(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, char * pchValue, uint32_t unBufferSize, EVROverlayError * pError){
    return self->GetOverlayKey(ulOverlayHandle, pchValue, unBufferSize, pError);
}

uint32_t tr_ovw_GetOverlayName(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, char * pchValue, uint32_t unBufferSize, EVROverlayError * pError){
    return self->GetOverlayName(ulOverlayHandle, pchValue, unBufferSize, pError);
}

EVROverlayError tr_ovw_GetOverlayImageData(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, void * pvBuffer, uint32_t unBufferSize, uint32_t * punWidth, uint32_t * punHeight){
    return self->GetOverlayImageData(ulOverlayHandle, pvBuffer, unBufferSize, punWidth, punHeight);
}

char * tr_ovw_GetOverlayErrorNameFromEnum(IVROverlay* self, EVROverlayError error){
    return self->GetOverlayErrorNameFromEnum(error);
}

EVROverlayError tr_ovw_SetOverlayRenderingPid(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, uint32_t unPID){
    return self->SetOverlayRenderingPid(ulOverlayHandle, unPID);
}

uint32_t tr_ovw_GetOverlayRenderingPid(IVROverlay* self, VROverlayHandle_t ulOverlayHandle){
    return self->GetOverlayRenderingPid(ulOverlayHandle);
}

EVROverlayError tr_ovw_SetOverlayFlag(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, VROverlayFlags eOverlayFlag, bool bEnabled){
    return self->SetOverlayFlag(ulOverlayHandle, eOverlayFlag, bEnabled);
}

EVROverlayError tr_ovw_GetOverlayFlag(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, VROverlayFlags eOverlayFlag, bool * pbEnabled){
    return self->GetOverlayFlag(ulOverlayHandle, eOverlayFlag, pbEnabled);
}

EVROverlayError tr_ovw_SetOverlayColor(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, float fRed, float fGreen, float fBlue){
    return self->SetOverlayColor(ulOverlayHandle, fRed, fGreen, fBlue);
}

EVROverlayError tr_ovw_GetOverlayColor(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, float * pfRed, float * pfGreen, float * pfBlue){
    return self->GetOverlayColor(ulOverlayHandle, pfRed, pfGreen, pfBlue);
}

EVROverlayError tr_ovw_SetOverlayAlpha(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, float fAlpha){
    return self->SetOverlayAlpha(ulOverlayHandle, fAlpha);
}

EVROverlayError tr_ovw_GetOverlayAlpha(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, float * pfAlpha){
    return self->GetOverlayAlpha(ulOverlayHandle, pfAlpha);
}

EVROverlayError tr_ovw_SetOverlayTexelAspect(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, float fTexelAspect){
    return self->SetOverlayTexelAspect(ulOverlayHandle, fTexelAspect);
}

EVROverlayError tr_ovw_GetOverlayTexelAspect(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, float * pfTexelAspect){
    return self->GetOverlayTexelAspect(ulOverlayHandle, pfTexelAspect);
}

EVROverlayError tr_ovw_SetOverlaySortOrder(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, uint32_t unSortOrder){
    return self->SetOverlaySortOrder(ulOverlayHandle, unSortOrder);
}

EVROverlayError tr_ovw_GetOverlaySortOrder(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, uint32_t * punSortOrder){
    return self->GetOverlaySortOrder(ulOverlayHandle, punSortOrder);
}

EVROverlayError tr_ovw_SetOverlayWidthInMeters(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, float fWidthInMeters){
    return self->SetOverlayWidthInMeters(ulOverlayHandle, fWidthInMeters);
}

EVROverlayError tr_ovw_GetOverlayWidthInMeters(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, float * pfWidthInMeters){
    return self->GetOverlayWidthInMeters(ulOverlayHandle, pfWidthInMeters);
}

EVROverlayError tr_ovw_SetOverlayAutoCurveDistanceRangeInMeters(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, float fMinDistanceInMeters, float fMaxDistanceInMeters){
    return self->SetOverlayAutoCurveDistanceRangeInMeters(ulOverlayHandle, fMinDistanceInMeters, fMaxDistanceInMeters);
}

EVROverlayError tr_ovw_GetOverlayAutoCurveDistanceRangeInMeters(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, float * pfMinDistanceInMeters, float * pfMaxDistanceInMeters){
    return self->GetOverlayAutoCurveDistanceRangeInMeters(ulOverlayHandle, pfMinDistanceInMeters, pfMaxDistanceInMeters);
}

EVROverlayError tr_ovw_SetOverlayTextureColorSpace(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, EColorSpace eTextureColorSpace){
    return self->SetOverlayTextureColorSpace(ulOverlayHandle, eTextureColorSpace);
}

EVROverlayError tr_ovw_GetOverlayTextureColorSpace(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, EColorSpace * peTextureColorSpace){
    return self->GetOverlayTextureColorSpace(ulOverlayHandle, peTextureColorSpace);
}

EVROverlayError tr_ovw_SetOverlayTextureBounds(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, VRTextureBounds_t * pOverlayTextureBounds){
    return self->SetOverlayTextureBounds(ulOverlayHandle, pOverlayTextureBounds);
}

EVROverlayError tr_ovw_GetOverlayTextureBounds(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, VRTextureBounds_t * pOverlayTextureBounds){
    return self->GetOverlayTextureBounds(ulOverlayHandle, pOverlayTextureBounds);
}

EVROverlayError tr_ovw_GetOverlayTransformType(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, VROverlayTransformType * peTransformType){
    return self->GetOverlayTransformType(ulOverlayHandle, peTransformType);
}

EVROverlayError tr_ovw_SetOverlayTransformAbsolute(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, ETrackingUniverseOrigin eTrackingOrigin, HmdMatrix34_t * pmatTrackingOriginToOverlayTransform){
    return self->SetOverlayTransformAbsolute(ulOverlayHandle, eTrackingOrigin, pmatTrackingOriginToOverlayTransform);
}

EVROverlayError tr_ovw_GetOverlayTransformAbsolute(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, ETrackingUniverseOrigin * peTrackingOrigin, HmdMatrix34_t * pmatTrackingOriginToOverlayTransform){
    return self->GetOverlayTransformAbsolute(ulOverlayHandle, peTrackingOrigin, pmatTrackingOriginToOverlayTransform);
}

EVROverlayError tr_ovw_SetOverlayTransformTrackedDeviceRelative(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, TrackedDeviceIndex_t unTrackedDevice, HmdMatrix34_t * pmatTrackedDeviceToOverlayTransform){
    return self->SetOverlayTransformTrackedDeviceRelative(ulOverlayHandle, unTrackedDevice, pmatTrackedDeviceToOverlayTransform);
}

EVROverlayError tr_ovw_GetOverlayTransformTrackedDeviceRelative(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, TrackedDeviceIndex_t * punTrackedDevice, HmdMatrix34_t * pmatTrackedDeviceToOverlayTransform){
    return self->GetOverlayTransformTrackedDeviceRelative(ulOverlayHandle, punTrackedDevice, pmatTrackedDeviceToOverlayTransform);
}

EVROverlayError tr_ovw_SetOverlayTransformTrackedDeviceComponent(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, TrackedDeviceIndex_t unDeviceIndex, char * pchComponentName){
    return self->SetOverlayTransformTrackedDeviceComponent(ulOverlayHandle, unDeviceIndex, pchComponentName);
}

EVROverlayError tr_ovw_GetOverlayTransformTrackedDeviceComponent(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, TrackedDeviceIndex_t * punDeviceIndex, char * pchComponentName, uint32_t unComponentNameSize){
    return self->GetOverlayTransformTrackedDeviceComponent(ulOverlayHandle, punDeviceIndex, pchComponentName, unComponentNameSize);
}

EVROverlayError tr_ovw_ShowOverlay(IVROverlay* self, VROverlayHandle_t ulOverlayHandle){
    return self->ShowOverlay(ulOverlayHandle);
}

EVROverlayError tr_ovw_HideOverlay(IVROverlay* self, VROverlayHandle_t ulOverlayHandle){
    return self->HideOverlay(ulOverlayHandle);
}

bool tr_ovw_IsOverlayVisible(IVROverlay* self, VROverlayHandle_t ulOverlayHandle){
    return self->IsOverlayVisible(ulOverlayHandle);
}

EVROverlayError tr_ovw_GetTransformForOverlayCoordinates(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, ETrackingUniverseOrigin eTrackingOrigin, HmdVector2_t coordinatesInOverlay, HmdMatrix34_t * pmatTransform){
    return self->GetTransformForOverlayCoordinates(ulOverlayHandle, eTrackingOrigin, coordinatesInOverlay, pmatTransform);
}

bool tr_ovw_PollNextOverlayEvent(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, VREvent_t * pEvent, uint32_t uncbVREvent){
    return self->PollNextOverlayEvent(ulOverlayHandle, pEvent, uncbVREvent);
}

EVROverlayError tr_ovw_GetOverlayInputMethod(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, VROverlayInputMethod * peInputMethod){
    return self->GetOverlayInputMethod(ulOverlayHandle, peInputMethod);
}

EVROverlayError tr_ovw_SetOverlayInputMethod(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, VROverlayInputMethod eInputMethod){
    return self->SetOverlayInputMethod(ulOverlayHandle, eInputMethod);
}

EVROverlayError tr_ovw_GetOverlayMouseScale(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, HmdVector2_t * pvecMouseScale){
    return self->GetOverlayMouseScale(ulOverlayHandle, pvecMouseScale);
}

EVROverlayError tr_ovw_SetOverlayMouseScale(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, HmdVector2_t * pvecMouseScale){
    return self->SetOverlayMouseScale(ulOverlayHandle, pvecMouseScale);
}

bool tr_ovw_ComputeOverlayIntersection(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, VROverlayIntersectionParams_t * pParams, VROverlayIntersectionResults_t * pResults){
    return self->ComputeOverlayIntersection(ulOverlayHandle, pParams, pResults);
}

bool tr_ovw_HandleControllerOverlayInteractionAsMouse(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, TrackedDeviceIndex_t unControllerDeviceIndex){
    return self->HandleControllerOverlayInteractionAsMouse(ulOverlayHandle, unControllerDeviceIndex);
}

bool tr_ovw_IsHoverTargetOverlay(IVROverlay* self, VROverlayHandle_t ulOverlayHandle){
    return self->IsHoverTargetOverlay(ulOverlayHandle);
}

VROverlayHandle_t tr_ovw_GetGamepadFocusOverlay(IVROverlay* self){
    return self->GetGamepadFocusOverlay();
}

EVROverlayError tr_ovw_SetGamepadFocusOverlay(IVROverlay* self, VROverlayHandle_t ulNewFocusOverlay){
    return self->SetGamepadFocusOverlay(ulNewFocusOverlay);
}

EVROverlayError tr_ovw_SetOverlayNeighbor(IVROverlay* self, EOverlayDirection eDirection, VROverlayHandle_t ulFrom, VROverlayHandle_t ulTo){
    return self->SetOverlayNeighbor(eDirection, ulFrom, ulTo);
}

EVROverlayError tr_ovw_MoveGamepadFocusToNeighbor(IVROverlay* self, EOverlayDirection eDirection, VROverlayHandle_t ulFrom){
    return self->MoveGamepadFocusToNeighbor(eDirection, ulFrom);
}

EVROverlayError tr_ovw_SetOverlayTexture(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, Texture_t * pTexture){
    return self->SetOverlayTexture(ulOverlayHandle, pTexture);
}

EVROverlayError tr_ovw_ClearOverlayTexture(IVROverlay* self, VROverlayHandle_t ulOverlayHandle){
    return self->ClearOverlayTexture(ulOverlayHandle);
}

EVROverlayError tr_ovw_SetOverlayRaw(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, void * pvBuffer, uint32_t unWidth, uint32_t unHeight, uint32_t unDepth){
    return self->SetOverlayRaw(ulOverlayHandle, pvBuffer, unWidth, unHeight, unDepth);
}

EVROverlayError tr_ovw_SetOverlayFromFile(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, char * pchFilePath){
    return self->SetOverlayFromFile(ulOverlayHandle, pchFilePath);
}

EVROverlayError tr_ovw_GetOverlayTexture(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, void ** pNativeTextureHandle, void * pNativeTextureRef, uint32_t * pWidth, uint32_t * pHeight, uint32_t * pNativeFormat, ETextureType * pAPIType, EColorSpace * pColorSpace, VRTextureBounds_t * pTextureBounds){
    return self->GetOverlayTexture(ulOverlayHandle, pNativeTextureHandle, pNativeTextureRef, pWidth, pHeight, pNativeFormat, pAPIType, pColorSpace, pTextureBounds);
}

EVROverlayError tr_ovw_ReleaseNativeOverlayHandle(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, void * pNativeTextureHandle){
    return self->ReleaseNativeOverlayHandle(ulOverlayHandle, pNativeTextureHandle);
}

EVROverlayError tr_ovw_GetOverlayTextureSize(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, uint32_t * pWidth, uint32_t * pHeight){
    return self->GetOverlayTextureSize(ulOverlayHandle, pWidth, pHeight);
}

EVROverlayError tr_ovw_CreateDashboardOverlay(IVROverlay* self, char * pchOverlayKey, char * pchOverlayFriendlyName, VROverlayHandle_t * pMainHandle, VROverlayHandle_t * pThumbnailHandle){
    return self->CreateDashboardOverlay(pchOverlayKey, pchOverlayFriendlyName, pMainHandle, pThumbnailHandle);
}

bool tr_ovw_IsDashboardVisible(IVROverlay* self){
    return self->IsDashboardVisible();
}

bool tr_ovw_IsActiveDashboardOverlay(IVROverlay* self, VROverlayHandle_t ulOverlayHandle){
    return self->IsActiveDashboardOverlay(ulOverlayHandle);
}

EVROverlayError tr_ovw_SetDashboardOverlaySceneProcess(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, uint32_t unProcessId){
    return self->SetDashboardOverlaySceneProcess(ulOverlayHandle, unProcessId);
}

EVROverlayError tr_ovw_GetDashboardOverlaySceneProcess(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, uint32_t * punProcessId){
    return self->GetDashboardOverlaySceneProcess(ulOverlayHandle, punProcessId);
}

void tr_ovw_ShowDashboard(IVROverlay* self, char * pchOverlayToShow){
    self->ShowDashboard(pchOverlayToShow);
}

TrackedDeviceIndex_t tr_ovw_GetPrimaryDashboardDevice(IVROverlay* self){
    return self->GetPrimaryDashboardDevice();
}

EVROverlayError tr_ovw_ShowKeyboard(IVROverlay* self, EGamepadTextInputMode eInputMode, EGamepadTextInputLineMode eLineInputMode, char * pchDescription, uint32_t unCharMax, char * pchExistingText, bool bUseMinimalMode, uint64_t uUserValue){
    return self->ShowKeyboard(eInputMode, eLineInputMode, pchDescription, unCharMax, pchExistingText, bUseMinimalMode, uUserValue);
}

EVROverlayError tr_ovw_ShowKeyboardForOverlay(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, EGamepadTextInputMode eInputMode, EGamepadTextInputLineMode eLineInputMode, char * pchDescription, uint32_t unCharMax, char * pchExistingText, bool bUseMinimalMode, uint64_t uUserValue){
    return self->ShowKeyboardForOverlay(ulOverlayHandle, eInputMode, eLineInputMode, pchDescription, unCharMax, pchExistingText, bUseMinimalMode, uUserValue);
}

uint32_t tr_ovw_GetKeyboardText(IVROverlay* self, char * pchText, uint32_t cchText){
    return self->GetKeyboardText(pchText, cchText);
}

void tr_ovw_HideKeyboard(IVROverlay* self){
    self->HideKeyboard();
}

void tr_ovw_SetKeyboardTransformAbsolute(IVROverlay* self, ETrackingUniverseOrigin eTrackingOrigin, HmdMatrix34_t * pmatTrackingOriginToKeyboardTransform){
    self->SetKeyboardTransformAbsolute(eTrackingOrigin, pmatTrackingOriginToKeyboardTransform);
}

void tr_ovw_SetKeyboardPositionForOverlay(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, HmdRect2_t avoidRect){
    self->SetKeyboardPositionForOverlay(ulOverlayHandle, avoidRect);
}

EVROverlayError tr_ovw_SetOverlayIntersectionMask(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, VROverlayIntersectionMaskPrimitive_t * pMaskPrimitives, uint32_t unNumMaskPrimitives, uint32_t unPrimitiveSize){
    return self->SetOverlayIntersectionMask(ulOverlayHandle, pMaskPrimitives, unNumMaskPrimitives, unPrimitiveSize);
}

EVROverlayError tr_ovw_GetOverlayFlags(IVROverlay* self, VROverlayHandle_t ulOverlayHandle, uint32_t * pFlags){
    return self->GetOverlayFlags(ulOverlayHandle, pFlags);
}

VRMessageOverlayResponse tr_ovw_ShowMessageOverlay(IVROverlay* self, char * pchText, char * pchCaption, char * pchButton0Text, char * pchButton1Text, char * pchButton2Text, char * pchButton3Text){
    return self->ShowMessageOverlay(pchText, pchCaption, pchButton0Text, pchButton1Text, pchButton2Text, pchButton3Text);
}

EVRRenderModelError tr_ovw_LoadRenderModel_Async(IVRRenderModels* self, char * pchRenderModelName, RenderModel_t ** ppRenderModel){
    return self->LoadRenderModel_Async(pchRenderModelName, ppRenderModel);
}

void tr_ovw_FreeRenderModel(IVRRenderModels* self, RenderModel_t * pRenderModel){
    self->FreeRenderModel(pRenderModel);
}

EVRRenderModelError tr_ovw_LoadTexture_Async(IVRRenderModels* self, TextureID_t textureId, RenderModel_TextureMap_t ** ppTexture){
    return self->LoadTexture_Async(textureId, ppTexture);
}

void tr_ovw_FreeTexture(IVRRenderModels* self, RenderModel_TextureMap_t * pTexture){
    self->FreeTexture(pTexture);
}

EVRRenderModelError tr_ovw_LoadTextureD3D11_Async(IVRRenderModels* self, TextureID_t textureId, void * pD3D11Device, void ** ppD3D11Texture2D){
    return self->LoadTextureD3D11_Async(textureId, pD3D11Device, ppD3D11Texture2D);
}

EVRRenderModelError tr_ovw_LoadIntoTextureD3D11_Async(IVRRenderModels* self, TextureID_t textureId, void * pDstTexture){
    return self->LoadIntoTextureD3D11_Async(textureId, pDstTexture);
}

void tr_ovw_FreeTextureD3D11(IVRRenderModels* self, void * pD3D11Texture2D){
    self->FreeTextureD3D11(pD3D11Texture2D);
}

uint32_t tr_ovw_GetRenderModelName(IVRRenderModels* self, uint32_t unRenderModelIndex, char * pchRenderModelName, uint32_t unRenderModelNameLen){
    return self->GetRenderModelName(unRenderModelIndex, pchRenderModelName, unRenderModelNameLen);
}

uint32_t tr_ovw_GetRenderModelCount(IVRRenderModels* self){
    return self->GetRenderModelCount();
}

uint32_t tr_ovw_GetComponentCount(IVRRenderModels* self, char * pchRenderModelName){
    return self->GetComponentCount(pchRenderModelName);
}

uint32_t tr_ovw_GetComponentName(IVRRenderModels* self, char * pchRenderModelName, uint32_t unComponentIndex, char * pchComponentName, uint32_t unComponentNameLen){
    return self->GetComponentName(pchRenderModelName, unComponentIndex, pchComponentName, unComponentNameLen);
}

uint64_t tr_ovw_GetComponentButtonMask(IVRRenderModels* self, char * pchRenderModelName, char * pchComponentName){
    return self->GetComponentButtonMask(pchRenderModelName, pchComponentName);
}

uint32_t tr_ovw_GetComponentRenderModelName(IVRRenderModels* self, char * pchRenderModelName, char * pchComponentName, char * pchComponentRenderModelName, uint32_t unComponentRenderModelNameLen){
    return self->GetComponentRenderModelName(pchRenderModelName, pchComponentName, pchComponentRenderModelName, unComponentRenderModelNameLen);
}

bool tr_ovw_GetComponentState(IVRRenderModels* self, char * pchRenderModelName, char * pchComponentName, VRControllerState_t * pControllerState, RenderModel_ControllerMode_State_t * pState, RenderModel_ComponentState_t * pComponentState){
    return self->GetComponentState(pchRenderModelName, pchComponentName, pControllerState, pState, pComponentState);
}

bool tr_ovw_RenderModelHasComponent(IVRRenderModels* self, char * pchRenderModelName, char * pchComponentName){
    return self->RenderModelHasComponent(pchRenderModelName, pchComponentName);
}

uint32_t tr_ovw_GetRenderModelThumbnailURL(IVRRenderModels* self, char * pchRenderModelName, char * pchThumbnailURL, uint32_t unThumbnailURLLen, EVRRenderModelError * peError){
    return self->GetRenderModelThumbnailURL(pchRenderModelName, pchThumbnailURL, unThumbnailURLLen, peError);
}

uint32_t tr_ovw_GetRenderModelOriginalPath(IVRRenderModels* self, char * pchRenderModelName, char * pchOriginalPath, uint32_t unOriginalPathLen, EVRRenderModelError * peError){
    return self->GetRenderModelOriginalPath(pchRenderModelName, pchOriginalPath, unOriginalPathLen, peError);
}

char * tr_ovw_GetRenderModelErrorNameFromEnum(IVRRenderModels* self, EVRRenderModelError error){
    return self->GetRenderModelErrorNameFromEnum(error);
}

EVRNotificationError tr_ovw_CreateNotification(IVRNotifications* self, VROverlayHandle_t ulOverlayHandle, uint64_t ulUserValue, EVRNotificationType type, char * pchText, EVRNotificationStyle style, NotificationBitmap_t * pImage, VRNotificationId * pNotificationId){
    return self->CreateNotification(ulOverlayHandle, ulUserValue, type, pchText, style, pImage, pNotificationId);
}

EVRNotificationError tr_ovw_RemoveNotification(IVRNotifications* self, VRNotificationId notificationId){
    return self->RemoveNotification(notificationId);
}

char * tr_ovw_GetSettingsErrorNameFromEnum(IVRSettings* self, EVRSettingsError eError){
    return self->GetSettingsErrorNameFromEnum(eError);
}

bool tr_ovw_Sync(IVRSettings* self, bool bForce, EVRSettingsError * peError){
    return self->Sync(bForce, peError);
}

void tr_ovw_SetBool(IVRSettings* self, char * pchSection, char * pchSettingsKey, bool bValue, EVRSettingsError * peError){
    self->SetBool(pchSection, pchSettingsKey, bValue, peError);
}

void tr_ovw_SetInt32(IVRSettings* self, char * pchSection, char * pchSettingsKey, int32_t nValue, EVRSettingsError * peError){
    self->SetInt32(pchSection, pchSettingsKey, nValue, peError);
}

void tr_ovw_SetFloat(IVRSettings* self, char * pchSection, char * pchSettingsKey, float flValue, EVRSettingsError * peError){
    self->SetFloat(pchSection, pchSettingsKey, flValue, peError);
}

void tr_ovw_SetString(IVRSettings* self, char * pchSection, char * pchSettingsKey, char * pchValue, EVRSettingsError * peError){
    self->SetString(pchSection, pchSettingsKey, pchValue, peError);
}

bool tr_ovw_GetBool(IVRSettings* self, char * pchSection, char * pchSettingsKey, EVRSettingsError * peError){
    return self->GetBool(pchSection, pchSettingsKey, peError);
}

int32_t tr_ovw_GetInt32(IVRSettings* self, char * pchSection, char * pchSettingsKey, EVRSettingsError * peError){
    return self->GetInt32(pchSection, pchSettingsKey, peError);
}

float tr_ovw_GetFloat(IVRSettings* self, char * pchSection, char * pchSettingsKey, EVRSettingsError * peError){
    return self->GetFloat(pchSection, pchSettingsKey, peError);
}

void tr_ovw_GetString(IVRSettings* self, char * pchSection, char * pchSettingsKey, char * pchValue, uint32_t unValueLen, EVRSettingsError * peError){
    self->GetString(pchSection, pchSettingsKey, pchValue, unValueLen, peError);
}

void tr_ovw_RemoveSection(IVRSettings* self, char * pchSection, EVRSettingsError * peError){
    self->RemoveSection(pchSection, peError);
}

void tr_ovw_RemoveKeyInSection(IVRSettings* self, char * pchSection, char * pchSettingsKey, EVRSettingsError * peError){
    self->RemoveKeyInSection(pchSection, pchSettingsKey, peError);
}

EVRScreenshotError tr_ovw_RequestScreenshot(IVRScreenshots* self, ScreenshotHandle_t * pOutScreenshotHandle, EVRScreenshotType type, char * pchPreviewFilename, char * pchVRFilename){
    return self->RequestScreenshot(pOutScreenshotHandle, type, pchPreviewFilename, pchVRFilename);
}

EVRScreenshotError tr_ovw_HookScreenshot(IVRScreenshots* self, EVRScreenshotType * pSupportedTypes, int numTypes){
    return self->HookScreenshot(pSupportedTypes, numTypes);
}

EVRScreenshotType tr_ovw_GetScreenshotPropertyType(IVRScreenshots* self, ScreenshotHandle_t screenshotHandle, EVRScreenshotError * pError){
    return self->GetScreenshotPropertyType(screenshotHandle, pError);
}

uint32_t tr_ovw_GetScreenshotPropertyFilename(IVRScreenshots* self, ScreenshotHandle_t screenshotHandle, EVRScreenshotPropertyFilenames filenameType, char * pchFilename, uint32_t cchFilename, EVRScreenshotError * pError){
    return self->GetScreenshotPropertyFilename(screenshotHandle, filenameType, pchFilename, cchFilename, pError);
}

EVRScreenshotError tr_ovw_UpdateScreenshotProgress(IVRScreenshots* self, ScreenshotHandle_t screenshotHandle, float flProgress){
    return self->UpdateScreenshotProgress(screenshotHandle, flProgress);
}

EVRScreenshotError tr_ovw_TakeStereoScreenshot(IVRScreenshots* self, ScreenshotHandle_t * pOutScreenshotHandle, char * pchPreviewFilename, char * pchVRFilename){
    return self->TakeStereoScreenshot(pOutScreenshotHandle, pchPreviewFilename, pchVRFilename);
}

EVRScreenshotError tr_ovw_SubmitScreenshot(IVRScreenshots* self, ScreenshotHandle_t screenshotHandle, EVRScreenshotType type, char * pchSourcePreviewFilename, char * pchSourceVRFilename){
    return self->SubmitScreenshot(screenshotHandle, type, pchSourcePreviewFilename, pchSourceVRFilename);
}

uint32_t tr_ovw_LoadSharedResource(IVRResources* self, char * pchResourceName, char * pchBuffer, uint32_t unBufferLen){
    return self->LoadSharedResource(pchResourceName, pchBuffer, unBufferLen);
}

uint32_t tr_ovw_GetResourceFullPath(IVRResources* self, char * pchResourceName, char * pchResourceTypeDirectory, char * pchPathBuffer, uint32_t unBufferLen){
    return self->GetResourceFullPath(pchResourceName, pchResourceTypeDirectory, pchPathBuffer, unBufferLen);
}

