-- gfx/bgfx.t
--
-- bgfx C api

local modutils = require("core/module.t")

local bgfx_c = terralib.includec("bgfx_truss.c99.h")
local bgfx_const = require("./bgfx_constants.t")

local bgfx = {}
modutils.reexport_without_prefix(bgfx_c, "bgfx_", bgfx)
modutils.reexport_without_prefix(bgfx_c, "BGFX_", bgfx)
modutils.reexport_without_prefix(bgfx_const, "BGFX_", bgfx)
bgfx.raw_functions = bgfx_c
bgfx.raw_constants = bgfx_const
function bgfx.check_handle(h) 
  return h.idx ~= bgfx.INVALID_HANDLE 
end

return bgfx
