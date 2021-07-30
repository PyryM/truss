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
)
set(truss_SOURCES
    src/main.cpp
    src/truss/core.cpp
    src/truss/interpreter.cpp
    src/truss/trussapi.cpp
)

add_executable(truss ${truss_SOURCES} ${truss_HEADERS})

# Install and build required dependencies.
# (Terra, PhysFS)
include(physfs)
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
    physfs terra
)

if("${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
    # Fix obscure LuaJIT issue on OSX.
    # http://www.freelists.org/post/luajit/luaL-newstate-fails-on-64bit-Mac-cant-set-linker-flags
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -pagezero_size 10000 -image_base 100000000")

    # Fix linking error with missing core libraries on OSX.
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -framework CoreFoundation -framework Carbon -framework IOKit")
endif()

# Configure the RPATH for Linux and OSX.
set(CMAKE_SKIP_BUILD_RPATH TRUE)
set(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)
set(CMAKE_MACOSX_RPATH TRUE)
set_target_properties(truss PROPERTIES
    INSTALL_RPATH "./lib"
    RUNTIME_OUTPUT_DIRECTORY "${DIST_DIR}"
    RUNTIME_OUTPUT_DIRECTORY_DEBUG "${DIST_DIR}"
    RUNTIME_OUTPUT_DIRECTORY_RELEASE "${DIST_DIR}"
    )

  
# use, i.e. don't skip the full RPATH for the build tree
set(CMAKE_SKIP_BUILD_RPATH FALSE)
# when building, don't use the install RPATH already
# (but later on when installing)
set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)

set(CMAKE_BUILD_RPATH "./lib")


# If the user attempts to install, politely inform them that it has no effect.
install(CODE "MESSAGE(WARNING \"\nTruss cannot be installed to the system. Typically, the 'dist' directory is re-distributed as a self-contained application.\")")
