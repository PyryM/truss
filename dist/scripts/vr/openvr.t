-- vr/openvr.t
--
-- wrapper for the openvr api

local m = {}
local class = require("class")

function m.init()
    if raw_addons.openvr ~= nil then
        m.openvr_c = terralib.includec("include/openvr_c.h")
        local addonfuncs = raw_addons.openvr.functions
        local addonptr   = raw_addons.openvr.pointer
        local success = addonfuncs.truss_openvr_init(addonptr, 0)
        if success > 0 then
            m.sysptr = terralib.cast(addonfuncs.truss_openvr_get_system(addonptr),
                                     &[m.openvr_c.IVRSystem])
            m.compositorptr = terralib.cast(addonfuncs.truss_openvr_get_compositor(addonptr),
                                            &[m.openvr_c.IVRCompositor])
            m.addonfuncs = addonfuncs
            m.addonptr = addonptr
        else
            local errorstr = ffi.string(addonfuncs.truss_openvr_get_last_error(addonptr))
            log.error("OpenVR init error: " .. errorstr)
        end
    else
        log.error("vr/openvr.t: interpreter does not have openvr attached!")
    end
end

local terra derefInt(x: &uint32) : uint32
    return @x
end

function m.getRecommendedTargetSize()
    local w = terralib.new(uint32)
    local h = terralib.new(uint32)
    m.openvr_c.tr_ovw_GetRecommendedRenderTargetSize(m.sysptr, w, h)
    log.info("W: " .. w, "H: " .. h)
    return tonumber(w), tonumber(h)
end
