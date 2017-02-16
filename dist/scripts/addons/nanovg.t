-- addons/nanovg.t
--
-- nanovg

local modutils = truss.require("core/module.t")
local nanovg_c = terralib.includec("nanovg_terra.h")

local nanovg = {}
modutils.reexport_without_prefix(nanovg_c, "nvg", nanovg)
modutils.reexport_without_prefix(nanovg_c, "NVG", nanovg)

return nanovg
