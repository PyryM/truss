# Utility functions for building truss.
# Copies every library in the given path to the `dist` lib directory.
function(truss_copy_libraries target target_libraries)
    foreach(library_path ${target_libraries})
        # Extract library name from full path.
        get_filename_component(library_file "${library_path}" NAME)

        # On Mac, we need to relocate the library RPATH.
        # This is handled manually as a post-build step because of wild
        # inconsistencies in how the Mac RPATH is handled in various libraries.
        if ("${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
            add_custom_command(
                TARGET "${target}" POST_BUILD
                COMMAND install_name_tool
                ARGS -id "@executable_path/lib/${library_file}" "${library_path}"
                DEPENDS "${library_path}"
                COMMENT "Relocated Mac RPATH of ${target} library."
            )
        endif()

        # On Windows, we delay loading for a bit to allow time for an RPATH modification.
        if("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")
            set_property(TARGET truss APPEND_STRING PROPERTY LINK_FLAGS "/DELAYLOAD:${library_file} ")
        endif()

        # Create a rule to copy the library to the `lib` directory.
        add_custom_command(
            TARGET "${target}" POST_BUILD
            COMMAND "${CMAKE_COMMAND}"
            ARGS -E copy "${library_path}" "${DIST_DIR}/lib/${library_file}"
            BYPRODUCTS "${DIST_DIR}/lib/${library_file}"
            COMMENT "Installed ${target} library to distribution directory."
        )
    endforeach()
endfunction()
