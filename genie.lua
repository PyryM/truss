-- premake5.lua

-- paths
BGFX_DIR   = "../bgfx"
BX_DIR     = "../bx"
TERRA_DIR  = "../terra"
SDL_DIR    = "../sdl"
PHYSFS_DIR = "../physfs"
STB_DIR    = "../stb"

solution "truss"
   configurations{ "Debug", "Release" }
   platforms{"x64"} -- it's 2015, 64bit is only option
   --architecture "x64" -- needed in premake5 but not genie?
   location "neobuild"

   startproject "truss"

project "truss"
   kind "ConsoleApp"
   language "C++"
   targetdir "bin"
   location "neobuild" 

   local nvg = "src/addons/bgfx_nanovg/"
   local ws  = "src/addons/websocket_client/"

   files{ "src/*.cpp", "src/*.h",                     -- core
           nvg .. "*.cpp", nvg .. "*.h",              -- nanovg
           ws .. "*.cpp", ws .. "*.h", ws .. "*.hpp" -- websocket
         }

   -- link in bgfx, bx, terra, and SDL2
   includedirs{BGFX_DIR .. "/include", TERRA_DIR .. "/include/terra", SDL_DIR .. "/include"}
   includedirs{BGFX_DIR .. "/3rdparty", BX_DIR .. "/include"} -- extra bgfx stuff
   includedirs{PHYSFS_DIR, STB_DIR}                           -- other includes
   libdirs{BGFX_DIR .. "/lib", TERRA_DIR .. "/lib", SDL_DIR .. "/lib/x64", PHYSFS_DIR .. "/lib"}
   links{"terra", "lua51",
         "SDL2", "SDL2main",
         "bgfx-shared-libRelease",
         "physfs"
         }

   configuration "Linux"
      links{"GL", "GLU", "X11"} -- otherwise linker will complain that bgfx is missing things

   configuration "Debug"
      defines{ "DEBUG" }
      flags{ "Symbols" }

   configuration "Release"
      defines{ "NDEBUG" }
      flags { "OptimizeSpeed" }