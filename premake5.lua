-- premake5.lua

-- paths
BGFX_DIR  = "../bgfx"
BX_DIR    = "../bx"
TERRA_DIR = "../terra"
SDL_DIR   = "../sdl" 

solution "truss"
   configurations{ "Debug", "Release" }
   platforms{"x64"} -- it's 2015, 64bit is only option
   architecture "x64" -- needed in premake5 but not genie?
   location "build"

   startproject "truss"

project "truss"
   kind "ConsoleApp"
   language "C++"
   targetdir "bin"
   location "build" 

   local nvg = "src/bgfx_nanovg/"
   local ws  = "src/websocket_client/"

   files{ "src/*.cpp", "src/*.h",                     -- core
           nvg .. "*.cpp", nvg .. "*.h",              -- nanovg
           ws .. "*.cpp", ws .. "*.h", ws .. "*.hpp", -- websocket
           BGFX_DIR .. "/src/amalgamated.cpp"         -- bgfx
         }

   -- link in bgfx, bx, terra, and SDL2
   includedirs{BGFX_DIR .. "/include", TERRA_DIR .. "/include", SDL_DIR .. "/include"}
   includedirs{BGFX_DIR .. "/3rdparty", BX_DIR .. "/include"} -- extra bgfx stuff
   libdirs{BGFX_DIR, TERRA_DIR, SDL_DIR .. "/lib/x64"}
   links{"terra", "lua51",
         "SDL2", "SDL2main"}

   configuration "Linux"
      links{"GL", "GLU", "X11"} -- otherwise linker will complain that bgfx is missing things

   configuration "Debug"
      defines{ "DEBUG" }
      flags{ "Symbols" }

   configuration "Release"
      defines{ "NDEBUG" }
      flags { "OptimizeSpeed" }