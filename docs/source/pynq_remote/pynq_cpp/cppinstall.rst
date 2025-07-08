How to build projects with PYNQ.cpp
===================================

Requirements for building PYNQ.cpp
----------------------------------

- XRT (2024.1)
- C++17 or later  

Requirements for using PYNQ.cpp on SoC devices.
-----------------------------------------------
- Embedded Linux with FPGA Manager support (``/sys/class/fpga_manager/``)  
- Root access on device (for device & filesystem operations)
- Embedded XRT 2.17 installed on the device.

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
