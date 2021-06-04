set (CMAKE_SYSTEM_PROCESSOR "aarch64"           CACHE STRING "")
set (MACHINE                "zynqmp_a53"        CACHE STRING "")
set (CROSS_PREFIX           ""                  CACHE STRING "")
set (CMAKE_C_FLAGS          ""                  CACHE STRING "")

include (cross-generic-gcc)
