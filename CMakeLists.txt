CMAKE_MINIMUM_REQUIRED(VERSION 2.8)

# Change these to point where you installed these things:
set(TERRADIR "/home/pmatikai/Projects/terra")
set(BGFXDIR "/home/pmatikai/Projects/bgfx")
set(BXDIR "/home/pmatikai/Projects/bx")
 
PROJECT(truss)

INCLUDE_DIRECTORIES("${PROJECT_SOURCE_DIR}/src")
INCLUDE_DIRECTORIES("${PROJECT_SOURCE_DIR}/include")
INCLUDE_DIRECTORIES("${PROJECT_SOURCE_DIR}/extras/bgfx_nanovg")
INCLUDE_DIRECTORIES("${PROJECT_SOURCE_DIR}/extras/websocket_client")
 
INCLUDE(FindPkgConfig)
PKG_SEARCH_MODULE(SDL2 REQUIRED sdl2)
INCLUDE_DIRECTORIES(${SDL2_INCLUDE_DIRS})

add_library( bgfx-shared-libRelease SHARED IMPORTED )
set_target_properties( bgfx-shared-libRelease PROPERTIES IMPORTED_LOCATION "${BGFXDIR}/.build/linux64_gcc/bin/libbgfx-shared-libRelease.so")
INCLUDE_DIRECTORIES("${BGFXDIR}/include")
INCLUDE_DIRECTORIES("${BXDIR}/include")
INCLUDE_DIRECTORIES("${BGFXDIR}/3rdparty")

add_library( terra SHARED IMPORTED )
set_target_properties( terra PROPERTIES IMPORTED_LOCATION "${TERRADIR}/libterra.so")
INCLUDE_DIRECTORIES("${TERRADIR}/include")

find_package(OpenGL REQUIRED)
include_directories(${OpenGL_INCLUDE_DIRS})
link_directories(${OpenGL_LIBRARY_DIRS})
add_definitions(${OpenGL_DEFINITIONS})
message(STATUS "OPENGL_LIBRARIES={${OPENGL_LIBRARY}}")

ADD_EXECUTABLE(truss src/minimain.cpp src/truss.cpp src/truss_sdl.cpp extras/bgfx_nanovg/nanovg_addon.cpp extras/bgfx_nanovg/nanovg.cpp extras/bgfx_nanovg/nanovg_bgfx_c99.cpp extras/websocket_client/wsclient_addon.cpp extras/websocket_client/easywsclient/easywsclient.cpp)
set_property(TARGET truss PROPERTY BUILD_WITH_INSTALL_RPATH TRUE)
TARGET_LINK_LIBRARIES(truss bgfx-shared-libRelease ${SDL2_LIBRARIES} terra GL GLU X11 SDL2)

