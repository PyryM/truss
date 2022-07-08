-- imgui/init.t
--
-- imgui meta-module

local moduleutils = require("core/module.t")

-- allow submodules to require("imgui")
local imgui = _preregister{}

moduleutils.include_submodules({
  "imgui/imgui.t",
  "imgui/styling.t",
  "imgui/databar.t"
}, imgui)

return imgui