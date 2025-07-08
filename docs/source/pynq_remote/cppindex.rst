.. _cppindex:

PYNQ.cpp
=====================

.. toctree::
   :maxdepth: 2
   :caption: PYNQ.cpp Contents
   :titlesonly:
   
   pynq_cpp/cppapi
   pynq_cpp/cppusage
   pynq_cpp/cppinstall

**PYNQ.cpp** is a C++ hardware abstraction library for AMD-Xilinx FPGA platforms. 
It provides a low-level interface to interact with the FPGA fabric, memory management, and device operations.
It is part of the PYNQ ecosystem, specifically designed to work with PYNQ.remote, which allows remote access to PYNQ devices over a network.
PYNQ.remote uses gRPC to communicate with PYNQ devices, allowing remote management of FPGA resources and memory operations. 
PYNQ.remote images use a gRPC server to interact with PYNQ.cpp, which provides the necessary C++ backend functionality.

PYNQ.cpp is designed to be used in C++ applications running on AMD-Xilinx FPGA platforms, providing a low-level interface to reprogram the FPGA fabric and manage memory.
It is built on top of the Xilinx Runtime (XRT) library, which provides access to the FPGA Manager and other hardware resources.
Because it exists as a standalone C++ library, it can be used independently of PYNQ.remote, allowing developers to create custom low-level applications that interact with PYNQ devices.

Key Features
------------

* Load FPGA bitstreams via the FPGA Manager device driver.
* Manage `xrt::bo` contiguous buffer objects with cacheable host-device memory mapping.
* Perform memory-mapped I/O (MMIO) operations via `/dev/mem`
* Directly synchronize and flush buffers to/from device memory
* Filesystem operations for write/read access to bitstreams and device files.