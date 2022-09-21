.. _pynq-pl_server:

pynq.pl_server Package
======================

The pynq.pl_server module contains the required modules for PL server. 
Each Linux device works as a singleton client to communicate with PL servers 
via a unique socket. Multiple devices can co-exist at the same time on a 
specific platform.

Modules:
  * :mod:`pynq.pl_server.server` - Implements the top-level PL server for all the devices
  * :mod:`pynq.pl_server.device` - Implements the (programmable) device class.
  * :mod:`pynq.pl_server.xrt_device` - Implements Xilinx Run Time (XRT) enabled device for x86.
  * :mod:`pynq.pl_server.embedded_device` - Implements Xilinx Run Time (XRT) enabled device for SoC.
  * :mod:`pynq.pl_server.hwh_parser` - Parses useful information from hwh files.
  * :mod:`pynq.pl_server.xclbin_parser` - Parses useful information from xclbin files.

.. toctree::
    :hidden:

    pynq.pl_server/pynq.pl_server.server
    pynq.pl_server/pynq.pl_server.device
    pynq.pl_server/pynq.pl_server.xrt_device
    pynq.pl_server/pynq.pl_server.embedded_device
    pynq.pl_server/pynq.pl_server.hwh_parser
    pynq.pl_server/pynq.pl_server.xclbin_parser
