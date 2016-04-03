#
# Module for printing properties of a target.
# Adapted from: http://stackoverflow.com/a/34292622
#

# Get all properties that cmake supports.
execute_process(COMMAND cmake --help-property-list OUTPUT_VARIABLE CMAKE_PROPERTY_LIST)

# Convert command output into a CMake list.
STRING(REGEX REPLACE ";" "\\\\;" CMAKE_PROPERTY_LIST ${CMAKE_PROPERTY_LIST})
STRING(REGEX REPLACE "\n" ";" CMAKE_PROPERTY_LIST ${CMAKE_PROPERTY_LIST})

function(print_properties)
    message ("CMAKE_PROPERTY_LIST = ${CMAKE_PROPERTY_LIST}")
endfunction(print_properties)

function(print_target_properties tgt)
    if(NOT TARGET ${tgt})
      message("There is no target named '${tgt}'")
      return()
    endif()

    foreach (prop ${CMAKE_PROPERTY_LIST})
        string(REPLACE "<CONFIG>" "${CMAKE_BUILD_TYPE}" prop ${prop})
        # message ("Checking ${prop}")
        get_property(propval TARGET ${tgt} PROPERTY ${prop} SET)
        if (propval)
            get_target_property(propval ${tgt} ${prop})
            message ("${tgt} ${prop} = ${propval}")
        endif()
    endforeach(prop)
endfunction(print_target_properties)