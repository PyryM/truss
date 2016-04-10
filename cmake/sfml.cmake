include(ExternalProject)

# Select binary package based on platform name.
if("${CMAKE_SYSTEM_NAME}" MATCHES "Windows")
    set(sfml_SHARED_LIBS_DIR "bin")
    if ("${CMAKE_CXX_COMPILER_ID}" MATCHES "MSVC")
        set(sfml_PACKAGE_FILENAME "SFML-2.0-windows-vc11-64bits.zip")
    elseif ("${CMAKE_CXX_COMPILER_ID}" MATCHES "GNU")
        set(sfml_PACKAGE_FILENAME "SFML-2.0-windows-gcc-4.7-tdm-64bits.zip")
    else()
        message(FATAL_ERROR "SFML does not have precompiled binaries for compiler '${CMAKE_CXX_COMPILER_ID}'.")    
    endif()
elseif("${CMAKE_SYSTEM_NAME}" MATCHES "Darwin")
    set(sfml_SHARED_LIBS_DIR "lib")
    if ("${CMAKE_CXX_COMPILER_ID}" MATCHES "Clang")
        set(sfml_PACKAGE_FILENAME "SFML-2.0-osx-clang-universal.zip")
    elseif ("${CMAKE_CXX_COMPILER_ID}" MATCHES "GNU")
        set(sfml_PACKAGE_FILENAME "SFML-2.0-osx-gcc-universal.zip")
    else()
        message(FATAL_ERROR "SFML does not have precompiled binaries for compiler '${CMAKE_CXX_COMPILER_ID}'.")    
    endif()
elseif("${CMAKE_SYSTEM_NAME}" MATCHES "Linux")
    set(sfml_SHARED_LIBS_DIR "lib")
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
set(sfml_LIBRARIES_DIR "${SOURCE_DIR}/${sfml_SHARED_LIBS_DIR}")

# Workaround for https://cmake.org/Bug/view.php?id=15052
file(MAKE_DIRECTORY "${sfml_INCLUDE_DIR}")

# Create a target for each SFML component.
foreach(component_name IN ITEMS audio graphics network system window)
    set(sfml_LIBRARY "${sfml_LIBRARIES_DIR}/${CMAKE_SHARED_LIBRARY_PREFIX}sfml-${component_name}${CMAKE_SHARED_LIBRARY_SUFFIX}")
    set(sfml_IMPLIB "${SOURCE_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}sfml-${component_name}${CMAKE_STATIC_LIBRARY_SUFFIX}")

    # Tell CMake that the external project generated a library so we
    # can add dependencies to the library here.
    add_library("sfml_${component_name}" SHARED IMPORTED)
    add_dependencies("sfml_${component_name}" sfml_EXTERNAL)
    set_target_properties("sfml_${component_name}" PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${sfml_INCLUDE_DIR}"
        IMPORTED_LOCATION "${sfml_LIBRARY}"
        IMPORTED_IMPLIB "${sfml_IMPLIB}"
    )
endforeach()

# Create an install command to install the shared libs.
copy_libraries(sfml_EXTERNAL "${sfml_LIBRARIES_DIR}")
