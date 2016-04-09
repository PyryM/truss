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
include(physfs)
include(sfml)
include(stb)
include(terra)

set(truss_SOURCES
    src/main.cpp
    src/truss.cpp
    #src/truss_sdl.cpp
    src/addons/websocket_client/easywsclient.cpp
    src/addons/websocket_client/wsclient_addon.cpp
    src/addons/bgfx_nanovg/nanovg.cpp
    src/addons/bgfx_nanovg/nanovg_addon.cpp
    src/addons/bgfx_nanovg/nanovg_bgfx_c99.cpp
)

add_executable(truss ${truss_SOURCES})
target_include_directories(truss
    PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/src"
    PUBLIC
    "${CMAKE_CURRENT_SOURCE_DIR}/include"
)
target_link_libraries(truss
    bgfx physfs terra stb sfml
    dl GL pthread X11
)

# Fix obscure LuaJIT issue on OSX.
# http://www.freelists.org/post/luajit/luaL-newstate-fails-on-64bit-Mac-cant-set-linker-flags
if("${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -pagezero_size 10000 -image_base 100000000")
endif()

# Unlike most builds, we want the resulting executable to be installed into
# the root of this directory, as this entire directory comprises a
# distribution package.
set(EXECUTABLE_OUTPUT_PATH "${CMAKE_CURRENT_SOURCE_DIR}/dist")
set(RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/dist")
set(RUNTIME_OUTPUT_DIRECTORY_DEBUG "${CMAKE_CURRENT_SOURCE_DIR}/dist")
set(RUNTIME_OUTPUT_DIRECTORY_RELEASE "${CMAKE_CURRENT_SOURCE_DIR}/dist")
