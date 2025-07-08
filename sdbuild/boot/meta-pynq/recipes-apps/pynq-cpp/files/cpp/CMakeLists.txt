cmake_minimum_required(VERSION 3.8)

project(PYNQ_Remote C CXX)

include(../cmake/common.cmake)
set (CMAKE_CXX_STANDARD 17) #For filesystem checks & unique_ptr

# Proto file
get_filename_component(remote_device_proto "../protos/remote_device.proto" ABSOLUTE)
get_filename_component(remote_device_proto_path "${remote_device_proto}" PATH)

get_filename_component(mmio_proto "../protos/mmio.proto" ABSOLUTE)
get_filename_component(mmio_proto_path "${mmio_proto}" PATH)

get_filename_component(buffer_proto "../protos/buffer.proto" ABSOLUTE)
get_filename_component(buffer_proto_path "${buffer_proto}" PATH)

# Generated sources
set(remote_device_proto_srcs "${CMAKE_CURRENT_BINARY_DIR}/remote_device.pb.cc")
set(remote_device_proto_hdrs "${CMAKE_CURRENT_BINARY_DIR}/remote_device.pb.h")
set(remote_device_grpc_srcs "${CMAKE_CURRENT_BINARY_DIR}/remote_device.grpc.pb.cc")
set(remote_device_grpc_hdrs "${CMAKE_CURRENT_BINARY_DIR}/remote_device.grpc.pb.h")

set(mmio_proto_srcs "${CMAKE_CURRENT_BINARY_DIR}/mmio.pb.cc")
set(mmio_proto_hdrs "${CMAKE_CURRENT_BINARY_DIR}/mmio.pb.h")
set(mmio_grpc_srcs "${CMAKE_CURRENT_BINARY_DIR}/mmio.grpc.pb.cc")
set(mmio_grpc_hdrs "${CMAKE_CURRENT_BINARY_DIR}/mmio.grpc.pb.h")

set(buffer_proto_srcs "${CMAKE_CURRENT_BINARY_DIR}/buffer.pb.cc")
set(buffer_proto_hdrs "${CMAKE_CURRENT_BINARY_DIR}/buffer.pb.h")
set(buffer_grpc_srcs "${CMAKE_CURRENT_BINARY_DIR}/buffer.grpc.pb.cc")
set(buffer_grpc_hdrs "${CMAKE_CURRENT_BINARY_DIR}/buffer.grpc.pb.h")

add_custom_command(
  OUTPUT "${remote_device_proto_srcs}" "${remote_device_proto_hdrs}" "${remote_device_grpc_srcs}" "${remote_device_grpc_hdrs}" 
  "${mmio_proto_srcs}" "${mmio_proto_hdrs}" "${mmio_grpc_srcs}" "${mmio_grpc_hdrs}"
  "${buffer_proto_srcs}" "${buffer_proto_hdrs}" "${buffer_grpc_srcs}" "${buffer_grpc_hdrs}"
  COMMAND ${_PROTOBUF_PROTOC}
  ARGS --grpc_out "${CMAKE_CURRENT_BINARY_DIR}"
  --cpp_out "${CMAKE_CURRENT_BINARY_DIR}"
  -I "${remote_device_proto_path}"
  --plugin=protoc-gen-grpc="${_GRPC_CPP_PLUGIN_EXECUTABLE}"
  "${remote_device_proto}"
  "${mmio_proto}"
  "${buffer_proto}"
  DEPENDS "${remote_device_proto}" "${mmio_proto}" "${buffer_proto}")

message(STATUS "CMAKE CURRENT DIR = ${CMAKE_CURRENT_SOURCE_DIR}")
# Change to whatever the Petalinux project path - will need to change this at some point

