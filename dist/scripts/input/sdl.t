local modutils = require("core/module.t")
local sdl_c_raw = terralib.includec("sdl/sdl_minimal.h")

local sdl_c = modutils.reexport_without_prefix(sdl_c_raw, "SDL_")
sdl_c.raw = sdl_c_raw

if truss.os == "Windows" then
  terralib.linklibrary("SDL2")
elseif truss.os == "OSX" then
  -- HMM not sure why I need to do it this way
  terralib.linklibrary("lib/libSDL2-2.0.dylib")
else
  terralib.linklibrary("lib/libSDL2-2.0.so")
end

return sdl_c
