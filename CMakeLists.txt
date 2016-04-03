cmake_minimum_required(VERSION 3.3)
set(CMAKE_USER_MAKE_RULES_OVERRIDE
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/c_flag_overrides.cmake")
set(CMAKE_USER_MAKE_RULES_OVERRIDE_CXX
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/cxx_flag_overrides.cmake")

project(truss)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

set(CMAKE_CXX_STANDARD 11)

include(PrintTargetProperties)

# Install and build required dependencies.
# (BGFX, Terra, PhysFS, STB)
include(bgfx)
include(terra)
include(physfs)
include(stb)

# Get SDL2 from a global install location.
find_package(SDL2 REQUIRED)

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
target_include_directories(truss
    PRIVATE
    "${SDL2_INCLUDE_DIR}"
    "${CMAKE_CURRENT_SOURCE_DIR}/src"
    PUBLIC
    "${CMAKE_CURRENT_SOURCE_DIR}/include"
)
target_link_libraries(truss
    bgfx physfs terra stb
    "${SDL2_LIBRARY}"
    "-lX11"
)

# Unlike most builds, we want the resulting executable to be installed into
# the root of this directory, as this entire directory comprises a
# distribution package.
set(EXECUTABLE_OUTPUT_PATH "${CMAKE_CURRENT_SOURCE_DIR}")
set(RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
set(RUNTIME_OUTPUT_DIRECTORY_DEBUG "${CMAKE_CURRENT_SOURCE_DIR}")
set(RUNTIME_OUTPUT_DIRECTORY_RELEASE "${CMAKE_CURRENT_SOURCE_DIR}")
