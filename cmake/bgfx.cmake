include(ExternalProject)

# Download `bx` and extract source path.
ExternalProject_Add(bx_EXTERNAL
    GIT_REPOSITORY "https://github.com/bkaradzic/bx.git"
    GIT_TAG "6124940cde319cb98d0662072a2993f756564fab"
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    LOG_DOWNLOAD 1
)

# Recover BX tool paths for additional settings.
ExternalProject_Get_Property(bx_EXTERNAL SOURCE_DIR)
set(bx_DIR "${SOURCE_DIR}")
set(bx_INCLUDE_DIR "${SOURCE_DIR}/include")
set(bx_MSVC_COMPAT_DIR "${SOURCE_DIR}/include/compat/msvc")
string(TOLOWER "${CMAKE_SYSTEM_NAME}" bx_SYSTEM_NAME)
set(bx_GENIE "${SOURCE_DIR}/tools/bin/${bx_SYSTEM_NAME}/genie")

# Download `bimg` and extract source path.
ExternalProject_Add(bimg_EXTERNAL
    GIT_REPOSITORY "https://github.com/bkaradzic/bimg.git"
    GIT_TAG "8f4ff5ba062abc4d5df6449210ec7423a694c6ec"
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    LOG_DOWNLOAD 1
)

# Recover BIMG tool paths for additional settings.
ExternalProject_Get_Property(bimg_EXTERNAL SOURCE_DIR)
set(bimg_DIR "${SOURCE_DIR}")
set(bimg_INCLUDE_DIR "${SOURCE_DIR}/include")


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
    set(bgfx_CONFIGURE_COMMAND "${CMAKE_COMMAND}" -E env "BX_DIR=${bx_DIR}" "BIMG_DIR=${bimg_DIR}" "${bx_GENIE}${CMAKE_EXECUTABLE_SUFFIX}" --with-tools --with-shared-lib "${bgfx_COMPILER}")
    set(bgfx_BUILD_COMMAND "${CMAKE_VS_DEVENV_COMMAND}" "<SOURCE_DIR>/.build/projects/${bgfx_COMPILER}/bgfx.sln" /Build Release|x64)
elseif("${CMAKE_GENERATOR}" MATCHES "Visual Studio 15 2017")
    set(bgfx_COMPILER "vs2017")
    set(bgfx_CONFIGURE_COMMAND "${CMAKE_COMMAND}" -E env "BX_DIR=${bx_DIR}" "BIMG_DIR=${bimg_DIR}" "${bx_GENIE}${CMAKE_EXECUTABLE_SUFFIX}" --with-tools --with-shared-lib "${bgfx_COMPILER}")
    set(bgfx_BUILD_COMMAND "${CMAKE_VS_DEVENV_COMMAND}" "<SOURCE_DIR>/.build/projects/${bgfx_COMPILER}/bgfx.sln" /Build Release|x64)
elseif("${CMAKE_GENERATOR}" STREQUAL "Unix Makefiles")
    set(bgfx_CONFIGURE_COMMAND "${CMAKE_COMMAND}" -E env "BX_DIR=${bx_DIR}" "BIMG_DIR=${bimg_DIR}" "${bx_GENIE}${CMAKE_EXECUTABLE_SUFFIX}" --with-tools --with-shared-lib "--gcc=${bgfx_GENIE_GCC}" gmake)
    set(bgfx_BUILD_COMMAND "$(MAKE)" -C "<SOURCE_DIR>/.build/projects/gmake-${bgfx_SYSTEM_NAME}" config=release64)
else()
    message(FATAL_ERROR "BGFX does not support the generator '${CMAKE_GENERATOR}'.")
endif()

# Download `bgfx` (my fork that allows getting native texture handles)
# and build it using `bx`.
ExternalProject_Add(bgfx_EXTERNAL
    DEPENDS bx_EXTERNAL bimg_EXTERNAL
    GIT_REPOSITORY "https://github.com/PyryM/bgfx.git"
    GIT_TAG "30552f21e3a232d74082f92c078c6e2ea89e7726"
    CONFIGURE_COMMAND ${bgfx_CONFIGURE_COMMAND}
    BUILD_COMMAND ${bgfx_BUILD_COMMAND}
    INSTALL_COMMAND ""
    BUILD_IN_SOURCE 1
    LOG_DOWNLOAD 1
    LOG_CONFIGURE 1
    #LOG_BUILD 1
)

# Add "Generate Parsers" step on Linux platforms.
# Required by BGFX (https://github.com/bkaradzic/bgfx/issues/364)
if("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")
    ExternalProject_Add_Step(bgfx_EXTERNAL GENERATE_PARSERS
        COMMAND "./generateParsers.sh"
        WORKING_DIRECTORY "<SOURCE_DIR>/3rdparty/glsl-optimizer/"
        COMMENT "Generating parsers for GLSL optimizer."
        DEPENDEES download
        DEPENDERS build
    )
endif()

# Recover BGFX paths for additional settings.
ExternalProject_Get_Property(bgfx_EXTERNAL SOURCE_DIR)
set(bgfx_INCLUDE_DIR "${SOURCE_DIR}/include")
set(bgfx_LIBRARIES_DIR "${SOURCE_DIR}/.build/${bgfx_SYSTEM_NAME}64_${bgfx_COMPILER}/bin")
set(bgfx_LIBRARY "${bgfx_LIBRARIES_DIR}/${CMAKE_SHARED_LIBRARY_PREFIX}bgfx-shared-libRelease${CMAKE_SHARED_LIBRARY_SUFFIX}")
set(bgfx_IMPLIB "${bgfx_LIBRARIES_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}bgfx-shared-libRelease${CMAKE_STATIC_LIBRARY_SUFFIX}")
set(bgfx_BINARIES
    "${bgfx_LIBRARIES_DIR}/shadercRelease${CMAKE_EXECUTABLE_SUFFIX}"
    "${bgfx_LIBRARIES_DIR}/texturecRelease${CMAKE_EXECUTABLE_SUFFIX}"
    "${bgfx_LIBRARIES_DIR}/geometrycRelease${CMAKE_EXECUTABLE_SUFFIX}"
)

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

# On Windows, need to include bx's 'compat' headers
if("${CMAKE_SYSTEM_NAME}" MATCHES "Windows")
    file(MAKE_DIRECTORY "${bx_MSVC_COMPAT_DIR}")
    set_target_properties(bgfx PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${bgfx_INCLUDE_DIR};${bx_INCLUDE_DIR};${bx_MSVC_COMPAT_DIR}"
    )
endif()

# On Linux, BGFX needs a few other libraries.
if("${CMAKE_SYSTEM_NAME}" MATCHES "Linux")
    set_target_properties(bgfx PROPERTIES
        INTERFACE_LINK_LIBRARIES "dl;GL;pthread;X11"
    )
endif()

# Create install commands to install the shared libs.
truss_copy_libraries(bgfx_EXTERNAL "${bgfx_LIBRARY}")
truss_copy_binaries(bgfx_EXTERNAL "${bgfx_BINARIES}")
