-- gfx/init.t
--
-- meta module for the gfx classes

local moduleutils = require("core/module.t")

-- we've moved the actual table into its own module
-- so that submodules can require it without causing
-- an infinite recursion with this init.t
local gfx = require("./_gfx.t")

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
