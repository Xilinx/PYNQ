How to build projects with PYNQ.cpp
===================================

Requirements for building PYNQ.cpp
----------------------------------

- XRT (2025.2)
- C++17 or later  

Requirements for using PYNQ.cpp on SoC devices
----------------------------------------------

- PYNQ.remote image built with EDF/Yocto (see :doc:`../image_build`)
- FPGA Manager support enabled on the target
- Root access on the device (for device and filesystem operations)
- Embedded XRT installed on the device

Build Instructions
------------------

Include the headers and sources in your CMake project, or manually compile:

.. code-block:: bash
   :caption: Example g++ command to build with PYNQ.cpp and XRT

   XRT_INCLUDE=/opt/xilinx/xrt/include
   XRT_LIB=/opt/xilinx/xrt/lib

   g++ -std=c++17 \
       -Iinclude -I$XRT_INCLUDE \
       -L$XRT_LIB \
       -o your_program \
       main.cpp buffer.cpp device.cpp mmio.cpp \
       -lxrt_coreutil
