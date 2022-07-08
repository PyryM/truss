-- vr/linux_hacks.t
--
-- deal with linux issues

local BadStruct = require("util/badstruct.t").BadStruct

local m = {}

function m.init_bad_structs(openvr_c)
  local ret = {}

  -- typedef struct VRControllerState_t
  -- {
  --   uint32_t unPacketNum;
  --   uint64_t ulButtonPressed;
  --   uint64_t ulButtonTouched;
  --   struct VRControllerAxis_t rAxis[5]; //struct vr::VRControllerAxis_t[5]
  -- } VRControllerState_t;
  ret.VRControllerState_t = BadStruct{
    unPacketNum     = {offset =  0, ttype = uint32}, -- correct C packing:
    ulButtonPressed = {offset =  4, ttype = uint64}, -- offset = 8
    ulButtonTouched = {offset = 12, ttype = uint64},
    rAxis           = {offset = 20, ttype = openvr_c.VRControllerAxis_t, 
                       is_arr = true, count = 5}
  }

  -- typedef struct RenderModel_t
  -- {
  --   struct RenderModel_Vertex_t * rVertexData; // const struct vr::RenderModel_Vertex_t *
  --   uint32_t unVertexCount;
  --   uint16_t * rIndexData; // const uint16_t *
  --   uint32_t unTriangleCount;
  --   TextureID_t diffuseTextureId;
  -- } RenderModel_t;
  ret.RenderModel_t = BadStruct{
    rVertexData      = {offset =  0, ttype = &openvr_c.RenderModel_Vertex_t},
    unVertexCount    = {offset =  8, ttype = uint32},
    rIndexData       = {offset = 12, ttype = &uint16},
    unTriangleCount  = {offset = 20, ttype = uint32},
    diffuseTextureId = {offset = 24, ttype = openvr_c.TextureID_t} 
  }

  return ret
end

return m