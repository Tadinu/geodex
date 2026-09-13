cmake_minimum_required(VERSION 3.20)
project(geodex VERSION 0.2.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)
include(FetchContent)

# Eigen3
find_package(Eigen3 REQUIRED)

# Header-only interface library
add_library(geodex INTERFACE)
add_library(geodex::geodex ALIAS geodex)
target_include_directories(geodex INTERFACE
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)
target_link_libraries(geodex INTERFACE Eigen3::Eigen)
target_compile_features(geodex INTERFACE cxx_std_20)

# OMPL (shared by tests and examples when BUILD_OMPL_EXAMPLES is ON)
option(BUILD_OMPL_EXAMPLES "Build OMPL integration examples (requires OMPL)" OFF)
if(BUILD_OMPL_EXAMPLES)
  set(OMPL_BUILD_DEMOS OFF CACHE BOOL "" FORCE)
  set(OMPL_BUILD_TESTS OFF CACHE BOOL "" FORCE)
  FetchContent_Declare(
    ompl
    GIT_REPOSITORY https://github.com/utiasSTARS/ompl.git #https://github.com/ompl/ompl.git
    GIT_TAG planner/greedyrrtstar #1.7.0
    GIT_SHALLOW    TRUE
    SYSTEM
    EXCLUDE_FROM_ALL
  )
  if(NOT TARGET eigen)
    add_library(eigen INTERFACE IMPORTED GLOBAL)
    target_link_libraries(eigen INTERFACE Eigen3::Eigen)
  endif()
  FetchContent_MakeAvailable(ompl)
endif()

# YAML-CPP
FetchContent_Declare(
    yaml-cpp
    GIT_REPOSITORY https://github.com/jbeder/yaml-cpp.git
    GIT_TAG master #0.8.0
    GIT_SHALLOW    TRUE
    SYSTEM
    EXCLUDE_FROM_ALL
)
FetchContent_MakeAvailable(yaml-cpp)

# Pinocchio
#set(BUILD_PYTHON_INTERFACE OFF CACHE BOOL "Disable Python bindings" FORCE)
#set(BUILD_TESTING OFF CACHE BOOL "Disable Pinocchio tests" FORCE)
#set(BUILD_BENCHMARK OFF CACHE BOOL "Disable Pinocchio benchmarks" FORCE)
#set(BUILD_WITH_URDF_SUPPORT ON CACHE BOOL "Enable URDF support" FORCE)

# eigenpy
FetchContent_Declare(
    eigenpy
    GIT_REPOSITORY https://github.com/stack-of-tasks/eigenpy.git
    GIT_TAG        v3.13.0
    FIND_PACKAGE_ARGS CONFIG
)
FetchContent_MakeAvailable(eigenpy)

FetchContent_Declare(
    pinocchio
    GIT_REPOSITORY https://github.com/stack-of-tasks/pinocchio.git
    GIT_TAG        v4.1.0
    GIT_SHALLOW    TRUE
    FIND_PACKAGE_ARGS CONFIG
)
FetchContent_MakeAvailable(pinocchio)

# Robot dynamics (precompiled CRBA mass matrices)
option(GEODEX_ROBOTS "Build the built-in robot dynamics library" ON)
if(GEODEX_ROBOTS)
  include(cmake/robots.cmake)
endif()

# Optional integrations
include(cmake/integrations/pinocchio.cmake)
include(cmake/integrations/vamp.cmake)

# Tests
option(BUILD_TESTING "Build tests" OFF)
if(BUILD_TESTING)
  enable_testing()
  add_subdirectory(tests)
endif()

# Examples
option(BUILD_EXAMPLES "Build examples" OFF)
if(BUILD_EXAMPLES)
  add_subdirectory(examples)
endif()

# OMPL integration examples
if(BUILD_OMPL_EXAMPLES)
  add_subdirectory(examples/ompl)
  add_subdirectory(examples/manipulator_planning)
endif()

# Benchmarks
option(BUILD_BENCHMARKS "Build performance benchmarks" OFF)
if(BUILD_BENCHMARKS)
  add_subdirectory(benchmarks)
endif()

# Python bindings
option(BUILD_PYTHON_BINDINGS "Build Python bindings via nanobind" OFF)
if(BUILD_PYTHON_BINDINGS)
  add_subdirectory(python)
endif()

# Documentation
option(BUILD_DOCS "Build documentation" OFF)
if(BUILD_DOCS)
  find_package(Doxygen REQUIRED)
  configure_file(docs/Doxyfile.in ${CMAKE_BINARY_DIR}/Doxyfile @ONLY)
  file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/docs/doxygen)
  add_custom_target(docs
    COMMAND ${DOXYGEN_EXECUTABLE} ${CMAKE_BINARY_DIR}/Doxyfile
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Generating API documentation with Doxygen"
    VERBATIM)

  find_program(SPHINX_EXECUTABLE sphinx-build
    HINTS ${CMAKE_SOURCE_DIR}/.venv/bin)
  if(SPHINX_EXECUTABLE)
    add_custom_target(sphinx
      COMMAND ${SPHINX_EXECUTABLE} -b html ${CMAKE_SOURCE_DIR}/docs ${CMAKE_BINARY_DIR}/docs/sphinx
      DEPENDS docs
      COMMENT "Building Sphinx documentation"
      VERBATIM)
  endif()
endif()

# Install
#install(TARGETS geodex
#  EXPORT geodexTargets
#)

install(DIRECTORY include/
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

install(DIRECTORY ${eigen_SOURCE_DIR}/Eigen
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

#install(EXPORT geodexTargets
#  FILE geodexTargets.cmake
#  NAMESPACE geodex::
#  DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/geodex
#)

configure_package_config_file(
  cmake/geodexConfig.cmake.in
  ${CMAKE_CURRENT_BINARY_DIR}/geodexConfig.cmake
  INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/geodex
)

write_basic_package_version_file(
  ${CMAKE_CURRENT_BINARY_DIR}/geodexConfigVersion.cmake
  VERSION ${PROJECT_VERSION}
  COMPATIBILITY SameMajorVersion
)

install(FILES
  ${CMAKE_CURRENT_BINARY_DIR}/geodexConfig.cmake
  ${CMAKE_CURRENT_BINARY_DIR}/geodexConfigVersion.cmake
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/geodex
)
