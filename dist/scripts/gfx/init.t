-- gfx/init.t
--
-- meta module for the gfx classes

local moduleutils = require("core/module.t")

local gfx = {}

moduleutils.includeSubmodules({
    "gfx/camera.t",
    "gfx/geometry.t",
    "gfx/multishaderstage.t",
    "gfx/object3d.t",
    "gfx/pipeline.t",
    "gfx/rendertarget.t",
    "gfx/texture.t",
    "gfx/uniforms.t",
    "gfx/vertexdefs.t",
    "gfx/nanovgstage.t"
}, gfx)

return gfx
