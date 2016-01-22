-- premake5.lua

DEPS_DIR = "../trussdeps"

-- paths
BGFX_DIR   = path.join(DEPS_DIR, "bgfx")
BX_DIR     = path.join(DEPS_DIR, "bx")
TERRA_DIR  = path.join(DEPS_DIR, "terra")
SDL_DIR    = path.join(DEPS_DIR, "sdl")
PHYSFS_DIR = path.join(DEPS_DIR, "physfs")
STB_DIR    = path.join(DEPS_DIR, "stb")

solution "truss"
   configurations{ "Debug", "Release" }
   platforms{"x64"} -- it's 2015, 64bit is only option
   --architecture "x64" -- needed in premake5 but not genie?
   location "build"

   startproject "truss"

project "truss"
   kind "ConsoleApp"
   language "C++"
   targetdir "."
   location "build" 

   local nvg = "src/addons/bgfx_nanovg/"
   local ws  = "src/addons/websocket_client/"

   files{ "src/*.cpp", "src/*.h",                     -- core
           nvg .. "*.cpp", nvg .. "*.h",              -- nanovg
           ws .. "*.cpp", ws .. "*.h", ws .. "*.hpp" -- websocket
         }

   -- link in bgfx, bx, terra, and SDL2
   includedirs{
               path.join(BGFX_DIR, "include"),
               path.join(TERRA_DIR, "include/terra"),
               path.join(SDL_DIR, "include"),
               --path.join(BGFX_DIR, "3rdparty"), 
               path.join(BX_DIR, "include"),
               PHYSFS_DIR,
               STB_DIR
            }

   libdirs{ 
            path.join(BGFX_DIR, "lib"),
            path.join(TERRA_DIR, "lib"),
            path.join(SDL_DIR, "lib/x64"),
            path.join(PHYSFS_DIR, "lib")
           }

   links{
         "terra", "lua51",
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