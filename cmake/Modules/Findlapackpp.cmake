#   Findlapackpp.cmake
#
#   Finds the LAPACK++ library.
#
#   This module will define the following variables:
#   
#     lapackpp_FOUND        - System has found LAPACK++ installation
#     lapackpp_INCLUDE_DIR  - Location of LAPACK++ headers
#     lapackpp_LIBRARIES    - LAPACK++ libraries
#
#   This module will export the following targets if lapackpp_FOUND
#
#     lapackpp::lapackpp
#
#   This module will use the following variables to change
#   default behaviour if set
#
#     lapackpp_PREFIX
#     lapackpp_INCLUDE_DIR
#     lapackpp_LIBRARY_DIR
#     lapackpp_LIBRARIES

cmake_minimum_required(VERSION 3.11)

include(CMakeFindDependencyMacro)

# LAPACK++ depends on BLAS++
if(NOT TARGET blaspp::blaspp)
  find_dependency(blaspp REQUIRED)
endif()

# Set up some auxiliary vars if hints have been set
if(lapackpp_PREFIX AND NOT lapackpp_INCLUDE_DIR)
  set(lapackpp_INCLUDE_DIR ${lapackpp_PREFIX}/include)
endif()

if(lapackpp_PREFIX AND NOT lapackpp_LIBRARY_DIR)
  set(lapackpp_LIBRARY_DIR 
    ${lapackpp_PREFIX}/lib 
    ${lapackpp_PREFIX}/lib32 
    ${lapackpp_PREFIX}/lib64 
  )
endif()

# Try to find the header
find_path(lapackpp_INCLUDE_DIR 
  NAMES lapack.hh
  HINTS ${lapackpp_PREFIX}
  PATHS ${lapackpp_INCLUDE_DIR}
  PATH_SUFFIXES include
  DOC "Location of LAPACK++ header"
)

# Try to find libraries if not already set
if(NOT lapackpp_LIBRARIES)
  find_library(lapackpp_LIBRARIES
    NAMES lapackpp
    HINTS ${lapackpp_PREFIX}
    PATHS ${lapackpp_LIBRARY_DIR}
    PATH_SUFFIXES lib lib64 lib32
    DOC "LAPACK++ Libraries"
  )
else()
  set(lapackpp_LIBRARIES ${lapackpp_LIBRARIES})
endif()

# If not found, try to download and build with FetchContent
if(NOT lapackpp_LIBRARIES OR NOT lapackpp_INCLUDE_DIR)
  message(STATUS "LAPACK++ not found on system, attempting to download and build...")
  
  include(FetchContent)
  
  FetchContent_Declare(
    lapackpp
    GIT_REPOSITORY https://github.com/icl-utk-edu/lapackpp.git
    GIT_TAG        v2024.05.31
    GIT_SHALLOW    TRUE
  )
  
  # Configure LAPACK++ build options
  set(lapackpp_BUILD_TESTS OFF CACHE BOOL "Build LAPACK++ tests" FORCE)
  set(build_tests OFF CACHE BOOL "Build tests" FORCE)
  
  FetchContent_MakeAvailable(lapackpp)
  
  if(lapackpp_POPULATED)
    message(STATUS "LAPACK++ downloaded and configured successfully")
    set(lapackpp_INCLUDE_DIR ${lapackpp_SOURCE_DIR}/include)
    set(lapackpp_LIBRARIES lapackpp)
    set(lapackpp_FOUND TRUE)
  endif()
else()
  # Determine if we've found LAPACK++
  mark_as_advanced(lapackpp_FOUND lapackpp_INCLUDE_DIR lapackpp_LIBRARIES)
  
  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(lapackpp
    REQUIRED_VARS lapackpp_LIBRARIES lapackpp_INCLUDE_DIR blaspp_FOUND
  )
endif()

# Export target
if(lapackpp_FOUND AND NOT TARGET lapackpp::lapackpp)
  add_library(lapackpp::lapackpp INTERFACE IMPORTED)
  set_target_properties(lapackpp::lapackpp PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${lapackpp_INCLUDE_DIR}"
    INTERFACE_LINK_LIBRARIES      "${lapackpp_LIBRARIES};blaspp::blaspp" 
  )
endif()

