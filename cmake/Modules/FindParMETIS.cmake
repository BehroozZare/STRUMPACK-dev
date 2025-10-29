#   FindParMETIS.cmake
#
#   Finds the ParMETIS library.
#
#   This module will define the following variables:
#   
#     ParMETIS_FOUND        - System has found ParMETIS installation
#     ParMETIS_INCLUDE_DIR  - Location of ParMETIS headers
#     ParMETIS_LIBRARIES    - ParMETIS libraries
#     ParMETIS_USES_ILP64   - Whether ParMETIS was compiled with ILP64

#   This module can handle the following COMPONENTS
#
#     ilp64 - 64-bit index integers
#
#   This module will export the following targets if ParMETIS_FOUND
#
#     ParMETIS::parmetis
#
#
#
#
#   Proper usage:
#
#     project( TEST_FIND_ParMETIS C )
#     find_package( ParMETIS )
#
#     if( ParMETIS_FOUND )
#       add_executable( test test.cxx )
#       target_link_libraries( test ParMETIS::parmetis )
#     endif()
#
#
#
#
#   This module will use the following variables to change
#   default behaviour if set
#
#     parmetis_PREFIX
#     parmetis_INCLUDE_DIR
#     parmetis_LIBRARY_DIR
#     parmetis_LIBRARIES

#==================================================================
#   Copyright (c) 2018 The Regents of the University of California,
#   through Lawrence Berkeley National Laboratory.  
#
#   Author: David Williams-Young
#   
#   This file is part of cmake-modules. All rights reserved.
#   
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions are met:
#   
#   (1) Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#   (2) Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#   (3) Neither the name of the University of California, Lawrence Berkeley
#   National Laboratory, U.S. Dept. of Energy nor the names of its contributors may
#   be used to endorse or promote products derived from this software without
#   specific prior written permission.
#   
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
#   ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#   WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#   DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
#   ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#   (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#   LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
#   ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#   
#   You are under no obligation whatsoever to provide any bug fixes, patches, or
#   upgrades to the features, functionality or performance of the source code
#   ("Enhancements") to anyone; however, if you choose to make your Enhancements
#   available either publicly, or directly to Lawrence Berkeley National
#   Laboratory, without imposing a separate written license agreement for such
#   Enhancements, then you hereby grant the following license: a non-exclusive,
#   royalty-free perpetual license to install, use, modify, prepare derivative
#   works, incorporate into other computer software, distribute, and sublicense
#   such enhancements or derivative works thereof, in binary and source code form.
#
#==================================================================

cmake_minimum_required( VERSION 3.11 ) # Require CMake 3.11+

include(CMakeFindDependencyMacro)



# Set up some auxillary vars if hints have been set

if( parmetis_PREFIX AND NOT parmetis_INCLUDE_DIR )
  set( parmetis_INCLUDE_DIR ${parmetis_PREFIX}/include )
endif()


if( parmetis_PREFIX AND NOT parmetis_LIBRARY_DIR )
  set( parmetis_LIBRARY_DIR 
    ${parmetis_PREFIX}/lib 
    ${parmetis_PREFIX}/lib32 
    ${parmetis_PREFIX}/lib64 
  )
endif()

# Pass parmetis vars as metis vars if they exist
if( parmetis_PREFIX AND NOT metis_PREFIX )
  set( metis_PREFIX ${parmetis_PREFIX} )
endif()

if( parmetis_INCLUDE_DIR AND NOT metis_INCLUDE_DIR )
  set( metis_INCLUDE_DIR ${parmetis_INCLUDE_DIR} )
endif()

if( parmetis_LIBRARY_DIR AND NOT metis_LIBRARY_DIR )
  set( metis_LIBRARY_DIR ${parmetis_LIBRARY_DIR} )
endif()





# DEPENDENCIES

# Make sure C is enabled
get_property( ParMETIS_languages GLOBAL PROPERTY ENABLED_LANGUAGES )
if( NOT "C" IN_LIST ParMETIS_languages )
  message( FATAL_ERROR "C Language Must Be Enabled for ParMETIS Linkage" )
endif()


# METIS
if( NOT TARGET METIS::metis )
  find_dependency( METIS REQUIRED )
endif()


# MPI
if( NOT TARGET MPI::MPI_C )
  find_dependency( MPI REQUIRED )
endif()








# Try to find the header
find_path( ParMETIS_INCLUDE_DIR 
  NAMES parmetis.h
  HINTS ${parmetis_PREFIX}
  PATHS ${parmetis_INCLUDE_DIR}
  PATH_SUFFIXES include
  DOC "Location of ParMETIS header"
)

# Try to find libraries if not already set
if( NOT parmetis_LIBRARIES )

  find_library( ParMETIS_LIBRARIES
    NAMES parmetis
    HINTS ${parmetis_PREFIX}
    PATHS ${parmetis_LIBRARY_DIR}
    PATH_SUFFIXES lib lib64 lib32
    DOC "ParMETIS Libraries"
  )

else()

  # FIXME: Check if files exists at least?
  set( ParMETIS_LIBRARIES ${parmetis_LIBRARIES} )

endif()

