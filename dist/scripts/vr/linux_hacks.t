-- vr/linux_hacks.t
--
-- deal with linux issues

local badstruct = require("utils/badstruct.t").BadStruct

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
    rAxis           = {offset = 20, ttype = openvr_c.VRControllerAxis_t[5]}
  }

  return ret
end

return m