include(ExternalProject)

# Use this version of physfs.
set(terra_RELEASE_DATE "2016-02-26")
set(terra_RELEASE_HASH "2fa8d0a")

if("${CMAKE_SYSTEM_NAME}" MATCHES "Windows")
    set(terra_SYSTEM_NAME "Windows")
    set(terra_SHARED_LIBS_DIR "bin")
elseif("${CMAKE_SYSTEM_NAME}" MATCHES "Darwin")
    set(terra_SYSTEM_NAME "OSX")
    set(terra_SHARED_LIBS_DIR "lib")
elseif("${CMAKE_SYSTEM_NAME}" MATCHES "Linux")
    set(terra_SYSTEM_NAME "Linux")
    set(terra_SHARED_LIBS_DIR "lib")
else()
    message(FATAL_ERROR "Terra does not have precompiled binaries for '${CMAKE_SYSTEM_NAME}'.")
endif()

# Download `terra` and unzip its binaries.
ExternalProject_Add(terra_EXTERNAL
    URL "https://github.com/zdevito/terra/releases/download/release-${terra_RELEASE_DATE}/terra-${terra_SYSTEM_NAME}-x86_64-${terra_RELEASE_HASH}.zip"
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
)

# Recover project paths for additional settings.
ExternalProject_Get_Property(terra_EXTERNAL SOURCE_DIR)

# On linux systems, fix terra's naming convention.
if("${CMAKE_SYSTEM_NAME}" MATCHES "Linux")
    add_custom_command(TARGET terra_EXTERNAL
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy
                "${SOURCE_DIR}/${terra_SHARED_LIBS_DIR}/terra${CMAKE_SHARED_LIBRARY_SUFFIX}"
                "${SOURCE_DIR}/${terra_SHARED_LIBS_DIR}/${CMAKE_SHARED_LIBRARY_PREFIX}terra${CMAKE_SHARED_LIBRARY_SUFFIX}"
    )
endif()

set(terra_INCLUDE_DIR "${SOURCE_DIR}/include")
set(terra_LIBRARIES_DIR "${SOURCE_DIR}/${terra_SHARED_LIBS_DIR}")
set(terra_LIBRARY "${terra_LIBRARIES_DIR}/${CMAKE_SHARED_LIBRARY_PREFIX}terra${CMAKE_SHARED_LIBRARY_SUFFIX}")
set(terra_IMPLIB "${SOURCE_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}terra${CMAKE_STATIC_LIBRARY_SUFFIX}")

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

# On Windows, Terra uses a separate Lua library for some reason.
if("${CMAKE_SYSTEM_NAME}" MATCHES "Windows")
    set(lua51_IMPLIB "${SOURCE_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}lua51${CMAKE_STATIC_LIBRARY_SUFFIX}")
    set_target_properties(terra PROPERTIES
        INTERFACE_LINK_LIBRARIES "${lua51_IMPLIB}")
endif()

# Create an install command to install the shared libs.
copy_libraries(terra_EXTERNAL "${terra_LIBRARIES_DIR}")
