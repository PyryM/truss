-- gfx/init.t
--
-- meta module for the gfx classes

local moduleutils = require("core/module.t")

local gfx = {}

moduleutils.include_submodules({
    "gfx/geometry.t",
    "gfx/vertexdefs.t",
    "gfx/common.t"
}, gfx)

return gfx
