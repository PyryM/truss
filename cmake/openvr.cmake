include(ExternalProject)

# Use this version of openvr
set(openvr_RELEASE_VERSION "1.6.10b")

if("${CMAKE_SYSTEM_NAME}" MATCHES "Windows")
    set(openvr_SYSTEM_NAME "win64")
    set(openvr_SHARED_LIBS_DIR "lib")
    set(openvr_SHARED_BINS_DIR "bin")
    set(openvr_LIBRARY_NAME "openvr_api.dll")
    set(openvr_IMPLIB_NAME "openvr_api.lib")
elseif("${CMAKE_SYSTEM_NAME}" MATCHES "Linux")
    set(openvr_SYSTEM_NAME "linux64")
    set(openvr_SHARED_LIBS_DIR "lib")
    set(openvr_SHARED_BINS_DIR "bin")
    set(openvr_LIBRARY_NAME "libopenvr_api.so") # these are different sizes??
    set(openvr_IMPLIB_NAME "libopenvr_api.so")  # despite having the same fn?
else()
    message(FATAL_ERROR "Openvr does not have precompiled binaries for '${CMAKE_SYSTEM_NAME}'.")
endif()

# Download `openvr` and unzip its binaries.
ExternalProject_Add(openvr_EXTERNAL
    URL "https://github.com/ValveSoftware/openvr/archive/v${openvr_RELEASE_VERSION}.zip"
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
)

# Recover project paths for additional settings.
ExternalProject_Get_Property(openvr_EXTERNAL SOURCE_DIR)

set(openvr_INCLUDE_DIR "${SOURCE_DIR}/headers")
set(openvr_LIBRARY "${SOURCE_DIR}/${openvr_SHARED_BINS_DIR}/${openvr_SYSTEM_NAME}/${openvr_LIBRARY_NAME}")
set(openvr_IMPLIB "${SOURCE_DIR}/${openvr_SHARED_LIBS_DIR}/${openvr_SYSTEM_NAME}/${openvr_IMPLIB_NAME}")

# Workaround for https://cmake.org/Bug/view.php?id=15052
file(MAKE_DIRECTORY "${openvr_INCLUDE_DIR}")

# Tell CMake that the external project generated a library so we
# can add dependencies to the library here.
add_library(openvr SHARED IMPORTED)
add_dependencies(openvr openvr_EXTERNAL)
set_target_properties(openvr PROPERTIES
    IMPORTED_NO_SONAME 1
	INTERFACE_INCLUDE_DIRECTORIES "${openvr_INCLUDE_DIR}"
    IMPORTED_LOCATION "${openvr_LIBRARY}"
    IMPORTED_IMPLIB "${openvr_IMPLIB}"
)

# Create an install command to install the shared libs.
truss_copy_libraries(openvr_EXTERNAL "${openvr_LIBRARY}")
