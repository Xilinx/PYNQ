cmake_minimum_required(VERSION 3.8)

project(PYNQ_Remote C CXX)

include(../cmake/common.cmake)
set (CMAKE_CXX_STANDARD 17) #For filesystem checks & unique_ptr

# RFSoC services (xrfdc, xrfclk) are RFSoC-board-only. The PYNQ Makefile
# sets PACKAGECONFIG to "rfsoc" via a per-project bbappend when RFSoC_<board>=1,
# which adds -DRFSOC=ON to EXTRA_OECMAKE.
option(RFSOC "Build RFSoC services (xrfdc, xrfclk)" OFF)
message(STATUS "RFSOC = ${RFSOC}")

# Proto file
get_filename_component(remote_device_proto "../protos/remote_device.proto" ABSOLUTE)
get_filename_component(remote_device_proto_path "${remote_device_proto}" PATH)

get_filename_component(mmio_proto "../protos/mmio.proto" ABSOLUTE)
get_filename_component(mmio_proto_path "${mmio_proto}" PATH)

get_filename_component(buffer_proto "../protos/buffer.proto" ABSOLUTE)
get_filename_component(buffer_proto_path "${buffer_proto}" PATH)

get_filename_component(gpio_proto "../protos/gpio.proto" ABSOLUTE)
get_filename_component(gpio_proto_path "${gpio_proto}" PATH)

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

set(gpio_proto_srcs "${CMAKE_CURRENT_BINARY_DIR}/gpio.pb.cc")
set(gpio_proto_hdrs "${CMAKE_CURRENT_BINARY_DIR}/gpio.pb.h")
set(gpio_grpc_srcs "${CMAKE_CURRENT_BINARY_DIR}/gpio.grpc.pb.cc")
set(gpio_grpc_hdrs "${CMAKE_CURRENT_BINARY_DIR}/gpio.grpc.pb.h")

add_custom_command(
  OUTPUT "${remote_device_proto_srcs}" "${remote_device_proto_hdrs}" "${remote_device_grpc_srcs}" "${remote_device_grpc_hdrs}" 
  "${mmio_proto_srcs}" "${mmio_proto_hdrs}" "${mmio_grpc_srcs}" "${mmio_grpc_hdrs}"
  "${buffer_proto_srcs}" "${buffer_proto_hdrs}" "${buffer_grpc_srcs}" "${buffer_grpc_hdrs}"
  "${gpio_proto_srcs}" "${gpio_proto_hdrs}" "${gpio_grpc_srcs}" "${gpio_grpc_hdrs}"
  COMMAND ${_PROTOBUF_PROTOC}
  ARGS --grpc_out "${CMAKE_CURRENT_BINARY_DIR}"
  --cpp_out "${CMAKE_CURRENT_BINARY_DIR}"
  -I "${remote_device_proto_path}"
  --plugin=protoc-gen-grpc="${_GRPC_CPP_PLUGIN_EXECUTABLE}"
  "${remote_device_proto}"
  "${mmio_proto}"
  "${buffer_proto}"
  "${gpio_proto}"
  DEPENDS "${remote_device_proto}" "${mmio_proto}" "${buffer_proto}" "${gpio_proto}")

# RFSoC-only proto generation
if(RFSOC)
    get_filename_component(xrfclk_proto "../protos/xrfclk.proto" ABSOLUTE)
    get_filename_component(xrfclk_proto_path "${xrfclk_proto}" PATH)

    get_filename_component(xrfdc_proto "../protos/xrfdc.proto" ABSOLUTE)
    get_filename_component(xrfdc_proto_path "${xrfdc_proto}" PATH)

    set(xrfclk_proto_srcs "${CMAKE_CURRENT_BINARY_DIR}/xrfclk.pb.cc")
    set(xrfclk_proto_hdrs "${CMAKE_CURRENT_BINARY_DIR}/xrfclk.pb.h")
    set(xrfclk_grpc_srcs "${CMAKE_CURRENT_BINARY_DIR}/xrfclk.grpc.pb.cc")
    set(xrfclk_grpc_hdrs "${CMAKE_CURRENT_BINARY_DIR}/xrfclk.grpc.pb.h")

    set(xrfdc_proto_srcs "${CMAKE_CURRENT_BINARY_DIR}/xrfdc.pb.cc")
    set(xrfdc_proto_hdrs "${CMAKE_CURRENT_BINARY_DIR}/xrfdc.pb.h")
    set(xrfdc_grpc_srcs "${CMAKE_CURRENT_BINARY_DIR}/xrfdc.grpc.pb.cc")
    set(xrfdc_grpc_hdrs "${CMAKE_CURRENT_BINARY_DIR}/xrfdc.grpc.pb.h")

    add_custom_command(
      OUTPUT "${xrfclk_proto_srcs}" "${xrfclk_proto_hdrs}" "${xrfclk_grpc_srcs}" "${xrfclk_grpc_hdrs}"
      "${xrfdc_proto_srcs}" "${xrfdc_proto_hdrs}" "${xrfdc_grpc_srcs}" "${xrfdc_grpc_hdrs}"
      COMMAND ${_PROTOBUF_PROTOC}
      ARGS --grpc_out "${CMAKE_CURRENT_BINARY_DIR}"
      --cpp_out "${CMAKE_CURRENT_BINARY_DIR}"
      -I "${xrfclk_proto_path}"
      --plugin=protoc-gen-grpc="${_GRPC_CPP_PLUGIN_EXECUTABLE}"
      "${xrfclk_proto}"
      "${xrfdc_proto}"
      DEPENDS "${xrfclk_proto}" "${xrfdc_proto}")
