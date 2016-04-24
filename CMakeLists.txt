cmake_minimum_required(VERSION 3.3)

project(truss)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
set(CMAKE_CXX_STANDARD 11)
include(utils)

# Unlike most builds, we want the resulting executable to be installed into
# the root of the `dist` directory, as this entire directory comprises a
# distribution package.
set(DIST_DIR "${CMAKE_CURRENT_SOURCE_DIR}/dist")

# Create the main `truss` target.
set(truss_HEADERS
    src/truss.h
    src/trussapi.h
    src/addons/sdl/sdl_addon.h
    src/addons/wsclient/easywsclient.hpp
    src/addons/wsclient/wsclient_addon.h
    src/addons/nanovg/nanovg.h
    src/addons/nanovg/nanovg_addon.h
)
set(truss_SOURCES
    src/main.cpp
    src/truss/core.cpp
    src/truss/interpreter.cpp
    src/truss/trussapi.cpp
    src/external/tinythread.cpp
    src/addons/sdl/sdl_addon.cpp
    src/addons/wsclient/easywsclient.cpp
    src/addons/wsclient/wsclient_addon.cpp
    src/addons/nanovg/nanovg.cpp
    src/addons/nanovg/nanovg_addon.cpp
    src/addons/nanovg/nanovg_bgfx_c99.cpp
)
add_executable(truss ${truss_SOURCES} ${truss_HEADERS})

# Install and build required dependencies.
# (BGFX, Terra, PhysFS, STB)
include(bgfx)
include(physfs)
include(sdl)
include(stb)
include(terra)

# Configure truss to handle include directories properly.
target_include_directories(truss
    PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/src"
    PUBLIC
    "${CMAKE_CURRENT_SOURCE_DIR}/include"
)

# Link against required dependencies.
target_link_libraries(truss
    bgfx physfs terra stb sdl
)

# Fix obscure LuaJIT issue on OSX.
# http://www.freelists.org/post/luajit/luaL-newstate-fails-on-64bit-Mac-cant-set-linker-flags
if("${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -pagezero_size 10000 -image_base 100000000")
endif()

# Configure the RPATH for Linux and OSX.
SET(CMAKE_SKIP_BUILD_RPATH TRUE)
SET(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)
set_target_properties(truss PROPERTIES
    INSTALL_RPATH "./lib"
    RUNTIME_OUTPUT_DIRECTORY "${DIST_DIR}"
    RUNTIME_OUTPUT_DIRECTORY_DEBUG "${DIST_DIR}"
    RUNTIME_OUTPUT_DIRECTORY_RELEASE "${DIST_DIR}"
)
