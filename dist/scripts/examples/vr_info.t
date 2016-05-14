-- vr_info.t
--
-- logs some openvr information (recommended target size, projection matrices)
-- and quits

terralib = core.terralib
truss = core.truss

local openvr = require("vr/openvr.t")

function init()
    openvr.init()
    openvr.printDebugInfo()
end

function update()
    truss.truss_stop_interpreter(core.TRUSS_ID)
end
