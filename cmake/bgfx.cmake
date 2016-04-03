include(ExternalProject)

# Get the name of the system as `bx` uses it.
string(TOLOWER "${CMAKE_SYSTEM_NAME}" bx_OS_NAME)
set(bx_COMPILER "gcc") # TODO: cross-platform this.

# Download `bx` and extract source path.
ExternalProject_Add(bx_EXTERNAL
    GIT_REPOSITORY "https://github.com/bkaradzic/bx.git"
    GIT_TAG "master"
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
)

# Recover project paths for additional settings.
ExternalProject_Get_Property(bx_EXTERNAL SOURCE_DIR)
set(bx_INCLUDE_DIR "${SOURCE_DIR}/include")
set(bx_SOURCE_DIR "${SOURCE_DIR}")

# Download `bgfx` and build it using `bx`.
ExternalProject_Add(bgfx_EXTERNAL
    DEPENDS bx_EXTERNAL
    GIT_REPOSITORY "https://github.com/bkaradzic/bgfx.git"
    GIT_TAG "d6bf810fb09f73c559102a7ba88454ce4c5d571c"
    CONFIGURE_COMMAND ""
    BUILD_COMMAND "make" -C <SOURCE_DIR> "BX_DIR=${bx_SOURCE_DIR}" "${bx_OS_NAME}-release64"
    INSTALL_COMMAND ""
    LOG_BUILD 1
)

# Recover project paths for additional settings.
ExternalProject_Get_Property(bgfx_EXTERNAL SOURCE_DIR)
set(bgfx_INCLUDE_DIR "${SOURCE_DIR}/include")
set(bgfx_LIBRARY "${SOURCE_DIR}/.build/${bx_OS_NAME}64_${bx_COMPILER}/bin/libbgfxRelease.a")

# Workaround for https://cmake.org/Bug/view.php?id=15052
file(MAKE_DIRECTORY "${bx_INCLUDE_DIR}")
file(MAKE_DIRECTORY "${bgfx_INCLUDE_DIR}")

# Tell CMake that the external project generated a library so we
# can add dependencies to the library here.
add_library(bgfx STATIC IMPORTED)
add_dependencies(bgfx bgfx_EXTERNAL)
set_target_properties(bgfx PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${bgfx_INCLUDE_DIR};${bx_INCLUDE_DIR}"
    INTERFACE_LINK_LIBRARIES "GL"
    IMPORTED_LOCATION "${bgfx_LIBRARY}"
)
