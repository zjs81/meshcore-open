# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(flserial_library VERSION 0.3.5 LANGUAGES C CXX)

if(MSVC)
    add_definitions(-D_CRT_SECURE_NO_WARNINGS)
endif()

set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(SRC_FILES
  "native_libs/src/serial.cpp"
  "native_libs/src/tinycthread.c"
  "native_libs/src/ringbuffer.c"
  "flserial.cpp"
  "flserial.def"
)

if(APPLE)
    list(APPEND SRC_FILES native_libs/src/impl/unix.cpp)
    list(APPEND SRC_FILES native_libs/src/impl/list_ports/list_ports_osx.cpp)
elseif(ANDROID)
    list(APPEND SRC_FILES native_libs/src/cglob.c)
    list(APPEND SRC_FILES native_libs/src/impl/unix.cpp)
    list(APPEND SRC_FILES native_libs/src/impl/list_ports/list_ports_linux.cpp)
elseif(UNIX)
    list(APPEND SRC_FILES native_libs/src/impl/unix.cpp)
    list(APPEND SRC_FILES native_libs/src/impl/list_ports/list_ports_linux.cpp)
else()
    list(APPEND SRC_FILES native_libs/src/impl/win.cpp)
    list(APPEND SRC_FILES native_libs/src/impl/list_ports/list_ports_win.cpp)
endif()

add_library(flserial SHARED ${SRC_FILES})

if(APPLE)
elseif(ANDROID)
  target_link_options(flserial PRIVATE "-Wl,-z,max-page-size=16384")
elseif(UNIX)
  target_link_libraries(flserial rt pthread)
else()
  target_link_libraries(flserial setupapi)
endif()




include_directories(native_libs/include native_libs/include/serial)

set_target_properties(flserial PROPERTIES
  PUBLIC_HEADER flserial.h
  OUTPUT_NAME "flserial"
)

target_compile_definitions(flserial PUBLIC DART_SHARED_LIB)