endif()

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

# Build libmetal — only required by rfdc (RFSoC services)
if(RFSOC)
    find_path(RFDC_INCLUDE_DIR
      NAMES xrfdc.h
      PATHS "${CMAKE_SYSROOT}/usr/include" "${CMAKE_SYSROOT}/include"
      NO_DEFAULT_PATH)
    find_path(METAL_INCLUDE_DIR
      NAMES metal/io.h
      PATHS "${CMAKE_SYSROOT}/usr/include" "${CMAKE_SYSROOT}/include"
      NO_DEFAULT_PATH)
    find_library(METAL_LIBRARY
      NAMES metal
      PATHS "${CMAKE_SYSROOT}/usr/lib" "${CMAKE_SYSROOT}/lib"
      NO_DEFAULT_PATH)

    if(NOT RFDC_INCLUDE_DIR)
        message(FATAL_ERROR "Could not find xrfdc.h in the Yocto sysroot. Enable the rfdc recipe for RFSoC builds.")
    endif()
    if(NOT METAL_INCLUDE_DIR OR NOT METAL_LIBRARY)
        message(FATAL_ERROR "Could not find libmetal headers/library in the Yocto sysroot. Enable the libmetal recipe for RFSoC builds.")
    endif()

    message(STATUS "Found rfdc include dir: ${RFDC_INCLUDE_DIR}")
    message(STATUS "Found libmetal: ${METAL_LIBRARY}")
endif()

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

# gpio_grpc_proto
add_library(gpio_grpc_proto
  ${gpio_grpc_srcs}
  ${gpio_grpc_hdrs}
  ${gpio_proto_srcs}
  ${gpio_proto_hdrs})

# RFSoC-only proto libraries, source list, and link/deps lists.
# These variables are empty on non-RFSoC boards so the splat below produces
# vanilla MMIO/GPIO/Buffer-only build.
set(RFSOC_SOURCES "")
set(RFSOC_DEPS "")
set(RFSOC_LINKS "")
set(RFSOC_INCLUDE_DIRS "")
set(RFSOC_SYSTEM_LINKS "")
if(RFSOC)
    add_compile_definitions(RFSOC)

    add_library(xrfclk_grpc_proto
      ${xrfclk_grpc_srcs}
      ${xrfclk_grpc_hdrs}
      ${xrfclk_proto_srcs}
      ${xrfclk_proto_hdrs})

    add_library(xrfdc_grpc_proto
      ${xrfdc_grpc_srcs}
      ${xrfdc_grpc_hdrs}
      ${xrfdc_proto_srcs}
      ${xrfdc_proto_hdrs})

    list(APPEND RFSOC_SOURCES xrfclk.cc xrfdc.cc)
    list(APPEND RFSOC_DEPS    xrfclk_grpc_proto xrfdc_grpc_proto)
    list(APPEND RFSOC_LINKS   xrfclk_grpc_proto xrfdc_grpc_proto)
    list(APPEND RFSOC_INCLUDE_DIRS ${RFDC_INCLUDE_DIR} ${METAL_INCLUDE_DIR})
    list(APPEND RFSOC_SYSTEM_LINKS ${METAL_LIBRARY} ${CMAKE_DL_LIBS})
endif()

# Main pynq library
add_library(pynq
  buffer.cc
  mmio.cc
  device.cc
  gpio.cc
  ${RFSOC_SOURCES}
)

# Ensure proto headers are generated before compiling pynq sources
add_dependencies(pynq
  buffer_grpc_proto
  mmio_grpc_proto
  remote_device_grpc_proto
  gpio_grpc_proto
  ${RFSOC_DEPS}
)

target_link_libraries(pynq
  ${XRT_LIBRARIES}
  ${XRT_ADDITIONAL_LIBRARIES}
  ${RFSOC_SYSTEM_LINKS})

target_include_directories(pynq PRIVATE
  ${RFSOC_INCLUDE_DIRS})

target_link_libraries(remote_device_grpc_proto
  mmio_grpc_proto
  buffer_grpc_proto
  gpio_grpc_proto
  ${RFSOC_LINKS}
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
    gpio_grpc_proto
    ${RFSOC_LINKS}
    ${_REFLECTION}
    ${_GRPC_GRPCPP}
    ${_PROTOBUF_LIBPROTOBUF}
    ${XRT_LIBRARIES}
    ${XRT_ADDITIONAL_LIBRARIES})  # Link against additional XRT libraries if necessary
endforeach()