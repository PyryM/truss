-- gfx/init.t
--
-- meta module for the gfx classes

local moduleutils = require("core/module.t")

local gfx = {}

moduleutils.include_submodules({
  "gfx/common.t",
  "gfx/geometry.t",
  "gfx/vertexdefs.t",
  "gfx/shaders.t",
  "gfx/view.t",
  "gfx/uniforms.t",
  "gfx/rendertarget.t",
  "gfx/texture.t",
  "gfx/resource.t"
}, gfx)

return gfx
