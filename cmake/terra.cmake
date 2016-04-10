include(ExternalProject)

# Use this version of physfs.
set(terra_RELEASE_DATE "2016-02-26")
set(terra_RELEASE_HASH "2fa8d0a")

if("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")
    set(terra_SYSTEM_NAME "Windows")
elseif("${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
    set(terra_SYSTEM_NAME "OSX")
elseif("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")
    set(terra_SYSTEM_NAME "Linux")
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
add_custom_command(TARGET terra_EXTERNAL
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy
            "${SOURCE_DIR}/lib/terra${CMAKE_SHARED_LIBRARY_SUFFIX}"
            "${SOURCE_DIR}/lib/${CMAKE_SHARED_LIBRARY_PREFIX}terra${CMAKE_SHARED_LIBRARY_SUFFIX}"
)

set(terra_INCLUDE_DIR "${SOURCE_DIR}/include")
set(terra_LIBRARIES_DIR "${SOURCE_DIR}/lib/")
set(terra_LIBRARY "${terra_LIBRARIES_DIR}/${CMAKE_SHARED_LIBRARY_PREFIX}terra${CMAKE_SHARED_LIBRARY_SUFFIX}")
# set(lua51_LIBRARY "${terra_LIBRARIES_DIR}/${CMAKE_SHARED_LIBRARY_PREFIX}lua51${CMAKE_SHARED_LIBRARY_SUFFIX}")

# Workaround for https://cmake.org/Bug/view.php?id=15052
file(MAKE_DIRECTORY "${terra_INCLUDE_DIR}")

# Tell CMake that the external project generated a library so we
# can add dependencies to the library here.
add_library(terra SHARED IMPORTED)
add_dependencies(terra terra_EXTERNAL)
set_target_properties(terra PROPERTIES
    IMPORTED_NO_SONAME 1
	INTERFACE_INCLUDE_DIRECTORIES "${terra_INCLUDE_DIR}"
    # INTERFACE_LINK_LIBRARIES "${lua51_LIBRARY}"
    IMPORTED_LOCATION "${terra_LIBRARY}"
)

# Create an install command to install the shared libs.
file(GLOB terra_LIBRARIES "${terra_LIBRARIES_DIR}/${CMAKE_SHARED_LIBRARY_PREFIX}*${CMAKE_SHARED_LIBRARY_SUFFIX}*")
install(
    FILES "${terra_LIBRARIES}"
    DESTINATION lib
)