# If not found, try to download and build with FetchContent
if(NOT ParMETIS_LIBRARIES OR NOT ParMETIS_INCLUDE_DIR)
  message(STATUS "ParMETIS not found on system, attempting to download and build...")
  
  include(FetchContent)
  
  # ParMETIS requires GKlib and METIS as dependencies
  # Download and build GKlib first (required for ParMETIS build)
  # Using a specific stable commit that works with METIS 5.1.0 and ParMETIS
  FetchContent_Declare(
    gklib
    GIT_REPOSITORY https://github.com/KarypisLab/GKlib.git
    GIT_TAG        8bd6bad750b2b0d90800c632cf18e8ee93ad72d7
  )
  
  # Build GKlib
  set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build shared libraries" FORCE)
  FetchContent_MakeAvailable(gklib)
  
  # Create include directory structure that ParMETIS expects
  # GKlib headers are in the root, but ParMETIS expects them in include/
  file(MAKE_DIRECTORY ${gklib_SOURCE_DIR}/include)
  file(GLOB GKLIB_HEADERS "${gklib_SOURCE_DIR}/*.h")
  foreach(header ${GKLIB_HEADERS})
    get_filename_component(header_name ${header} NAME)
    if(NOT EXISTS "${gklib_SOURCE_DIR}/include/${header_name}")
      file(CREATE_LINK ${header} "${gklib_SOURCE_DIR}/include/${header_name}" SYMBOLIC)
    endif()
  endforeach()
  
  message(STATUS "GKlib downloaded and built successfully")
  
  # Download METIS (if not already found)
  # Using git version compatible with the ParMETIS commit
  if(NOT TARGET METIS::metis)
    FetchContent_Declare(
      metis
      GIT_REPOSITORY https://github.com/KarypisLab/METIS.git
      GIT_TAG        94c03a6e2d1860128c2d0675cbbb86ad4f261256
    )
    
    FetchContent_MakeAvailable(metis)
    message(STATUS "METIS downloaded and configured successfully")
  endif()
  
  # Now download and configure ParMETIS with proper paths
  # Using specific commit compatible with METIS 5.1.0
  FetchContent_Declare(
    parmetis
    GIT_REPOSITORY https://github.com/KarypisLab/ParMETIS.git
    GIT_TAG        14d4bfe3848979d0c0610aac585f3e38746e9fad
  )
  
  # Configure ParMETIS build options
  set(BUILD_TESTING OFF CACHE BOOL "Build ParMETIS tests" FORCE)
  set(GKLIB_PATH ${gklib_SOURCE_DIR} CACHE PATH "Path to GKlib" FORCE)
  set(METIS_PATH ${metis_SOURCE_DIR} CACHE PATH "Path to METIS" FORCE)
  
  FetchContent_MakeAvailable(parmetis)
  
  if(parmetis_POPULATED)
    message(STATUS "ParMETIS downloaded and configured successfully")
    set(ParMETIS_INCLUDE_DIR ${parmetis_SOURCE_DIR}/include)
    set(ParMETIS_LIBRARIES parmetis)
    set(ParMETIS_FOUND TRUE)
    # METIS variables are already set from METIS::metis target
    if(NOT METIS_FOUND)
      set(METIS_INCLUDE_DIR ${metis_SOURCE_DIR}/include)
      set(METIS_LIBRARIES metis)
      set(METIS_FOUND TRUE)
    endif()
  endif()
else()
  # Check version
  if( EXISTS ${ParMETIS_INCLUDE_DIR}/parmetis.h )

    set( version_pattern 
    "^#define[\t ]+ParMETIS_(MAJOR|MINOR|SUBMINOR)_VERSION[\t ]+([0-9\\.]+)$"
    )
    file( STRINGS ${ParMETIS_INCLUDE_DIR}/parmetis.h parmetis_version
          REGEX ${version_pattern} )
    
    foreach( match ${parmetis_version} )
    
      if(ParMETIS_VERSION_STRING)
        set(ParMETIS_VERSION_STRING "${ParMETIS_VERSION_STRING}.")
      endif()
    
      string(REGEX REPLACE ${version_pattern} 
        "${ParMETIS_VERSION_STRING}\\2" 
        ParMETIS_VERSION_STRING ${match}
      )
    
      set(ParMETIS_VERSION_${CMAKE_MATCH_1} ${CMAKE_MATCH_2})
    
    endforeach()
    
    unset( parmetis_version )
    unset( version_pattern )

  endif()

  # Check ILP64 (Inherits from METIS)
  if( METIS_FOUND )

    set( ParMETIS_USES_ILP64 ${METIS_USES_ILP64} )

  endif()

  # Handle components
  if( ParMETIS_USES_ILP64 )
    set( ParMETIS_ilp64_FOUND TRUE )
  endif()




  # Determine if we've found ParMETIS
  mark_as_advanced( ParMETIS_FOUND ParMETIS_INCLUDE_DIR ParMETIS_LIBRARIES )

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args( ParMETIS
    REQUIRED_VARS ParMETIS_LIBRARIES ParMETIS_INCLUDE_DIR METIS_FOUND 
    VERSION_VAR ParMETIS_VERSION_STRING
    HANDLE_COMPONENTS
  )
endif()

# Export target
if( ParMETIS_FOUND AND NOT TARGET ParMETIS::parmetis )

  add_library( ParMETIS::parmetis INTERFACE IMPORTED )
  set_target_properties( ParMETIS::parmetis PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${ParMETIS_INCLUDE_DIR}"
    INTERFACE_LINK_LIBRARIES      "${ParMETIS_LIBRARIES};METIS::metis;MPI::MPI_C" 
  )

endif()
