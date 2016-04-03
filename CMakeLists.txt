cmake_minimum_required(VERSION 3.3)
project(truss)
set(CMAKE_CXX_STANDARD 11)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
include(PrintTargetProperties)

# Install and build required dependencies.
# (BGFX, Terra, PhysFS)
add_subdirectory(external)

print_target_properties(bgfx)
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
    "${SDL2_LIBRARIES}"
    bgfx physfs terra stb
    "-ldl" "-lpthread" "-lGL"
)
