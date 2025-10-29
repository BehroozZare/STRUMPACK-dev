#   Findblaspp.cmake
#
#   Finds the BLAS++ library.
#
#   This module will define the following variables:
#   
#     blaspp_FOUND        - System has found BLAS++ installation
#     blaspp_INCLUDE_DIR  - Location of BLAS++ headers
#     blaspp_LIBRARIES    - BLAS++ libraries
#
#   This module will export the following targets if blaspp_FOUND
#
#     blaspp::blaspp
#
#   This module will use the following variables to change
#   default behaviour if set
#
#     blaspp_PREFIX
#     blaspp_INCLUDE_DIR
#     blaspp_LIBRARY_DIR
#     blaspp_LIBRARIES

cmake_minimum_required(VERSION 3.11)

include(CMakeFindDependencyMacro)

# Set up some auxiliary vars if hints have been set
if(blaspp_PREFIX AND NOT blaspp_INCLUDE_DIR)
  set(blaspp_INCLUDE_DIR ${blaspp_PREFIX}/include)
endif()

if(blaspp_PREFIX AND NOT blaspp_LIBRARY_DIR)
  set(blaspp_LIBRARY_DIR 
    ${blaspp_PREFIX}/lib 
    ${blaspp_PREFIX}/lib32 
    ${blaspp_PREFIX}/lib64 
  )
endif()

# Try to find the header
find_path(blaspp_INCLUDE_DIR 
  NAMES blas.hh
  HINTS ${blaspp_PREFIX}
  PATHS ${blaspp_INCLUDE_DIR}
  PATH_SUFFIXES include
  DOC "Location of BLAS++ header"
)

# Try to find libraries if not already set
if(NOT blaspp_LIBRARIES)
  find_library(blaspp_LIBRARIES
    NAMES blaspp
    HINTS ${blaspp_PREFIX}
    PATHS ${blaspp_LIBRARY_DIR}
    PATH_SUFFIXES lib lib64 lib32
    DOC "BLAS++ Libraries"
  )
else()
  set(blaspp_LIBRARIES ${blaspp_LIBRARIES})
endif()

# If not found, try to download and build with FetchContent
if(NOT blaspp_LIBRARIES OR NOT blaspp_INCLUDE_DIR)
  message(STATUS "BLAS++ not found on system, attempting to download and build...")
  
  include(FetchContent)
  
  FetchContent_Declare(
    blaspp
    GIT_REPOSITORY https://github.com/icl-utk-edu/blaspp.git
    GIT_TAG        v2024.05.31
    GIT_SHALLOW    TRUE
  )
  
  # Configure BLAS++ build options
  set(blaspp_BUILD_TESTS OFF CACHE BOOL "Build BLAS++ tests" FORCE)
  set(build_tests OFF CACHE BOOL "Build tests" FORCE)
  set(gpu_backend "none" CACHE STRING "GPU backend for BLAS++" FORCE)
  
  # Check for CUDA or HIP
  if(STRUMPACK_USE_CUDA OR CUDA_FOUND)
    set(gpu_backend "cuda" CACHE STRING "GPU backend for BLAS++" FORCE)
  elseif(STRUMPACK_USE_HIP OR HIP_FOUND)
    set(gpu_backend "hip" CACHE STRING "GPU backend for BLAS++" FORCE)
  endif()
  
  FetchContent_MakeAvailable(blaspp)
  
  if(blaspp_POPULATED)
    message(STATUS "BLAS++ downloaded and configured successfully")
    set(blaspp_INCLUDE_DIR ${blaspp_SOURCE_DIR}/include)
    set(blaspp_LIBRARIES blaspp)
    set(blaspp_FOUND TRUE)
  endif()
else()
  # Determine if we've found BLAS++
  mark_as_advanced(blaspp_FOUND blaspp_INCLUDE_DIR blaspp_LIBRARIES)
  
  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(blaspp
    REQUIRED_VARS blaspp_LIBRARIES blaspp_INCLUDE_DIR
  )
endif()

# Export target
if(blaspp_FOUND AND NOT TARGET blaspp::blaspp)
  add_library(blaspp::blaspp INTERFACE IMPORTED)
  set_target_properties(blaspp::blaspp PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${blaspp_INCLUDE_DIR}"
    INTERFACE_LINK_LIBRARIES      "${blaspp_LIBRARIES}" 
  )
endif()

