include(ExternalProject)

# Use this version of physfs.
set(terra_RELEASE_DATE "2016-02-26")
set(terra_RELEASE_HASH "2fa8d0a")

# Download `terra` and unzip its binaries.
ExternalProject_Add(terra_EXTERNAL
    URL "https://github.com/zdevito/terra/releases/download/release-${terra_RELEASE_DATE}/terra-${CMAKE_SYSTEM_NAME}-x86_64-${terra_RELEASE_HASH}.zip"
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
)

# Recover project paths for additional settings.
ExternalProject_Get_Property(terra_EXTERNAL SOURCE_DIR)
set(terra_INCLUDE_DIR "${SOURCE_DIR}/include")
set(terra_LIBRARY "${SOURCE_DIR}/lib/libterra.a")

# Workaround for https://cmake.org/Bug/view.php?id=15052
file(MAKE_DIRECTORY "${terra_INCLUDE_DIR}")

# Tell CMake that the external project generated a library so we
# can add dependencies to the library here.
add_library(terra STATIC IMPORTED)
add_dependencies(terra terra_EXTERNAL)
set_target_properties(terra PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${terra_INCLUDE_DIR}"
    INTERFACE_LINK_LIBRARIES "dl"
    IMPORTED_LOCATION "${terra_LIBRARY}"
)