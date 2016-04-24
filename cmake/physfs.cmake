include(ExternalProject)

# Use this version of physfs.
set(physfs_VERSION "2.0.3")

# Download `physfs` and build it using CMake.
ExternalProject_Add(physfs_EXTERNAL
    URL "https://icculus.org/physfs/downloads/physfs-${physfs_VERSION}.tar.bz2"
    INSTALL_COMMAND ""
    CMAKE_GENERATOR "${CMAKE_GENERATOR}"
    CMAKE_ARGS
    "-DPHYSFS_INTERNAL_ZLIB=TRUE"
    "-DPHYSFS_BUILD_STATIC=FALSE" "-DPHYSFS_BUILD_SHARED=TRUE"
    "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE=<BINARY_DIR>"
    "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG=<BINARY_DIR>"
    "-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY_RELEASE=<BINARY_DIR>"
    "-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY_DEBUG=<BINARY_DIR>"
)

# Recover project paths for additional settings.
ExternalProject_Get_Property(physfs_EXTERNAL SOURCE_DIR BINARY_DIR)
set(physfs_INCLUDE_DIR "${SOURCE_DIR}")
set(physfs_LIBRARIES_DIR "${BINARY_DIR}")
set(physfs_LIBRARY "${physfs_LIBRARIES_DIR}/${CMAKE_SHARED_LIBRARY_PREFIX}physfs${CMAKE_SHARED_LIBRARY_SUFFIX}")
set(physfs_IMPLIB "${physfs_LIBRARIES_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}physfs${CMAKE_STATIC_LIBRARY_SUFFIX}")

# Workaround for https://cmake.org/Bug/view.php?id=15052
file(MAKE_DIRECTORY "${physfs_INCLUDE_DIR}")

# Tell CMake that the external project generated a library so we
# can add dependencies to the library here.
add_library(physfs SHARED IMPORTED)
add_dependencies(physfs physfs_EXTERNAL)
set_target_properties(physfs PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${physfs_INCLUDE_DIR}"
    IMPORTED_LOCATION "${physfs_LIBRARY}"
    IMPORTED_IMPLIB "${physfs_IMPLIB}"
)

# Create an install command to install the shared libs.
copy_truss_libraries(physfs_EXTERNAL "${physfs_LIBRARIES_DIR}")
