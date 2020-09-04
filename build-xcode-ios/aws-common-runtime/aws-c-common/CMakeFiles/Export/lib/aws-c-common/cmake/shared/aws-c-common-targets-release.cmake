#----------------------------------------------------------------
# Generated CMake target import file for configuration "Release".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "AWS::aws-c-common" for configuration "Release"
set_property(TARGET AWS::aws-c-common APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(AWS::aws-c-common PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libaws-c-common.1.0.0.dylib"
  IMPORTED_SONAME_RELEASE "libaws-c-common.0unstable.dylib"
  )

list(APPEND _IMPORT_CHECK_TARGETS AWS::aws-c-common )
list(APPEND _IMPORT_CHECK_FILES_FOR_AWS::aws-c-common "${_IMPORT_PREFIX}/lib/libaws-c-common.1.0.0.dylib" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
