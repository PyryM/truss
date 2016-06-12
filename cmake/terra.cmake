include(ExternalProject)

# Use this version of terra.
set(terra_RELEASE_DATE "2016-03-25")
set(terra_RELEASE_HASH "332a506")

if("${CMAKE_SYSTEM_NAME}" MATCHES "Windows")
    set(terra_SYSTEM_NAME "Windows")
    set(terra_SHARED_LIBS_DIR "bin")
    set(terra_LIBRARY_NAME "terra.dll")
    set(terra_IMPLIB_NAME "terra.lib")
    set(terra_MD5 "d4358ccd3a3dcb312a407026e39cd1e5")
elseif("${CMAKE_SYSTEM_NAME}" MATCHES "Darwin")
    set(terra_SYSTEM_NAME "OSX")
    set(terra_SHARED_LIBS_DIR "lib")
    set(terra_LIBRARY_NAME "terra.so")
elseif("${CMAKE_SYSTEM_NAME}" MATCHES "Linux")
    set(terra_SYSTEM_NAME "Linux")
    set(terra_SHARED_LIBS_DIR "lib")
    set(terra_LIBRARY_NAME "libterra.so")
else()
    message(FATAL_ERROR "Terra does not have precompiled binaries for '${CMAKE_SYSTEM_NAME}'.")
endif()

# Download `terra` and unzip its binaries.
ExternalProject_Add(terra_EXTERNAL
    URL "https://github.com/zdevito/terra/releases/download/release-${terra_RELEASE_DATE}/terra-${terra_SYSTEM_NAME}-x86_64-${terra_RELEASE_HASH}.zip"
    URL_MD5 "${terra_MD5}"
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
)

# Recover project paths for additional settings.
ExternalProject_Get_Property(terra_EXTERNAL SOURCE_DIR)

# On Linux systems, fix terra's naming convention.
if("${CMAKE_SYSTEM_NAME}" MATCHES "Linux")
    add_custom_command(TARGET terra_EXTERNAL
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy
                "${SOURCE_DIR}/${terra_SHARED_LIBS_DIR}/terra.so"
                "${SOURCE_DIR}/${terra_SHARED_LIBS_DIR}/${terra_LIBRARY_NAME}"
    )
endif()

set(terra_INCLUDE_DIR "${SOURCE_DIR}/include")
set(terra_LIBRARY "${SOURCE_DIR}/${terra_SHARED_LIBS_DIR}/${terra_LIBRARY_NAME}")
set(terra_IMPLIB "${SOURCE_DIR}/lib/${terra_IMPLIB_NAME}")

# Workaround for https://cmake.org/Bug/view.php?id=15052
file(MAKE_DIRECTORY "${terra_INCLUDE_DIR}")

# Tell CMake that the external project generated a library so we
# can add dependencies to the library here.
add_library(terra SHARED IMPORTED)
add_dependencies(terra terra_EXTERNAL)
set_target_properties(terra PROPERTIES
    IMPORTED_NO_SONAME 1
	INTERFACE_INCLUDE_DIRECTORIES "${terra_INCLUDE_DIR}"
    IMPORTED_LOCATION "${terra_LIBRARY}"
    IMPORTED_IMPLIB "${terra_IMPLIB}"
)

# Create an install command to install the shared libs.
truss_copy_libraries(terra_EXTERNAL "${terra_LIBRARY}")

# On Windows, Terra uses a separate Lua library for some reason.
if("${CMAKE_SYSTEM_NAME}" MATCHES "Windows")
    set(lua51_LIBRARY "${SOURCE_DIR}/bin/lua51.dll")
    set(lua51_IMPLIB "${SOURCE_DIR}/lib/lua51.lib")
    
    set_target_properties(terra PROPERTIES
        INTERFACE_LINK_LIBRARIES "${lua51_IMPLIB}")
    truss_copy_libraries(terra_EXTERNAL "${lua51_LIBRARY}")
endif()
