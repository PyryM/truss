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
  "graphics/renderop.t",
  "graphics/camera.t",
  --"graphics/material.t",
  "graphics/framestats.t",
  "graphics/line.t",
  "graphics/nanovg.t",
  "graphics/taskstage.t",
  "graphics/canvas.t",
  "graphics/immediate.t"
}, graphics)

return graphics
