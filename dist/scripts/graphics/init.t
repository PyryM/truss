-- graphics/init.t
--
-- graphics metamodule

local moduleutils = require("core/module.t")
local graphics = {}

moduleutils.include_submodules({
  "graphics/pipeline.t",
  "graphics/stage.t",
  "graphics/multiview.t",
  "graphics/composite.t",
  "graphics/renderer.t",
  "graphics/camera.t",
  "graphics/material.t",
  "graphics/framestats.t"
}, graphics)

return graphics
