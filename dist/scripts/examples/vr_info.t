-- vr_info.t
--
-- logs some openvr information (recommended target size, projection matrices)
-- and quits

local openvr = require("vr/openvr.t")

function init()
  openvr.init()
  openvr.print_debug_info()
end

function update()
  truss.quit()
end
