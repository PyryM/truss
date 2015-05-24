-- premake5.lua
solution "truss"
   configurations{ "Debug", "Release" }
   platforms{"x64"} -- it's 2015, 64bit is only option
   architecture "x64" -- needed in premake5 but not genie?
   location "build"

project "truss"
   kind "ConsoleApp"
   language "C++"
   targetdir "bin"
   location "build" 

   local nvg = "extras/bgfx_nanovg/"

   files{ "src/*.cpp", "src/*.h", -- core
           nvg.."*.cpp" , nvg.."*.h"} -- nanovg
   removefiles{nvg.."nanovg_bgfx.cpp"} -- don't compile c++ bgfx api nanovg

   -- link in bgfx, bx, terra, and SDL2
   includedirs{"deps/bgfx/include", "deps/terra/include", "deps/sdl/include"}
   includedirs{"deps/bgfx/3rdparty", "deps/bx/include"} -- extra bgfx stuff
   libdirs{"deps/bgfx", "deps/terra", "deps/sdl/lib/x64"}
   links{"bgfx-shared-libRelease",
         "terra", "lua51",
         "SDL2", "SDL2main"}

   configuration "Linux"
      links{"GL", "GLU", "X11"} -- otherwise linker will complain that bgfx is missing things

   configuration "Debug"
      defines{ "DEBUG" }
      flags{ "Symbols" }

   configuration "Release"
      defines{ "NDEBUG" }
      flags { "OptimizeSpeed" }