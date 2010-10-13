########################################################################################################################
#
# CMake package use file for OROCOS-RTT.
# It is assumed that find_package(OROCOS-RTT ...) has already been invoked.
# See orocos-rtt-config.cmake for information on how to load OROCOS-RTT into your CMake project.
# To include this file from your CMake project, the OROCOS-RTT_USE_FILE_PATH variable is used:
# include(${OROCOS-RTT_USE_FILE_PATH}/UseOROCOS-RTT.cmake)
#
########################################################################################################################

if(OROCOS-RTT_FOUND)
  # Include directories
  include_directories(${OROCOS-RTT_INCLUDE_DIRS})

  # Preprocessor definitions
  add_definitions(${OROCOS-RTT_DEFINITIONS})
  
#
# Include and link against required stuff
#
#From: http://www.cmake.org/Wiki/CMakeMacroParseArguments
MACRO(ORO_PARSE_ARGUMENTS prefix arg_names option_names)
  SET(DEFAULT_ARGS)
  FOREACH(arg_name ${arg_names})  
    SET(${prefix}_${arg_name})
  ENDFOREACH(arg_name)
  FOREACH(option ${option_names})
    SET(${prefix}_${option} FALSE)
  ENDFOREACH(option)

  SET(current_arg_name DEFAULT_ARGS)
  SET(current_arg_list)
  FOREACH(arg ${ARGN})
    SET(larg_names ${arg_names})
    LIST(FIND larg_names "${arg}" is_arg_name)     
    IF (is_arg_name GREATER -1)
      SET(${prefix}_${current_arg_name} ${current_arg_list})
      SET(current_arg_name ${arg})
      SET(current_arg_list)
    ELSE (is_arg_name GREATER -1)
      SET(loption_names ${option_names})
      LIST(FIND loption_names "${arg}" is_option)            
      IF (is_option GREATER -1)
         SET(${prefix}_${arg} TRUE)
      ELSE (is_option GREATER -1)
         SET(current_arg_list ${current_arg_list} ${arg})
      ENDIF (is_option GREATER -1)
    ENDIF (is_arg_name GREATER -1)
  ENDFOREACH(arg)
  SET(${prefix}_${current_arg_name} ${current_arg_list})
ENDMACRO(ORO_PARSE_ARGUMENTS)

# Components should add themselves by calling 'OROCOS_COMPONENT' 
# instead of 'ADD_LIBRARY' in CMakeLists.txt.
#
# Usage: orocos_component( COMPONENT_NAME src1 src2 src3 [INSTALL lib/orocos/${PROJECT_NAME}] )
#
macro( orocos_component )
  
  ORO_PARSE_ARGUMENTS(ADD_COMPONENT
    "INSTALL"
    ""
    ${ARGN}
    )
  list(GET ADD_COMPONENT_DEFAULT_ARGS 0 COMPONENT_NAME)
  list(REMOVE_AT ADD_COMPONENT_DEFAULT_ARGS 0)
  SET( SOURCES ${ADD_COMPONENT_DEFAULT_ARGS} )
  SET( LIB_NAME "${COMPONENT_NAME}-${OROCOS_TARGET}")
  if ( ADD_COMPONENT_INSTALL )
    set(AC_INSTALL_DIR ${ADD_COMPONENT_INSTALL})
    set(AC_INSTALL_RT_DIR bin)
  else()
    set(AC_INSTALL_DIR lib/orocos/${PROJECT_NAME})
    set(AC_INSTALL_RT_DIR lib/orocos/${PROJECT_NAME})
  endif()
  
  if ( ${OROCOS_TARGET} STREQUAL "gnulinux" OR ${OROCOS_TARGET} STREQUAL "lxrt" OR ${OROCOS_TARGET} STREQUAL "xenomai")
      set( COMPONENT_LIB_NAME ${COMPONENT_NAME}-${OROCOS_TARGET})
  else()
      set( COMPONENT_LIB_NAME ${COMPONENT_NAME})
  endif()
  MESSAGE( "Building component ${COMPONENT_NAME} in library ${COMPONENT_LIB_NAME}" )
  ADD_LIBRARY( ${COMPONENT_NAME} SHARED ${SOURCES} )
  SET_TARGET_PROPERTIES( ${COMPONENT_NAME} PROPERTIES
    OUTPUT_NAME ${COMPONENT_LIB_NAME}
    DEFINE_SYMBOL "RTT_COMPONENT"
#    VERSION ${OCL_VERSION}
#    SOVERSION ${OCL_VERSION_MAJOR}.${OCL_VERSION_MINOR}
    INSTALL_RPATH_USE_LINK_PATH 1
    )
  TARGET_LINK_LIBRARIES( ${COMPONENT_NAME} ${OROCOS-RTT_LIBRARIES} )


  INSTALL(TARGETS ${COMPONENT_NAME} LIBRARY DESTINATION ${AC_INSTALL_DIR} ARCHIVE DESTINATION lib RUNTIME DESTINATION ${AC_INSTALL_RT_DIR})

  LINK_DIRECTORIES( ${CMAKE_CURRENT_BINARY_DIR} )
