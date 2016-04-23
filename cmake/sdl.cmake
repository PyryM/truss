include(ExternalProject)

# Use this version of physfs.
set(sdl_VERSION "2.0.4")

# Download `physfs` and build it using CMake.
ExternalProject_Add(sdl_EXTERNAL
    URL "https://libsdl.org/release/SDL2-2.0.4.zip"
    INSTALL_COMMAND ""
)

# Recover project paths for additional settings.
ExternalProject_Get_Property(sdl_EXTERNAL SOURCE_DIR BINARY_DIR)
set(sdl_INCLUDE_DIRS "${BINARY_DIR}/include" "${SOURCE_DIR}/include")
set(sdl_LIBRARIES_DIR "${BINARY_DIR}")
set(sdl_LIBRARY "${sdl_LIBRARIES_DIR}/${CMAKE_SHARED_LIBRARY_PREFIX}SDL2-2.0${CMAKE_SHARED_LIBRARY_SUFFIX}")
set(sdl_IMPLIB "${sdl_LIBRARIES_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}SDL2-2.0${CMAKE_STATIC_LIBRARY_SUFFIX}")

# Workaround for https://cmake.org/Bug/view.php?id=15052
file(MAKE_DIRECTORY "${sdl_INCLUDE_DIR}")

# Tell CMake that the external project generated a library so we
# can add dependencies to the library here.
add_library(sdl SHARED IMPORTED)
add_dependencies(sdl sdl_EXTERNAL)
set_target_properties(sdl PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${sdl_INCLUDE_DIRS}"
    IMPORTED_LOCATION "${sdl_LIBRARY}"
    IMPORTED_IMPLIB "${sdl_IMPLIB}"
)

# Create an install command to install the shared libs.
copy_truss_libraries(sdl_EXTERNAL "${sdl_LIBRARIES_DIR}")
