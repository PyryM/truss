-- imgui/init.t
--
-- imgui meta-module

local moduleutils = require("core/module.t")

local imgui = moduleutils.include_submodules({
  "imgui/imgui.t",
  "imgui/styling.t",
  "imgui/databar.t"
})

return imgui