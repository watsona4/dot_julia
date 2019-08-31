#----------------------------------------------------------------
# Generated CMake target import file for configuration "RELEASE".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "netcdf" for configuration "RELEASE"
set_property(TARGET netcdf APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(netcdf PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libnetcdf.so.13"
  IMPORTED_SONAME_RELEASE "libnetcdf.so.13"
  )

list(APPEND _IMPORT_CHECK_TARGETS netcdf )
list(APPEND _IMPORT_CHECK_FILES_FOR_netcdf "${_IMPORT_PREFIX}/lib/libnetcdf.so.13" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
