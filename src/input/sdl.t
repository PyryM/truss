local build = require("build/build.t")
local modutils = require("core/module.t")
local sdl_c_raw = build.includec("sdl/sdl_minimal.h")

local sdl_c = modutils.reexport_without_prefix(sdl_c_raw, "SDL_")
sdl_c.raw = sdl_c_raw

if build.is_native() then
  if truss.os == "Windows" then
    build.linklibrary("lib/SDL2")
  elseif truss.os == "OSX" then
    -- HMM not sure why I need to do it this way
    build.linklibrary("lib/libSDL2-2.0.dylib")
  else
    build.linklibrary("lib/libSDL2-2.0.so")
  end
end

return sdl_c
