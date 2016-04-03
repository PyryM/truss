cmake_minimum_required(VERSION 3.3)
project(truss)
set(CMAKE_CXX_STANDARD 11)

# Install and build required dependencies.
# (BGFX, Terra, PhysFS)
add_subdirectory(external)

# Get SDL2 from a global install location.
include(FindPkgConfig)
pkg_search_module(SDL2 REQUIRED sdl2)

#find_package(OpenGL REQUIRED)
#include_directories(${OpenGL_INCLUDE_DIRS})
#add_definitions(${OpenGL_DEFINITIONS})
#link_directories(${OpenGL_LIBRARY_DIRS})
#message(STATUS "OPENGL_LIBRARIES={${OPENGL_LIBRARY}}")

set(truss_SOURCES
    src/main.cpp
    src/truss.cpp
    src/truss_sdl.cpp
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
)
