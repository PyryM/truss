cmake_minimum_required(VERSION 3.3)
project(truss)
set(CMAKE_CXX_STANDARD 11)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

include(PrintTargetProperties)

# Install and build required dependencies.
# (BGFX, Terra, PhysFS, STB)
include(bgfx)
include(terra)
include(physfs)
include(stb)

#print_target_properties(bgfx)
#print_properties()

# Get SDL2 from a global install location.
include(FindPkgConfig)
pkg_search_module(SDL2 REQUIRED sdl2)

set(truss_SOURCES
    src/main.cpp
    src/truss.cpp
    src/truss_sdl.cpp
    src/addons/websocket_client/easywsclient.cpp
    src/addons/websocket_client/wsclient_addon.cpp
    src/addons/bgfx_nanovg/nanovg.cpp
    src/addons/bgfx_nanovg/nanovg_addon.cpp
    src/addons/bgfx_nanovg/nanovg_bgfx_c99.cpp
)

add_executable(truss ${truss_SOURCES})
target_compile_definitions(truss PRIVATE
    "${SDL2_DEFINITIONS}"
)
target_include_directories(truss
    PRIVATE
    "${SDL2_INCLUDE_DIRS}"
    "${CMAKE_CURRENT_SOURCE_DIR}/src"
    PUBLIC
    "${CMAKE_CURRENT_SOURCE_DIR}/include"
)
target_link_libraries(truss
    bgfx physfs terra stb
    "${SDL2_LIBRARIES}"
    "-lX11"
)

# Unlike most builds, we want the resulting executable to be installed into
# the root of this directory, as this entire directory comprises a
# distribution package.
set(EXECUTABLE_OUTPUT_PATH "${CMAKE_CURRENT_SOURCE_DIR}")