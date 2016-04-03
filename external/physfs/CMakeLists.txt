include(ExternalProject)

# Use this version of physfs.
set(physfs_VERSION "2.0.3")

# Download `physfs` and build it using CMake.
include(ExternalProject)
ExternalProject_Add(physfs_EXTERNAL
    URL "https://icculus.org/physfs/downloads/physfs-${physfs_VERSION}.tar.bz2"
    INSTALL_COMMAND ""
)

# Recover project paths for additional settings.
ExternalProject_Get_Property(physfs_EXTERNAL SOURCE_DIR BINARY_DIR)
set(physfs_INCLUDE_DIR "${SOURCE_DIR}")
set(physfs_LIBRARY "${BINARY_DIR}/libphysfs.a")

# Workaround for https://cmake.org/Bug/view.php?id=15052
file(MAKE_DIRECTORY "${physfs_INCLUDE_DIR}")

# Tell CMake that the external project generated a library so we
# can add dependencies to the library here.
add_library(physfs STATIC IMPORTED GLOBAL)
add_dependencies(physfs physfs_EXTERNAL)
set_property(TARGET physfs
    PROPERTY INTERFACE_INCLUDE_DIRECTORIES
    "${physfs_INCLUDE_DIR}"
)
set_property(TARGET physfs
    PROPERTY IMPORTED_LOCATION
    "${physfs_LIBRARY}"
)
