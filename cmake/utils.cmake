# Utility functions for building truss.
# Copies every library in the given path to the `dist` lib directory.
function(copy_truss_libraries target target_library_path)
    file(GLOB target_libraries
        "${target_library_path}/${CMAKE_SHARED_LIBRARY_PREFIX}*${CMAKE_SHARED_LIBRARY_SUFFIX}*")

    foreach(library_path ${target_libraries})
        # Extract library name and create a rule to copy it to the `lib` directory.
        get_filename_component(library_file "${library_path}" NAME)
        add_custom_command(
            TARGET "${target}" POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy "${library_path}" "${DIST_DIR}/lib/${library_file}"
        )

        # On Windows, we delay loading for a bit to allow time for an RPATH modification.
        if("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")
            set_property(TARGET truss APPEND_STRING PROPERTY LINK_FLAGS "/DELAYLOAD:${library_file} ")
        endif()
    endforeach()
endfunction()