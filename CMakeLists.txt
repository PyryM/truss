CMAKE_MINIMUM_REQUIRED(VERSION 2.8)
 
PROJECT(truss)

INCLUDE_DIRECTORIES("${PROJECT_SOURCE_DIR}/src")
INCLUDE_DIRECTORIES("${PROJECT_SOURCE_DIR}/extras/bgfx_nanovg")
INCLUDE_DIRECTORIES("${PROJECT_SOURCE_DIR}/extras/websocket_client")
 
INCLUDE(FindPkgConfig)
PKG_SEARCH_MODULE(SDL2 REQUIRED sdl2)
INCLUDE_DIRECTORIES(${SDL2_INCLUDE_DIRS})

add_library( bgfx-shared-libRelease SHARED IMPORTED )
set_target_properties( bgfx-shared-libRelease PROPERTIES IMPORTED_LOCATION "${PROJECT_SOURCE_DIR}/../bgfx/.build/linux64_gcc/bin/libbgfx-shared-libRelease.so")
INCLUDE_DIRECTORIES("${PROJECT_SOURCE_DIR}/../bgfx/include")
INCLUDE_DIRECTORIES("${PROJECT_SOURCE_DIR}/../bx/include")
INCLUDE_DIRECTORIES("${PROJECT_SOURCE_DIR}/../bgfx/3rdparty")

add_library( terra SHARED IMPORTED )
set_target_properties( terra PROPERTIES IMPORTED_LOCATION "${PROJECT_SOURCE_DIR}/../terra/libterra.so")
INCLUDE_DIRECTORIES("${PROJECT_SOURCE_DIR}/../terra/include")

find_package(OpenGL REQUIRED)
include_directories(${OpenGL_INCLUDE_DIRS})
link_directories(${OpenGL_LIBRARY_DIRS})
add_definitions(${OpenGL_DEFINITIONS})
message(STATUS "OPENGL_LIBRARIES={${OPENGL_LIBRARY}}")

ADD_EXECUTABLE(truss src/minimain.cpp src/truss.cpp src/truss_sdl.cpp extras/bgfx_nanovg/nanovg_addon.cpp extras/bgfx_nanovg/nanovg.cpp extras/bgfx_nanovg/nanovg_bgfx_c99.cpp extras/websocket_client/wsclient_addon.cpp extras/websocket_client/easywsclient/easywsclient.cpp)
TARGET_LINK_LIBRARIES(truss bgfx-shared-libRelease ${SDL2_LIBRARIES} terra GL GLU X11 SDL2)