endmacro( orocos_component )

# Utility libraries should add themselves by calling 'orocos_library()' 
# instead of 'ADD_LIBRARY' in CMakeLists.txt.
#
# Usage: orocos_library( libraryname src1 src2 src3 )
#
macro( orocos_library LIB_TARGET_NAME )

  set(AC_INSTALL_DIR lib)
  set(AC_INSTALL_RT_DIR bin)
  
  if ( ${OROCOS_TARGET} STREQUAL "gnulinux" OR ${OROCOS_TARGET} STREQUAL "lxrt" OR ${OROCOS_TARGET} STREQUAL "xenomai")
      set( LIB_NAME ${LIB_TARGET_NAME}-${OROCOS_TARGET})
  else()
      set( LIB_NAME ${LIB_TARGET_NAME})
  endif()
  MESSAGE( "Building library ${LIB_TARGET_NAME}" )
  ADD_LIBRARY( ${LIB_TARGET_NAME} SHARED ${ARGN} )
  SET_TARGET_PROPERTIES( ${LIB_TARGET_NAME} PROPERTIES
    OUTPUT_NAME ${LIB_NAME}
#    VERSION ${OCL_VERSION}
#    SOVERSION ${OCL_VERSION_MAJOR}.${OCL_VERSION_MINOR}
    INSTALL_RPATH_USE_LINK_PATH 1
    )
  TARGET_LINK_LIBRARIES( ${LIB_TARGET_NAME} ${OROCOS-RTT_LIBRARIES} )


  INSTALL(TARGETS ${LIB_TARGET_NAME} LIBRARY DESTINATION ${AC_INSTALL_DIR} ARCHIVE DESTINATION lib RUNTIME DESTINATION ${AC_INSTALL_RT_DIR})

  LINK_DIRECTORIES( ${CMAKE_CURRENT_BINARY_DIR} )
endmacro( orocos_library )

# Type headers should add themselves by calling 'orocos_typekit()' 
#
# Usage: orocos_typekit( robotdata.hpp sensordata.hpp )
#
macro( orocos_typekit )

  MESSAGE( "Generating typekit for ${PROJECT_NAME}..." )
  
  # Works in top level source dir:
  execute_process( COMMAND typegen --output typekit ${PROJECT_NAME} ${ARGN} 
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR} 
        )
  set(TYPEKIT_IN_PROJECT TRUE)
  add_subdirectory( typekit )
endmacro( orocos_typekit )

# plugin libraries and services should add themselves by calling 'orocos_plugin()' 
# instead of 'ADD_LIBRARY' in CMakeLists.txt.
#
# Usage: orocos_plugin( pluginname src1 src2 src3 )
#
macro( orocos_plugin LIB_TARGET_NAME )

  set(AC_INSTALL_DIR lib/${PROJECT_NAME}/plugins )
  set(AC_INSTALL_RT_DIR lib/${PROJECT_NAME}/plugins )
  
  if ( ${OROCOS_TARGET} STREQUAL "gnulinux" OR ${OROCOS_TARGET} STREQUAL "lxrt" OR ${OROCOS_TARGET} STREQUAL "xenomai")
      set( LIB_NAME ${LIB_TARGET_NAME}-${OROCOS_TARGET})
  else()
      set( LIB_NAME ${LIB_TARGET_NAME})
  endif()
  MESSAGE( "Building plugin library ${LIB_TARGET_NAME}" )
  ADD_LIBRARY( ${LIB_TARGET_NAME} SHARED ${ARGN} )
  SET_TARGET_PROPERTIES( ${LIB_TARGET_NAME} PROPERTIES
    OUTPUT_NAME ${LIB_NAME}
#    VERSION ${OCL_VERSION}
#    SOVERSION ${OCL_VERSION_MAJOR}.${OCL_VERSION_MINOR}
    INSTALL_RPATH_USE_LINK_PATH 1
    )
  TARGET_LINK_LIBRARIES( ${LIB_TARGET_NAME} ${OROCOS-RTT_LIBRARIES} )

  INSTALL(TARGETS ${LIB_TARGET_NAME} LIBRARY DESTINATION ${AC_INSTALL_DIR} ARCHIVE DESTINATION lib RUNTIME DESTINATION ${AC_INSTALL_RT_DIR})

  LINK_DIRECTORIES( ${CMAKE_CURRENT_BINARY_DIR} )
endmacro( orocos_plugin )

#
# Components supply header files which should be included when 
# using these components. Each component should use this macro
# to install its header-files.
#
# Usage example: orocos_install_header( hardware.hpp control.hpp)
macro( orocos_install_headers )
  INSTALL( FILES ${ARGN} DESTINATION include/orocos/${PROJECT_NAME} )
endmacro( orocos_install_headers )

endif()