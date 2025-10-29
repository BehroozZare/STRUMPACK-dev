#   FindZFP.cmake
#
#   Finds the ZFP compression library.
#
#   This module will define the following variables:
#   
#     ZFP_FOUND        - System has found ZFP installation
#     ZFP_INCLUDE_DIR  - Location of ZFP headers
#     ZFP_LIBRARIES    - ZFP libraries
#     ZFP_VERSION      - ZFP version
#
#   This module will export the following targets if ZFP_FOUND
#
#     ZFP::zfp
#
#   This module will use the following variables to change
#   default behaviour if set
#
#     zfp_PREFIX
#     zfp_INCLUDE_DIR
#     zfp_LIBRARY_DIR
#     zfp_LIBRARIES

cmake_minimum_required(VERSION 3.11)

# Set up some auxiliary vars if hints have been set
if(zfp_PREFIX AND NOT zfp_INCLUDE_DIR)
  set(zfp_INCLUDE_DIR ${zfp_PREFIX}/include)
endif()

if(zfp_PREFIX AND NOT zfp_LIBRARY_DIR)
  set(zfp_LIBRARY_DIR 
    ${zfp_PREFIX}/lib 
    ${zfp_PREFIX}/lib32 
    ${zfp_PREFIX}/lib64 
  )
endif()

# Try to find the header
find_path(ZFP_INCLUDE_DIR 
  NAMES zfp.h
  HINTS ${zfp_PREFIX}
  PATHS ${zfp_INCLUDE_DIR}
  PATH_SUFFIXES include
  DOC "Location of ZFP header"
)

# Try to find libraries if not already set
if(NOT zfp_LIBRARIES)
  find_library(ZFP_LIBRARIES
    NAMES zfp
    HINTS ${zfp_PREFIX}
    PATHS ${zfp_LIBRARY_DIR}
    PATH_SUFFIXES lib lib64 lib32
    DOC "ZFP Libraries"
  )
else()
  set(ZFP_LIBRARIES ${zfp_LIBRARIES})
endif()

# Check version
if(EXISTS ${ZFP_INCLUDE_DIR}/zfp.h)
  set(version_pattern 
    "^#define[\t ]+ZFP_VERSION_MAJOR[\t ]+([0-9]+)$"
  )
  file(STRINGS ${ZFP_INCLUDE_DIR}/zfp.h zfp_major_version
        REGEX ${version_pattern})
  
  if(zfp_major_version)
    string(REGEX REPLACE ${version_pattern} "\\1" 
      ZFP_VERSION_MAJOR ${zfp_major_version})
      
    set(version_pattern 
      "^#define[\t ]+ZFP_VERSION_MINOR[\t ]+([0-9]+)$"
    )
    file(STRINGS ${ZFP_INCLUDE_DIR}/zfp.h zfp_minor_version
          REGEX ${version_pattern})
    
    if(zfp_minor_version)
      string(REGEX REPLACE ${version_pattern} "\\1" 
        ZFP_VERSION_MINOR ${zfp_minor_version})
      set(ZFP_VERSION "${ZFP_VERSION_MAJOR}.${ZFP_VERSION_MINOR}")
    endif()
  endif()
  
  unset(version_pattern)
  unset(zfp_major_version)
  unset(zfp_minor_version)
endif()

# If not found, try to download and build with FetchContent
if(NOT ZFP_LIBRARIES OR NOT ZFP_INCLUDE_DIR)
  message(STATUS "ZFP not found on system, attempting to download and build...")
  
  include(FetchContent)
  
  FetchContent_Declare(
    zfp
    GIT_REPOSITORY https://github.com/LLNL/zfp.git
    GIT_TAG        1.0.1
    GIT_SHALLOW    TRUE
  )
  
  # Configure ZFP build options
  set(BUILD_TESTING OFF CACHE BOOL "Build ZFP tests" FORCE)
  set(BUILD_EXAMPLES OFF CACHE BOOL "Build ZFP examples" FORCE)
  set(BUILD_UTILITIES OFF CACHE BOOL "Build ZFP utilities" FORCE)
  set(ZFP_WITH_OPENMP ${STRUMPACK_USE_OPENMP} CACHE BOOL "Enable OpenMP in ZFP" FORCE)
  
  FetchContent_MakeAvailable(zfp)
  
  if(zfp_POPULATED)
    message(STATUS "ZFP downloaded and configured successfully")
    set(ZFP_INCLUDE_DIR ${zfp_SOURCE_DIR}/include)
    set(ZFP_LIBRARIES zfp)
    set(ZFP_FOUND TRUE)
  endif()
else()
  # Determine if we've found ZFP
  mark_as_advanced(ZFP_FOUND ZFP_INCLUDE_DIR ZFP_LIBRARIES)
  
  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(ZFP
    REQUIRED_VARS ZFP_LIBRARIES ZFP_INCLUDE_DIR
    VERSION_VAR ZFP_VERSION
  )
endif()

# Export target
if(ZFP_FOUND AND NOT TARGET ZFP::zfp)
  add_library(ZFP::zfp INTERFACE IMPORTED)
  set_target_properties(ZFP::zfp PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${ZFP_INCLUDE_DIR}"
    INTERFACE_LINK_LIBRARIES      "${ZFP_LIBRARIES}" 
  )
endif()

