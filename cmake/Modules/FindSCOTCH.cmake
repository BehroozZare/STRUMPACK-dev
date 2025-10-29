#   FindSCOTCH.cmake
#
#   Finds the SCOTCH library.
#
#   This module will define the following variables:
#   
#     SCOTCH_FOUND         - System has found SCOTCH installation
#     SCOTCH_INCLUDE_DIR   - Location of SCOTCH headers
#     SCOTCH_LIBRARIES     - SCOTCH libraries
#     PTSCOTCH_FOUND       - System has found PT-SCOTCH
#     PTSCOTCH_LIBRARIES   - PT-SCOTCH libraries
#
#   This module will export the following targets if SCOTCH_FOUND
#
#     SCOTCH::scotch
#     SCOTCH::ptscotch (if PT-SCOTCH is found)
#
#   This module will use the following variables to change
#   default behaviour if set
#
#     scotch_PREFIX
#     scotch_INCLUDE_DIR
#     scotch_LIBRARY_DIR
#     scotch_LIBRARIES
#     ptscotch_LIBRARIES
#
#   To install SCOTCH on Ubuntu/Debian:
#     sudo apt-get install libscotch-dev libptscotch-dev

cmake_minimum_required(VERSION 3.11)

include(CMakeFindDependencyMacro)

# Set up some auxiliary vars if hints have been set
if(scotch_PREFIX AND NOT scotch_INCLUDE_DIR)
  set(scotch_INCLUDE_DIR ${scotch_PREFIX}/include)
endif()

if(scotch_PREFIX AND NOT scotch_LIBRARY_DIR)
  set(scotch_LIBRARY_DIR 
    ${scotch_PREFIX}/lib 
    ${scotch_PREFIX}/lib32 
    ${scotch_PREFIX}/lib64 
  )
endif()

# Try to find the header
find_path(SCOTCH_INCLUDE_DIR 
  NAMES scotch.h
  HINTS ${scotch_PREFIX}
  PATHS ${scotch_INCLUDE_DIR}
  PATH_SUFFIXES include include/scotch
  DOC "Location of SCOTCH header"
)

# Try to find libraries if not already set
if(NOT scotch_LIBRARIES)
  find_library(SCOTCH_LIBRARIES
    NAMES scotch
    HINTS ${scotch_PREFIX}
    PATHS ${scotch_LIBRARY_DIR}
    PATH_SUFFIXES lib lib64 lib32
    DOC "SCOTCH Libraries"
  )
else()
  set(SCOTCH_LIBRARIES ${scotch_LIBRARIES})
endif()

# Try to find PT-SCOTCH
if(NOT ptscotch_LIBRARIES)
  find_library(PTSCOTCH_LIBRARIES
    NAMES ptscotch
    HINTS ${scotch_PREFIX}
    PATHS ${scotch_LIBRARY_DIR}
    PATH_SUFFIXES lib lib64 lib32
    DOC "PT-SCOTCH Libraries"
  )
else()
  set(PTSCOTCH_LIBRARIES ${ptscotch_LIBRARIES})
endif()

# Find scotcherr and scotcherrexit (often required)
find_library(SCOTCH_ERR_LIBRARY
  NAMES scotcherr
  HINTS ${scotch_PREFIX}
  PATHS ${scotch_LIBRARY_DIR}
  PATH_SUFFIXES lib lib64 lib32
)

find_library(SCOTCH_ERREXIT_LIBRARY
  NAMES scotcherrexit
  HINTS ${scotch_PREFIX}
  PATHS ${scotch_LIBRARY_DIR}
  PATH_SUFFIXES lib lib64 lib32
)

# Find ptscotcherr and ptscotcherrexit (for PT-SCOTCH)
find_library(PTSCOTCH_ERR_LIBRARY
  NAMES ptscotcherr
  HINTS ${scotch_PREFIX}
  PATHS ${scotch_LIBRARY_DIR}
  PATH_SUFFIXES lib lib64 lib32
)