# Navigate up the directory hierarchy to find the project root
get_filename_component(BASE_DIR "${CMAKE_CURRENT_SOURCE_DIR}" DIRECTORY)
get_filename_component(BASE_DIR "${BASE_DIR}" DIRECTORY)
get_filename_component(BASE_DIR "${BASE_DIR}" DIRECTORY)
get_filename_component(BASE_DIR "${BASE_DIR}" DIRECTORY)
get_filename_component(BASE_DIR "${BASE_DIR}" DIRECTORY)
get_filename_component(BASE_DIR "${BASE_DIR}" DIRECTORY)
get_filename_component(BASE_DIR "${BASE_DIR}" DIRECTORY)

message(STATUS "BASE_DIR (Project Path) = ${BASE_DIR}")

# Define an option for using custom XRT paths
option(USE_LOCAL_XRT "Use custom XRT include and library paths" OFF)

# Check if USE_LOCAL_XRT is ON
if(USE_LOCAL_XRT)
    # Hard code custom XRT paths
    set(XRT_INCLUDE_DIRS "/usr/include")
    set(XRT_LIBRARIES "/usr/lib/libxrt_core.so")
    set(XRT_ADDITIONAL_LIBRARIES "/usr/lib/libxrt_coreutil.so")
else()
    # Hard code default XRT paths
    # Explicitly set the paths for XRT
    set(XRT_INCLUDE_DIRS "${BASE_DIR}/build/tmp/sysroots-components/cortexa72-cortexa53/xrt/usr/include")
    set(XRT_LIBRARIES "${BASE_DIR}/build/tmp/sysroots-components/cortexa72-cortexa53/xrt/usr/lib/libxrt_core.so")

    # Additional XRT libraries (if needed)
    set(XRT_ADDITIONAL_LIBRARIES "${BASE_DIR}/build/tmp/sysroots-components/cortexa72-cortexa53/xrt/usr/lib/libxrt_coreutil.so")
endif()

if(EXISTS "${XRT_INCLUDE_DIRS}/xrt/xrt.h" AND EXISTS "${XRT_LIBRARIES}")
    message(STATUS "Found XRT: includes in ${XRT_INCLUDE_DIRS}, libs in ${XRT_LIBRARIES}")
else()
    message(FATAL_ERROR "Could not find XRT")
endif()

# Include directories, explicitly excluding deprecated
include_directories(${XRT_INCLUDE_DIRS})
include_directories("${XRT_INCLUDE_DIRS}/xrt")  # Add xrt directly to prevent using deprecated

# Include generated *.pb.h files and remote_server.h
include_directories("${CMAKE_CURRENT_BINARY_DIR}")

set(BUILD_SHARED_LIBS OFF)
# buffer_grpc_proto
add_library(buffer_grpc_proto
  ${buffer_grpc_srcs}
  ${buffer_grpc_hdrs}
  ${buffer_proto_srcs}
  ${buffer_proto_hdrs})

# mmio_grpc_proto
add_library(mmio_grpc_proto
  ${mmio_grpc_srcs}
  ${mmio_grpc_hdrs}
  ${mmio_proto_srcs}
  ${mmio_proto_hdrs})

# remote_device_grpc_proto
add_library(remote_device_grpc_proto
  ${remote_device_grpc_srcs}
  ${remote_device_grpc_hdrs}
  ${remote_device_proto_srcs}
  ${remote_device_proto_hdrs})

add_library(pynq
  buffer.cc
  mmio.cc
  device.cc
)

target_link_libraries(remote_device_grpc_proto
  mmio_grpc_proto
  buffer_grpc_proto
  ${_REFLECTION}
  ${_GRPC_GRPCPP}
  ${_PROTOBUF_LIBPROTOBUF})

# Targets remote_(client|server)
foreach(_target
  pynq-remote)
  add_executable(${_target} "${_target}.cc")
  target_link_libraries(${_target}
    pynq
    remote_device_grpc_proto
    mmio_grpc_proto
    buffer_grpc_proto
    ${_REFLECTION}
    ${_GRPC_GRPCPP}
    ${_PROTOBUF_LIBPROTOBUF}
    ${XRT_LIBRARIES}
    ${XRT_ADDITIONAL_LIBRARIES})  # Link against additional XRT libraries if necessary
endforeach()