# Project-level configuration.
cmake_minimum_required(VERSION 3.13)
project(runner LANGUAGES CXX)

# The name of the executable created for the application. Change this to change
# the on-disk name of your application.
set(BINARY_NAME "meshcore_open")
# The unique GTK application identifier for this application. See:
# https://wiki.gnome.org/HowDoI/ChooseApplicationID
set(APPLICATION_ID "com.meshcore.meshcore_open")

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(SET CMP0063 NEW)

# Load bundled libraries from the lib/ directory relative to the binary.
set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")

# Root filesystem for cross-building.
if(FLUTTER_TARGET_PLATFORM_SYSROOT)
  set(CMAKE_SYSROOT ${FLUTTER_TARGET_PLATFORM_SYSROOT})
  set(CMAKE_FIND_ROOT_PATH ${CMAKE_SYSROOT})
  set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
  set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
endif()

# Define build configuration options.
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE "Debug" CACHE
    STRING "Flutter build mode" FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
    "Debug" "Profile" "Release")
endif()

# Compilation settings that should be applied to most targets.
#
# Be cautious about adding new options here, as plugins use this function by
# default. In most cases, you should add new options to specific targets instead
# of modifying this function.
function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_14)
  target_compile_options(${TARGET} PRIVATE -Wall -Werror)
  target_compile_options(${TARGET} PRIVATE "$<$<NOT:$<CONFIG:Debug>>:-O3>")
  target_compile_definitions(${TARGET} PRIVATE "$<$<NOT:$<CONFIG:Debug>>:NDEBUG>")
endfunction()

# Flutter library and tool build rules.
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# System-level dependencies.
find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)

# Application build; see runner/CMakeLists.txt.
add_subdirectory("runner")

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)

# Only the install-generated bundle's copy of the executable will launch
# correctly, since the resources must in the right relative locations. To avoid
# people trying to run the unbundled copy, put it in a subdirectory instead of
# the default top-level location.
set_target_properties(${BINARY_NAME}
  PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/intermediates_do_not_run"
)


# Generated plugin build rules, which manage building the plugins and adding
# them to the application.
include(flutter/generated_plugins.cmake)

# Work around tinycthread/glibc 2.43+ conflict: glibc 2.43 (with Clang 21's
# C23 default) exports once_flag from stdlib.h bt tinycthread in flserial
# defines once_flag as a preprocessor macro, causing a typedef clash.
# __STDC_NO_THREADS__ suppresses the C23 once_flag declaration in glibc stdlib.h.
if(TARGET flserial)
  target_compile_definitions(flserial PRIVATE __STDC_NO_THREADS__)
endif()

# Issue zjs81/meshcore-open#600: the release zip must contain
# libonnxruntime.so.1 and must not depend on the build machine's absolute
# path. The plugin is linked against that library by absolute path, so CMake
# records the download directory as the plugin RUNPATH, and install(FILES)
# ships that build-tree file unchanged. The loader uses the plugin RUNPATH,
# not the executable RPATH, when resolving the plugin's libonnxruntime.so.1
# dependency. Keep the download directory so ld can resolve the SONAME while
# linking meshcore_open, and add $ORIGIN so the copy installed next to the
# plugin is found on a machine that does not have this build tree. Do not set
# SKIP_BUILD_RPATH: without the download directory the link fails with
# "libonnxruntime.so.1, needed by libflutter_onnxruntime_plugin.so, not found".
if(TARGET flutter_onnxruntime_plugin)
  file(GLOB _onnx_link_libs
    "${CMAKE_BINARY_DIR}/plugins/flutter_onnxruntime/onnxruntime/onnxruntime-linux-*/lib/libonnxruntime.so"
    "${PROJECT_BINARY_DIR}/plugins/flutter_onnxruntime/onnxruntime/onnxruntime-linux-*/lib/libonnxruntime.so")
  if(_onnx_link_libs)
    list(GET _onnx_link_libs 0 _onnx_link_lib)
    get_filename_component(_onnx_lib_dir "${_onnx_link_lib}" DIRECTORY)
    set_target_properties(flutter_onnxruntime_plugin PROPERTIES
      BUILD_RPATH "\$ORIGIN;${_onnx_lib_dir}")
  endif()
endif()
set_target_properties(${BINARY_NAME} PROPERTIES
  INSTALL_RPATH "$ORIGIN/lib")
target_link_options(${BINARY_NAME} PRIVATE "-Wl,--disable-new-dtags")


# === Installation ===
# By default, "installing" just makes a relocatable bundle in the build
# directory.
set(BUILD_BUNDLE_DIR "${PROJECT_BINARY_DIR}/bundle")
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)
endif()

# Start with a clean build bundle directory every time.
install(CODE "
  file(REMOVE_RECURSE \"${BUILD_BUNDLE_DIR}/\")
  " COMPONENT Runtime)

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}/lib")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)

foreach(bundled_library ${PLUGIN_BUNDLED_LIBRARIES})
  install(FILES "${bundled_library}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endforeach(bundled_library)

# Copy ONNX Runtime under the names the dynamic linker asks for. The plugin
# bundles libonnxruntime.so, which is a symlink; the NEEDED entry is
# libonnxruntime.so.1.
install(CODE "
  set(_onnx_roots
    \"${CMAKE_BINARY_DIR}/plugins/flutter_onnxruntime/onnxruntime\"
    \"${PROJECT_BINARY_DIR}/plugins/flutter_onnxruntime/onnxruntime\")
  foreach(_root \${_onnx_roots})
    file(GLOB _onnx_libs
      \"\${_root}/onnxruntime-linux-*/lib/libonnxruntime.so*\"
      \"\${_root}/onnxruntime-linux-*/lib/libonnxruntime_providers_shared.so\")
    foreach(_lib \${_onnx_libs})
      get_filename_component(_name \"\${_lib}\" NAME)
      execute_process(COMMAND readlink -f \"\${_lib}\"
        OUTPUT_VARIABLE _real OUTPUT_STRIP_TRAILING_WHITESPACE)
      execute_process(COMMAND \"${CMAKE_COMMAND}\" -E copy
        \"\${_real}\" \"${INSTALL_BUNDLE_LIB_DIR}/\${_name}\")
    endforeach()
  endforeach()
  " COMPONENT Runtime)

# Copy the native assets provided by the build.dart from all packages.
set(NATIVE_ASSETS_DIR "${PROJECT_BUILD_DIR}native_assets/linux/")
install(DIRECTORY "${NATIVE_ASSETS_DIR}"
   DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
   COMPONENT Runtime)

# Fully re-copy the assets directory on each build to avoid having stale files
# from a previous install.
set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "
  file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")
  " COMPONENT Runtime)
install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
  DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

# Install the AOT library on non-Debug builds only.
if(NOT CMAKE_BUILD_TYPE MATCHES "Debug")
  install(FILES "${AOT_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endif()
