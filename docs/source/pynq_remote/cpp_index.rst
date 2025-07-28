.. _cppindex:

PYNQ.cpp
=====================

.. toctree::
   :maxdepth: 2
   :caption: Contents
   :titlesonly:
   
   pynq_cpp/cpp_usage
   pynq_cpp/cpp_install
   pynq_cpp/cpp_api

**PYNQ.cpp** is a C++ hardware abstraction library that provides a C++ equivalent to PYNQ's Python API for AMD adaptive SoC platforms. 
It delivers the same low-level interface capabilities as PYNQ for interacting with the FPGA fabric, memory management, and device operations.

Like PYNQ's Python API, PYNQ.cpp is part of the PYNQ ecosystem and is specifically designed to work with PYNQ.remote, which allows remote access to PYNQ devices over a network.
PYNQ.remote uses gRPC to communicate with PYNQ devices, allowing remote management of FPGA resources and memory operations. 
PYNQ.remote images use a gRPC server to interact with PYNQ.cpp, which provides the necessary C++ backend functionality equivalent to what PYNQ's Python API offers.

Because it exists as a standalone C++ library, PYNQ can be used independently of PYNQ.remote. This allows developers to create custom low-level C++ applications that interact with AMD adaptive SoC platforms using familiar PYNQ concepts.