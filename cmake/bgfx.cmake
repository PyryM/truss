include(ExternalProject)

# Download `bx` and extract source path.
ExternalProject_Add(bx_EXTERNAL
    GIT_REPOSITORY "https://github.com/bkaradzic/bx.git"
    GIT_TAG "master"
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
)

# Recover BX tool paths for additional settings.
ExternalProject_Get_Property(bx_EXTERNAL SOURCE_DIR)
set(bx_DIR "${SOURCE_DIR}")
set(bx_INCLUDE_DIR "${SOURCE_DIR}/include")
string(TOLOWER "${CMAKE_SYSTEM_NAME}" bx_OS_NAME)
set(bx_GENIE "${SOURCE_DIR}/tools/bin/${bx_OS_NAME}/genie")

# Configure platform-specific build commands.
if("${CMAKE_GENERATOR}" MATCHES "Visual Studio 14 2015.*")
    set(bx_OS_SHORT "win")
    set(bx_COMPILER "vs2015")
    set(bgfx_CONFIGURE_COMMAND "${CMAKE_COMMAND}" -E env "BX_DIR=${bx_DIR}" "${bx_GENIE}.exe" "${bx_COMPILER}")
    set(bgfx_BUILD_COMMAND "devenv" "<SOURCE_DIR>/.build/projects/${bx_COMPILER}/bgfx.sln" /Build Release|x64)
elseif("${CMAKE_GENERATOR}" STREQUAL "gcc")
    set(bx_OS_SHORT "${bx_OS_NAME}")
    set(bx_COMPILER "gcc")
    set(bgfx_CONFIGURE_COMMAND "")
    set(bgfx_BUILD_COMMAND "make" -C <SOURCE_DIR> "BX_DIR=${bx_SOURCE_DIR}" "${bx_OS_NAME}-release64")
else()
    message(FATAL_ERROR "BGFX does not support the compiler '${CMAKE_GENERATOR}'.")
endif()

# Download `bgfx` and build it using `bx`.
ExternalProject_Add(bgfx_EXTERNAL
    DEPENDS bx_EXTERNAL
    GIT_REPOSITORY "https://github.com/bkaradzic/bgfx.git"
    GIT_TAG "d6bf810fb09f73c559102a7ba88454ce4c5d571c"
    CONFIGURE_COMMAND ${bgfx_CONFIGURE_COMMAND}
    BUILD_COMMAND ${bgfx_BUILD_COMMAND}
    INSTALL_COMMAND ""
    BUILD_IN_SOURCE 1
    # LOG_BUILD 1
)

# Recover BGFX paths for additional settings.
ExternalProject_Get_Property(bgfx_EXTERNAL SOURCE_DIR)
set(bgfx_INCLUDE_DIR "${SOURCE_DIR}/include")
set(bgfx_LIBRARY "${SOURCE_DIR}/.build/${bx_OS_SHORT}64_${bx_COMPILER}/bin/${CMAKE_STATIC_LIBRARY_PREFIX}bgfxRelease${CMAKE_STATIC_LIBRARY_SUFFIX}")

# Workaround for https://cmake.org/Bug/view.php?id=15052
file(MAKE_DIRECTORY "${bx_INCLUDE_DIR}")
file(MAKE_DIRECTORY "${bgfx_INCLUDE_DIR}")

# Tell CMake that the external project generated a library so we
# can add dependencies to the library here.
add_library(bgfx STATIC IMPORTED)
add_dependencies(bgfx bgfx_EXTERNAL)
set_target_properties(bgfx PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${bgfx_INCLUDE_DIR};${bx_INCLUDE_DIR}"
    # INTERFACE_LINK_LIBRARIES "libGL"
    IMPORTED_LOCATION "${bgfx_LIBRARY}"
)
