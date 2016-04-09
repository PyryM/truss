include(ExternalProject)

# Select binary package based on platform name.
if("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")
    if ("${CMAKE_CXX_COMPILER_ID}" MATCHES "MSVC")
        set(sfml_PACKAGE_FILENAME "SFML-2.0-windows-vc11-64bits.zip")
    elseif ("${CMAKE_CXX_COMPILER_ID}" MATCHES "GNU")
        set(sfml_PACKAGE_FILENAME "SFML-2.0-windows-gcc-4.7-tdm-64bits.zip")
    else()
        message(FATAL_ERROR "SFML does not have precompiled binaries for compiler '${CMAKE_CXX_COMPILER_ID}'.")    
    endif()
elseif("${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
    if ("${CMAKE_CXX_COMPILER_ID}" MATCHES "Clang")
        set(sfml_PACKAGE_FILENAME "SFML-2.0-osx-clang-universal.zip")
    elseif ("${CMAKE_CXX_COMPILER_ID}" MATCHES "GNU")
        set(sfml_PACKAGE_FILENAME "SFML-2.0-osx-gcc-universal.zip")
    else()
        message(FATAL_ERROR "SFML does not have precompiled binaries for compiler '${CMAKE_CXX_COMPILER_ID}'.")    
    endif()
elseif("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")
    set(sfml_PACKAGE_FILENAME "SFML-2.0-linux-gcc-64bits.tar.bz2")
else()
    message(FATAL_ERROR "SFML does not have precompiled binaries for '${CMAKE_SYSTEM_NAME}'.")
endif()

# Download `sfml` precompiled binaries.
ExternalProject_Add(sfml_EXTERNAL
    URL "http://www.sfml-dev.org/files/${sfml_PACKAGE_FILENAME}"
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
)

# Recover project paths for additional settings.
ExternalProject_Get_Property(sfml_EXTERNAL SOURCE_DIR)
set(sfml_INCLUDE_DIR "${SOURCE_DIR}/include")
set(sfml_LIBRARY "${SOURCE_DIR}/lib/${CMAKE_SHARED_LIBRARY_PREFIX}sfml-system${CMAKE_SHARED_LIBRARY_SUFFIX}.2")
set(sfml_LIBRARIES
    "${SOURCE_DIR}/lib/${CMAKE_SHARED_LIBRARY_PREFIX}sfml-audio${CMAKE_SHARED_LIBRARY_SUFFIX}.2"
    "${SOURCE_DIR}/lib/${CMAKE_SHARED_LIBRARY_PREFIX}sfml-graphics${CMAKE_SHARED_LIBRARY_SUFFIX}.2"
    "${SOURCE_DIR}/lib/${CMAKE_SHARED_LIBRARY_PREFIX}sfml-network${CMAKE_SHARED_LIBRARY_SUFFIX}.2"
    "${SOURCE_DIR}/lib/${CMAKE_SHARED_LIBRARY_PREFIX}sfml-window${CMAKE_SHARED_LIBRARY_SUFFIX}.2"
)
message(STATUS "SFML LIBRARIES: ${sfml_LIBRARY}, ${sfml_LIBRARIES}")

# Workaround for https://cmake.org/Bug/view.php?id=15052
file(MAKE_DIRECTORY "${sfml_INCLUDE_DIR}")

# Tell CMake that the external project generated a library so we
# can add dependencies to the library here.
add_library(sfml STATIC IMPORTED)
add_dependencies(sfml sfml_EXTERNAL)
set_target_properties(sfml PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${sfml_INCLUDE_DIR}"
    INTERFACE_LINK_LIBRARIES "${sfml_LIBRARIES}"
    IMPORTED_LOCATION "${sfml_LIBRARY}"
)
