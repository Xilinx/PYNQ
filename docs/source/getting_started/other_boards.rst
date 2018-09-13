.. _other-boards:

*********************************
Using PYNQ with other Zynq boards
*********************************

PYNQ is an open source software framework that supports Xilinx Zynq devices.
To use PYNQ, a PYNQ image and suitable Zynq development board is required. 

Currently two boards are officially supported by the PYNQ project (Pynq-Z1 from
Digilent and Pynq-Z2 from TUL). This means that pre-compiled images are 
available for download for these boards that include example overlays and 
example Jupyter notebooks. All source files to rebuild the PYNQ image for these
boards are available in the PYNQ GitHub. However, it is possible to use PYNQ
with other Zynq development boards. 

As PYNQ is a framework, there are a number of different components that make up
PYNQ; Python libraries to control the Programmable Logic, Jupyter Notebook
interface, PYNQ overlays and IP, pre-installed packages. There is a set of
board requirements to use the full array of PYNQ features. This includes a
network interface, USB port and UART. However, if a developer does not intend
to use all aspects of PYNQ, only a subset of board features are required. For
example, a design could be developed on a board fully supported by PYNQ, and
deployed on a different production board. If Jupyter is only used for
development, and not deployment, a network connection may not be required for
the production board. For deployment, PYNQ designs and applications can be run
on a minimal setup consisting of a Zynq device, boot source, and the minimum
memory required to run an OS and the custom application. 

The rest of this guide will assume a Zynq board will be used for development
that contains all the recommended features for PYNQ development. This can be an
off-the-shelf board, or a custom board you developed yourself. 

Board recommendations for development
-------------------------------------

   * Any Zynq/Zynq Ultrascale+ device (including single-core)
   * >=512 MB DRAM
   * SD Card (>=8GB) or other bootable source
   * Network connection; Ethernet or WiFi
   * UART
   * USB

The network connection can be an Ethernet connection or a WiFi connection. USB
WiFi, and boards with WiFi chips connected directly to the Zynq - E.g. SDIO or
other interfaces can be used. Linux also has a feature to allow a USB port to
be used as an Ethernet Gadget, allowing an Ethernet network connection to a PC
over a USB cable. 

UART is not essential, but can be useful to debug OS related issues. For
example, UART can be used to check the network configuration and IP address
of the board. 

A USB port is not essential, but is useful if USB peripherals may be used with
the board. 

You will need a PYNQ image for your board. See the :ref:`pynq-image` guide for
details. 
