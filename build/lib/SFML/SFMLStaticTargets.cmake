# Generated by CMake

if("${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION}" LESS 2.6)
   message(FATAL_ERROR "CMake >= 2.6.0 required")
endif()
cmake_policy(PUSH)
cmake_policy(VERSION 2.6...3.20)
#----------------------------------------------------------------
# Generated CMake target import file.
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

if(CMAKE_VERSION VERSION_LESS 3.0.0)
  message(FATAL_ERROR "This file relies on consumers using CMake 3.0.0 or greater.")
endif()

# Protect against multiple inclusion, which would fail when already imported targets are added once more.
set(_targetsDefined)
set(_targetsNotDefined)
set(_expectedTargets)
foreach(_expectedTarget sfml-system OpenAL Vorbis FLAC sfml-audio)
  list(APPEND _expectedTargets ${_expectedTarget})
  if(NOT TARGET ${_expectedTarget})
    list(APPEND _targetsNotDefined ${_expectedTarget})
  endif()
  if(TARGET ${_expectedTarget})
    list(APPEND _targetsDefined ${_expectedTarget})
  endif()
endforeach()
if("${_targetsDefined}" STREQUAL "${_expectedTargets}")
  unset(_targetsDefined)
  unset(_targetsNotDefined)
  unset(_expectedTargets)
  set(CMAKE_IMPORT_FILE_VERSION)
  cmake_policy(POP)
  return()
endif()
if(NOT "${_targetsDefined}" STREQUAL "")
  message(FATAL_ERROR "Some (but not all) targets in this export set were already defined.\nTargets Defined: ${_targetsDefined}\nTargets not yet defined: ${_targetsNotDefined}\n")
endif()
unset(_targetsDefined)
unset(_targetsNotDefined)
unset(_expectedTargets)


# Create imported target sfml-system
add_library(sfml-system STATIC IMPORTED)

set_target_properties(sfml-system PROPERTIES
  INTERFACE_COMPILE_DEFINITIONS "SFML_STATIC"
  INTERFACE_INCLUDE_DIRECTORIES "/home/kleinc/TDT4230-Project/lib/SFML/include"
  INTERFACE_LINK_LIBRARIES "\$<LINK_ONLY:pthread>;\$<LINK_ONLY:rt>"
)

# Create imported target OpenAL
add_library(OpenAL INTERFACE IMPORTED)

set_target_properties(OpenAL PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "/usr/include/AL"
  INTERFACE_LINK_LIBRARIES "/usr/lib/x86_64-linux-gnu/libopenal.so"
)

# Create imported target Vorbis
add_library(Vorbis INTERFACE IMPORTED)

set_target_properties(Vorbis PROPERTIES
  INTERFACE_COMPILE_DEFINITIONS "OV_EXCLUDE_STATIC_CALLBACKS"
  INTERFACE_INCLUDE_DIRECTORIES "/usr/include;/usr/include"
  INTERFACE_LINK_LIBRARIES "/usr/lib/x86_64-linux-gnu/libvorbisenc.so;/usr/lib/x86_64-linux-gnu/libvorbisfile.so;/usr/lib/x86_64-linux-gnu/libvorbis.so;/usr/lib/x86_64-linux-gnu/libogg.so"
)

# Create imported target FLAC
add_library(FLAC INTERFACE IMPORTED)

set_target_properties(FLAC PROPERTIES
  INTERFACE_COMPILE_DEFINITIONS "FLAC__NO_DLL"
  INTERFACE_INCLUDE_DIRECTORIES "/usr/include"
  INTERFACE_LINK_LIBRARIES "/usr/lib/x86_64-linux-gnu/libFLAC.so"
)

# Create imported target sfml-audio
add_library(sfml-audio STATIC IMPORTED)

set_target_properties(sfml-audio PROPERTIES
  INTERFACE_COMPILE_DEFINITIONS "SFML_STATIC"
  INTERFACE_INCLUDE_DIRECTORIES "/home/kleinc/TDT4230-Project/lib/SFML/include"
  INTERFACE_LINK_LIBRARIES "\$<LINK_ONLY:OpenAL>;sfml-system;\$<LINK_ONLY:Vorbis>;\$<LINK_ONLY:FLAC>"
)

# Import target "sfml-system" for configuration ""
set_property(TARGET sfml-system APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
set_target_properties(sfml-system PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_NOCONFIG "CXX"
  IMPORTED_LOCATION_NOCONFIG "/home/kleinc/TDT4230-Project/build/lib/SFML/lib/libsfml-system.a"
  )

# Import target "sfml-audio" for configuration ""
set_property(TARGET sfml-audio APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
set_target_properties(sfml-audio PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_NOCONFIG "CXX"
  IMPORTED_LOCATION_NOCONFIG "/home/kleinc/TDT4230-Project/build/lib/SFML/lib/libsfml-audio.a"
  )

# This file does not depend on other imported targets which have
# been exported from the same project but in a separate export set.

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
cmake_policy(POP)
