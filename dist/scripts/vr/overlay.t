-- vr/overlay.t
--
-- openvr overlays, should not be directly imported,
-- instead, init openvr in 'overlay' mode and use openvr.create_overlay()

local m = {}
local openvr = nil
local openvr_c = nil
local class = require("class")
local bgfx = require("gfx/bgfx.t")
local create_overlay_terra = nil
local OverlayInfo = nil

function m.init(parent)
  openvr = parent
  openvr_c = openvr.c_api
  m.overlayptr = openvr.addonfuncs.truss_openvr_get_overlay(openvr.addonptr)
  OverlayInfo = struct {
    err: openvr_c.EVROverlayError;
    handle: openvr_c.VROverlayHandle_t;
  }
  create_overlay_terra = terra(ptr: &openvr_c.IVROverlay, name: &int8, fname: &int8) : OverlayInfo
    var info: OverlayInfo
    info.err = 0
    info.handle = 0
    info.err = openvr_c.tr_ovw_CreateOverlay(ptr, name, fname, &(info.handle))
    return info
  end
end

local created_overlays = {}
function m.create_overlay(options)
  return m.Overlay(options)
end

function m.shutdown()
  for _, overlay in pairs(created_overlays) do
    overlay:set_texture(nil)
  end
end

local Overlay = class("Overlay")
m.Overlay = Overlay

local function check_error(err)
  if err == openvr_c.EVROverlayError_VROverlayError_None then
    return true
  else
    log.error("overlay error: " .. tostring(err))
    local serr = ffi.string(openvr_c.tr_ovw_GetOverlayErrorNameFromEnum(m.overlayptr, err))
    truss.error("Overlay error: " .. tostring(err) .. " : " .. serr)
    return false
  end
end

function Overlay:init(options)
  local name = options and options.name
  if not name then truss.error("Overlays *must* have a name.") end
  if created_overlays[name] then 
    truss.error("Overlay " .. name .. " already exists.")
  end
  created_overlays[name] = self
  self._name = name
  self._ovr_m34 = terralib.new(openvr_c.HmdMatrix34_t)
  self._ovr_tex = terralib.new(openvr_c.Texture_t)
  self._info = create_overlay_terra(m.overlayptr, name, name)
  check_error(self._info.err)
  self._handle = self._info.handle
end

function Overlay:set_color(color)
  local r, g, b = 1,1,1
  if color.elem then -- Vector
    r, g, b = color:components()
  else -- assume list
    r, g, b = unpack(color) 
  end
  check_error(openvr_c.tr_ovw_SetOverlayColor(m.overlayptr, self._handle, r, g, b))
  return self
end

function Overlay:set_width(w)
  check_error(openvr_c.tr_ovw_SetOverlayWidthInMeters(m.overlayptr, self._handle, w))
  return self
end

function Overlay:set_visible(v)
  if v then
    check_error(openvr_c.tr_ovw_ShowOverlay(m.overlayptr, self._handle))
  else
    check_error(openvr_c.tr_ovw_HideOverlay(m.overlayptr, self._handle))
  end
  return self
end

function Overlay:set_absolute_transform(tf, origin)
  local vr_origin
  if origin == "standing" or origin == nil then
    vr_origin = openvr_c.ETrackingUniverseOrigin_TrackingUniverseStanding
  elseif origin == "sitting" then
    vr_origin = openvr_c.ETrackingUniverseOrigin_TrackingUniverseSeated
  else
    truss.error("Unknown origin " .. origin)
  end
  openvr.mat_to_openvr_mat34(tf, self._ovr_m34)
  check_error(openvr_c.tr_ovw_SetOverlayTransformAbsolute(
    m.overlayptr, self._handle, vr_origin, self._ovr_m34))
  return self
end

function Overlay:set_relative_transform(tf, device_index)
  device_index = device_index or 0 -- default to hmd (always idx 0)
  openvr.mat_to_openvr_mat34(tf, self._ovr_m34)
  check_error(openvr_c.tr_ovw_SetOverlayTransformTrackedDeviceRelative(
    m.overlayptr, self._handle, device_index, self._ovr_m34))
  return self
end

function Overlay:set_texture(tex)
  if tex == nil then
    check_error(openvr_c.tr_ovw_ClearOverlayTexture(m.overlayptr, self._handle))
    self._tex = nil
    return self
  end

  self._tex = tex -- keep this around to prevent garbage collection issues
  local bgfx_tex_handle = tex._handle or tex:get_attachment_handle(1)
  local raw_handle = bgfx.get_internal_texture_ptr(bgfx_tex_handle)
  if raw_handle == nil then 
    truss.error("Texture has no backing handle... maybe trying too early?") 
  end
  self._ovr_tex.handle = raw_handle
  self._ovr_tex.eType = openvr_c.ETextureType_TextureType_DirectX
  self._ovr_tex.eColorSpace = openvr_c.EColorSpace_ColorSpace_Auto
  self:update_texture()
  return self
end

function Overlay:update_texture()
  if not self._tex then return self end
  check_error(openvr_c.tr_ovw_SetOverlayTexture(m.overlayptr, 
    self._handle, self._ovr_tex))
  return self
end

return m