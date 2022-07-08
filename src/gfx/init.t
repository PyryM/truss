-- gfx/init.t
--
-- meta module for the gfx classes

local moduleutils = require("core/module.t")

-- this allows submodules to require("gfx") without
-- causing an infinite recursion
local gfx = _preregister{}

moduleutils.include_submodules({
  "gfx/common.t",
  "gfx/caps.t",
  "gfx/geometry.t",
  "gfx/formats.t",
  "gfx/vertexdefs.t",
  "gfx/shaders.t",
  "gfx/view.t",
  --"gfx/uniforms.t",
  "gfx/compiled.t",
  "gfx/tagset.t",
  "gfx/rendertarget.t",
  "gfx/texture.t",
  "gfx/resource.t",
  "gfx/imrender.t"
}, gfx)

return gfx
