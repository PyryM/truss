# Utility functions for building truss.
# Copies every library in the given path to the `dist` lib directory.
function(truss_copy_libraries target target_libraries)
    # Create the `dist/lib` directory if it does not already exist.
    file(MAKE_DIRECTORY "${DIST_DIR}/lib")
    
    # Copy over each shared library in the specified path.
    foreach(library_path ${target_libraries})
        # Extract library name and create a rule to copy it to the `lib` directory.
        get_filename_component(library_file "${library_path}" NAME)
        add_custom_command(
            TARGET "${target}" POST_BUILD
            COMMAND "${CMAKE_COMMAND}"
            ARGS -E copy "${library_path}" "${DIST_DIR}/lib/${library_file}"
            BYPRODUCTS "${DIST_DIR}/lib/${library_file}"
            COMMENT "Installed ${target} library to distribution directory."
        )

        # On Windows, we delay loading for a bit to allow time for an RPATH modification.
        if("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")
            set_property(TARGET truss APPEND_STRING PROPERTY LINK_FLAGS "/DELAYLOAD:${library_file} ")
        endif()

        # On Mac, we need to relocate the library RPATH.
        # This is handled manually as a post-build step because of wild
        # inconsistencies in how the Mac RPATH is handled in various libraries.
        if ("${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
            add_custom_command(
                TARGET "${target}" POST_BUILD
                COMMAND install_name_tool
                ARGS -id "@executable_path/lib/${library_file}" "${DIST_DIR}/lib/${library_file}"
                DEPENDS "${DIST_DIR}/lib/${library_file}"
                COMMENT "Relocated Mac RPATH of ${target} library."
            )
        endif()
    endforeach()
endfunction()