find_library(PTSCOTCH_ERREXIT_LIBRARY
  NAMES ptscotcherrexit
  HINTS ${scotch_PREFIX}
  PATHS ${scotch_LIBRARY_DIR}
  PATH_SUFFIXES lib lib64 lib32
)

# Determine if we've found SCOTCH
mark_as_advanced(SCOTCH_FOUND SCOTCH_INCLUDE_DIR SCOTCH_LIBRARIES)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(SCOTCH
  REQUIRED_VARS SCOTCH_LIBRARIES SCOTCH_INCLUDE_DIR
)

# Check for PT-SCOTCH
if(PTSCOTCH_LIBRARIES)
  set(PTSCOTCH_FOUND TRUE)
  message(STATUS "Found PT-SCOTCH")
endif()

# Export target for SCOTCH
if(SCOTCH_FOUND AND NOT TARGET SCOTCH::scotch)
  add_library(SCOTCH::scotch INTERFACE IMPORTED)
  
  set_target_properties(SCOTCH::scotch PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${SCOTCH_INCLUDE_DIR}"
    INTERFACE_LINK_LIBRARIES      "${SCOTCH_LIBRARIES}" 
  )
endif()

# Export separate targets for SCOTCH error libraries
if(SCOTCH_FOUND AND SCOTCH_ERR_LIBRARY AND NOT TARGET SCOTCH::scotcherr)
  add_library(SCOTCH::scotcherr INTERFACE IMPORTED)
  set_target_properties(SCOTCH::scotcherr PROPERTIES
    INTERFACE_LINK_LIBRARIES "${SCOTCH_ERR_LIBRARY}"
  )
endif()

if(SCOTCH_FOUND AND SCOTCH_ERREXIT_LIBRARY AND NOT TARGET SCOTCH::scotcherrexit)
  add_library(SCOTCH::scotcherrexit INTERFACE IMPORTED)
  set_target_properties(SCOTCH::scotcherrexit PROPERTIES
    INTERFACE_LINK_LIBRARIES "${SCOTCH_ERREXIT_LIBRARY}"
  )
endif()

# Export target for PT-SCOTCH
if(PTSCOTCH_FOUND AND NOT TARGET SCOTCH::ptscotch)
  # Find MPI dependency for PT-SCOTCH
  if(NOT TARGET MPI::MPI_C)
    find_dependency(MPI REQUIRED)
  endif()
  
  add_library(SCOTCH::ptscotch INTERFACE IMPORTED)
  
  set_target_properties(SCOTCH::ptscotch PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${SCOTCH_INCLUDE_DIR}"
    INTERFACE_LINK_LIBRARIES      "${PTSCOTCH_LIBRARIES};SCOTCH::scotch;MPI::MPI_C" 
  )
endif()

# Export separate targets for PT-SCOTCH error libraries
if(PTSCOTCH_FOUND AND PTSCOTCH_ERR_LIBRARY AND NOT TARGET SCOTCH::ptscotcherr)
  add_library(SCOTCH::ptscotcherr INTERFACE IMPORTED)
  set_target_properties(SCOTCH::ptscotcherr PROPERTIES
    INTERFACE_LINK_LIBRARIES "${PTSCOTCH_ERR_LIBRARY}"
  )
endif()

if(PTSCOTCH_FOUND AND PTSCOTCH_ERREXIT_LIBRARY AND NOT TARGET SCOTCH::ptscotcherrexit)
  add_library(SCOTCH::ptscotcherrexit INTERFACE IMPORTED)
  set_target_properties(SCOTCH::ptscotcherrexit PROPERTIES
    INTERFACE_LINK_LIBRARIES "${PTSCOTCH_ERREXIT_LIBRARY}"
  )
endif()

# Provide helpful message if not found
if(NOT SCOTCH_FOUND)
  message(STATUS "SCOTCH not found. To install on Ubuntu/Debian:")
  message(STATUS "  sudo apt-get install libscotch-dev libptscotch-dev")
  message(STATUS "Or set scotch_PREFIX to point to your SCOTCH installation")
endif()

