#   Findslate.cmake
#
#   Finds the SLATE library.
#
#   This module will define the following variables:
#   
#     slate_FOUND        - System has found SLATE installation
#     slate_INCLUDE_DIR  - Location of SLATE headers
#     slate_LIBRARIES    - SLATE libraries
#
#   This module will export the following targets if slate_FOUND
#
#     slate::slate
#
#   This module will use the following variables to change
#   default behaviour if set
#
#     slate_PREFIX
#     slate_INCLUDE_DIR
#     slate_LIBRARY_DIR
#     slate_LIBRARIES

cmake_minimum_required(VERSION 3.11)

include(CMakeFindDependencyMacro)

# SLATE depends on BLAS++ and LAPACK++
if(NOT TARGET blaspp::blaspp)
  find_dependency(blaspp REQUIRED)
endif()

if(NOT TARGET lapackpp::lapackpp)
  find_dependency(lapackpp REQUIRED)
endif()

# SLATE requires MPI
if(NOT TARGET MPI::MPI_CXX)
  find_dependency(MPI REQUIRED)
endif()

# Set up some auxiliary vars if hints have been set
if(slate_PREFIX AND NOT slate_INCLUDE_DIR)
  set(slate_INCLUDE_DIR ${slate_PREFIX}/include)
endif()

if(slate_PREFIX AND NOT slate_LIBRARY_DIR)
  set(slate_LIBRARY_DIR 
    ${slate_PREFIX}/lib 
    ${slate_PREFIX}/lib32 
    ${slate_PREFIX}/lib64 
  )
endif()

# Try to find the header
find_path(slate_INCLUDE_DIR 
  NAMES slate/slate.hh
  HINTS ${slate_PREFIX}
  PATHS ${slate_INCLUDE_DIR}
  PATH_SUFFIXES include
  DOC "Location of SLATE header"
)

# Try to find libraries if not already set
if(NOT slate_LIBRARIES)
  find_library(slate_LIBRARIES
    NAMES slate
    HINTS ${slate_PREFIX}
    PATHS ${slate_LIBRARY_DIR}
    PATH_SUFFIXES lib lib64 lib32
    DOC "SLATE Libraries"
  )
else()
  set(slate_LIBRARIES ${slate_LIBRARIES})
endif()

# If not found, try to download and build with FetchContent
if(NOT slate_LIBRARIES OR NOT slate_INCLUDE_DIR)
  message(STATUS "SLATE not found on system, attempting to download and build...")
  
  include(FetchContent)
  
  FetchContent_Declare(
    slate
    GIT_REPOSITORY https://github.com/icl-utk-edu/slate.git
    GIT_TAG        v2024.05.31
    GIT_SHALLOW    TRUE
  )
  
  # Configure SLATE build options
  set(slate_BUILD_TESTS OFF CACHE BOOL "Build SLATE tests" FORCE)
  set(build_tests OFF CACHE BOOL "Build tests" FORCE)
  set(use_openmp ${STRUMPACK_USE_OPENMP} CACHE BOOL "Use OpenMP in SLATE" FORCE)
  
  # Set GPU backend for SLATE
  set(gpu_backend "none" CACHE STRING "GPU backend for SLATE" FORCE)
  if(STRUMPACK_USE_CUDA OR CUDA_FOUND)
    set(gpu_backend "cuda" CACHE STRING "GPU backend for SLATE" FORCE)
  elseif(STRUMPACK_USE_HIP OR HIP_FOUND)
    set(gpu_backend "hip" CACHE STRING "GPU backend for SLATE" FORCE)
  endif()
  
  FetchContent_MakeAvailable(slate)
  
  if(slate_POPULATED)
    message(STATUS "SLATE downloaded and configured successfully")
    set(slate_INCLUDE_DIR ${slate_SOURCE_DIR}/include)
    set(slate_LIBRARIES slate)
    set(slate_FOUND TRUE)
  endif()
else()
  # Determine if we've found SLATE
  mark_as_advanced(slate_FOUND slate_INCLUDE_DIR slate_LIBRARIES)
  
  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(slate
    REQUIRED_VARS slate_LIBRARIES slate_INCLUDE_DIR blaspp_FOUND lapackpp_FOUND
  )
endif()

# Export target
if(slate_FOUND AND NOT TARGET slate::slate)
  add_library(slate::slate INTERFACE IMPORTED)
  set_target_properties(slate::slate PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${slate_INCLUDE_DIR}"
    INTERFACE_LINK_LIBRARIES      "${slate_LIBRARIES};lapackpp::lapackpp;blaspp::blaspp;MPI::MPI_CXX" 
  )
endif()

