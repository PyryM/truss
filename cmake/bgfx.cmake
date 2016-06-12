include(ExternalProject)

# Download `bx` and extract source path.
ExternalProject_Add(bx_EXTERNAL
    GIT_REPOSITORY "https://github.com/bkaradzic/bx.git"
    GIT_TAG "c989434ad78398241e8792efc992290ee2823555"
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
)

# Recover BX tool paths for additional settings.
ExternalProject_Get_Property(bx_EXTERNAL SOURCE_DIR)
set(bx_DIR "${SOURCE_DIR}")
set(bx_INCLUDE_DIR "${SOURCE_DIR}/include")
string(TOLOWER "${CMAKE_SYSTEM_NAME}" bx_SYSTEM_NAME)
set(bx_GENIE "${SOURCE_DIR}/tools/bin/${bx_SYSTEM_NAME}/genie")

# Create a system name compatible with BGFX build scripts.
if("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")
    set(bgfx_SYSTEM_NAME "win")
elseif("${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
    set(bgfx_SYSTEM_NAME "osx")
    set(bgfx_COMPILER "clang")
    set(bgfx_GENIE_GCC "osx")
elseif("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")
    set(bgfx_SYSTEM_NAME "linux")
    set(bgfx_COMPILER "gcc")
    set(bgfx_GENIE_GCC "linux-gcc")
else()
    message(FATAL_ERROR "BGFX does not support the system '${CMAKE_SYSTEM_NAME}'.")
endif()

# Configure platform-specific build commands.
if("${CMAKE_GENERATOR}" MATCHES "Visual Studio 14 2015")
    set(bgfx_COMPILER "vs2015")
    set(bgfx_CONFIGURE_COMMAND "${CMAKE_COMMAND}" -E env "BX_DIR=${bx_DIR}" "${bx_GENIE}${CMAKE_EXECUTABLE_SUFFIX}" --with-shared-lib "${bgfx_COMPILER}")
    set(bgfx_BUILD_COMMAND "devenv" "<SOURCE_DIR>/.build/projects/${bgfx_COMPILER}/bgfx.sln" /Build Release|x64)
elseif("${CMAKE_GENERATOR}" STREQUAL "Unix Makefiles")
    set(bgfx_CONFIGURE_COMMAND "${CMAKE_COMMAND}" -E env "BX_DIR=${bx_DIR}" "${bx_GENIE}${CMAKE_EXECUTABLE_SUFFIX}" --with-shared-lib "--gcc=${bgfx_GENIE_GCC}" gmake)
    set(bgfx_BUILD_COMMAND "$(MAKE)" -C "<SOURCE_DIR>/.build/projects/gmake-${bgfx_SYSTEM_NAME}" config=release64)
else()
    message(FATAL_ERROR "BGFX does not support the generator '${CMAKE_GENERATOR}'.")
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
    LOG_CONFIGURE 1
    LOG_BUILD 1
)

# Recover BGFX paths for additional settings.
ExternalProject_Get_Property(bgfx_EXTERNAL SOURCE_DIR)
set(bgfx_INCLUDE_DIR "${SOURCE_DIR}/include")
set(bgfx_LIBRARIES_DIR "${SOURCE_DIR}/.build/${bgfx_SYSTEM_NAME}64_${bgfx_COMPILER}/bin")
set(bgfx_LIBRARY "${bgfx_LIBRARIES_DIR}/${CMAKE_SHARED_LIBRARY_PREFIX}bgfx-shared-libRelease${CMAKE_SHARED_LIBRARY_SUFFIX}")
set(bgfx_IMPLIB "${bgfx_LIBRARIES_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}bgfx-shared-libRelease${CMAKE_STATIC_LIBRARY_SUFFIX}")

# Workaround for https://cmake.org/Bug/view.php?id=15052
file(MAKE_DIRECTORY "${bx_INCLUDE_DIR}")
file(MAKE_DIRECTORY "${bgfx_INCLUDE_DIR}")

# Tell CMake that the external project generated a library so we
# can add dependencies to the library here.
add_library(bgfx SHARED IMPORTED)
add_dependencies(bgfx bgfx_EXTERNAL)
set_target_properties(bgfx PROPERTIES
    IMPORTED_NO_SONAME 1
    INTERFACE_INCLUDE_DIRECTORIES "${bgfx_INCLUDE_DIR};${bx_INCLUDE_DIR}"
    IMPORTED_LOCATION "${bgfx_LIBRARY}"
    IMPORTED_IMPLIB "${bgfx_IMPLIB}"
)

# On Linux, BGFX needs a few other libraries.
if("${CMAKE_SYSTEM_NAME}" MATCHES "Linux")
    set_target_properties(bgfx PROPERTIES
        INTERFACE_LINK_LIBRARIES "dl;GL;pthread;X11"
    )
endif()

# Create install commands to install the shared libs.
#truss_copy_libraries(bgfx_EXTERNAL "${bgfx_LIBRARY}")  # TODO: PUT ME BACK!!!!
