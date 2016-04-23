cmake_minimum_required(VERSION 3.3)
set(CMAKE_USER_MAKE_RULES_OVERRIDE
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/c_flag_overrides.cmake")
set(CMAKE_USER_MAKE_RULES_OVERRIDE_CXX
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/cxx_flag_overrides.cmake")

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
    src/truss_sdl.h
    src/addons/websocket_client/easywsclient.hpp
    src/addons/websocket_client/wsclient_addon.h
    src/addons/bgfx_nanovg/nanovg.h
    src/addons/bgfx_nanovg/nanovg_addon.h
)
set(truss_SOURCES
    src/main.cpp
    src/truss.cpp
    src/tinythread.cpp
    src/truss_sdl.cpp
    src/addons/websocket_client/easywsclient.cpp
    src/addons/websocket_client/wsclient_addon.cpp
    src/addons/bgfx_nanovg/nanovg.cpp
    src/addons/bgfx_nanovg/nanovg_addon.cpp
    src/addons/bgfx_nanovg/nanovg_bgfx_c99.cpp
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
